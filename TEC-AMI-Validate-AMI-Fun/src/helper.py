# (c) 2020 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement
# available at http://aws.amazon.com/agreement or other written agreement between
# Customer and Amazon Web Services, Inc.
import os
from common.helper import retry_v2
from common.client_session_helper import boto3_client
from common.custom_logging import CustomLogger
from common import exceptions
import zipfile
import tempfile
import random
import time
from common.client_session_helper import boto3_client, boto3_resource, boto3_session

logger = CustomLogger().logger
function_name = os.environ['AWS_LAMBDA_FUNCTION_NAME']


def get_pipeline_artifacts(artifacts):
    """Getting CodePipeline Artifact Names

    Args:
        artifacts (dict): Gets CodePipeline Artifact Names

    Returns:
        :list: List of CodePipeline Artifact Names
    """
    pipeline_artifacts = []
    for artifact in artifacts:
        name = artifact['name']
        logger.info(f"Adding {name} to pipeline_artifacts array")
        pipeline_artifacts.append(name)

    return pipeline_artifacts


def get_artifact_id(artifacts, pipeline_artifact):
    """Getting CodePipeline Artifact Ids

    Args:
        artifacts (dict): Gets CodePipeline Artifact Names
        pipeline_artifact (str):

    Returns:
        :str: Returns UID of CodePipeline Artifact
        :str: Returns S3 Bucket Name where CodePipeline Artifact lives
    """
    for artifact in artifacts:
        if artifact['name'] == pipeline_artifact:
            object_key = artifact['location']['s3Location']['objectKey']
            bucket_name = artifact['location']['s3Location']['bucketName']
            split_object = object_key.split('/')
            uid = split_object[2]
            return uid, bucket_name

    raise Exception(f"Input artifact named {pipeline_artifact} not found in event")


def assume_role(account_number, role_name, role_session_name=function_name, profile=None):
    """Assumes the provided role name in the provided account number

    http://boto3.readthedocs.io/en/latest/reference/services/sts.html#STS.Client.assume_role

    Args:
        account_number (str): Account number where the role to assume resides
        role_name (str): Name of the role to assume
        role_session_name (str, optional): The name you'd like to use for the session
            (suggested to use the lambda function name)
        profile (str, optional): Local AWS Profile name

    Returns:
        dict: Returns standard AWS dictionary with credential details
    """
    logger.info(f"Assuming Role:{role_name} in Account:{account_number}")
    sts_client = boto3_client(service='sts', profile=profile)

    assumed_role_object = sts_client.assume_role(
        RoleArn=f'arn:aws:iam::{account_number}:role/{role_name}',
        RoleSessionName=role_session_name
    )

    assumed_credentials = assumed_role_object['Credentials']

    if assumed_credentials:
        return assumed_credentials

    else:
        raise exceptions.CredentialException(
            "Failed to retrieve assumed_credentials from sts object."
        )


def download_file_from_pipeline_s3(job_data, artifact):
    """Pulls artifact credentials from job_data then downloads specific file from the artifact to /tmp

    Args:
        job_data (dict): Job_data section of pipeline event
        artifact (dict): Artifact object from pipeline to pull file from
        file_in_zip (str): File within the artifact dict to download

    Returns:
        str: Full path to the downloaded file
    """
    logger.debug(f'Getting file from S3...')

    credentials = {
        'AccessKeyId': job_data['artifactCredentials']['accessKeyId'],
        'SecretAccessKey': job_data['artifactCredentials']['secretAccessKey'],
        'SessionToken': job_data['artifactCredentials']['sessionToken']
    }
    session = boto3_session(credentials=credentials)

    bucket = artifact['location']['s3Location']['bucketName']
    artifact_path = artifact['location']['s3Location']['objectKey']
    zip_file = artifact_path.split('/')[2]
    temp_dir = '/tmp/' + str(random.randint(1, 9999)) + '/'

    try:
        logger.debug(f'Downloading {artifact_path} from S3 Bucket ({bucket})...')
        _response = s3_download_file(bucket_name=bucket, input_file_name=artifact_path, output_file_name=f"/tmp/{zip_file}", session=session)
        with zipfile.ZipFile('/tmp/' + zip_file, "r") as z:
            z.extractall(temp_dir)

        return str(temp_dir)

    except (KeyError, AttributeError, OSError) as e:
        logger.error(f'Something went wrong trying to download file. {e}')
        raise Exception(str(e))


def s3_download_file(bucket_name, input_file_name, output_file_name, session=None):
    """Download a file from S3 to disk

    http://boto3.readthedocs.io/en/latest/reference/services/s3.html#S3.Client.download_file

    Args:
        bucket_name (str): Name of the bucket
        input_file_name (str): Name of the file to download from S3 (including path if necessary)
        output_file_name (str): Path to where the file should be downloaded to including its name
        session (object, optional): boto3 session object

    Returns:
        dict: Standard AWS response dict
    """
    logger.debug(f"bucket_name:{bucket_name}")
    logger.debug(f"input_file_name:{input_file_name}")
    logger.debug(f"output_file_name:{output_file_name}")
    logger.debug(f"session:{session}")

    tries = 3
    count = 1
    client = boto3_client(service='s3', session=session)
    while True:
        try:
            logger.info(f"Attempt {count} of {tries} to download file {input_file_name} from {bucket_name}")
            response = client.download_file(bucket_name, input_file_name, output_file_name)
            return response

        except BaseException as e:
            count += 1
            time.sleep(10)
            if count > tries:
                raise exceptions.S3ObjectException(
                    f"Failed to download key {input_file_name} in bucket {bucket_name}: {str(e)}"
                )


def put_codepieline_artifact(job_data, file_name, kms_id=None):
    """Uploads file to artifact bucket using the 0'th output artifact from job_data

    Args:
        job_data (dict): Job_data section of pipeline event
        file_name (str): Full path to file to upload to s3 in artifact
        kms_id (str, optional): ID of the kms key to use to encrypt the object

    Returns:
        :obj:`json`: Json object (loads) of the artifact file
    """
    try:
        credentials = {
            'AccessKeyId': job_data['artifactCredentials']['accessKeyId'],
            'SecretAccessKey': job_data['artifactCredentials']['secretAccessKey'],
            'SessionToken': job_data['artifactCredentials']['sessionToken']
        }
        session = boto3_session(credentials=credentials)

        out_artifacts = job_data['outputArtifacts']
        out_object_key = out_artifacts[0]['location']['s3Location']['objectKey']
        out_bucket_name = out_artifacts[0]['location']['s3Location']['bucketName']

        logger.debug(f'out_artifacts: {out_artifacts}')
        logger.debug(f'out_objectKey: {out_object_key}')
        logger.debug(f'out_bucketName: {out_bucket_name}')

        s3_upload_file(
            bucket_name=out_bucket_name,
            input_file_name=file_name,
            s3_key=out_object_key,
            kms_id=kms_id,
            session=session
        )

    except Exception as e:
        logger.error(f'Failed to put pipeline artifact: {e}')
        raise Exception("Failed to put pipeline artifact.")


def s3_upload_file(bucket_name, input_file_name, s3_key, kms_id=None, session=None):
    """Upload a file from disk to a bucket using the provided kms ID

    http://boto3.readthedocs.io/en/latest/reference/services/s3.html#S3.Client.upload_file

    Args:
        bucket_name (str): Name of the bucket
        input_file_name (str): Path to the file to be uploaded
        s3_key (str): Name of the file after upload to the bucket
        kms_id (str): ARN of the kms key to use to encrypt the object
        session (object, optional): boto3 session object

    Returns:
        dict: Standard AWS response dict
    """
    client = boto3_client(service='s3', session=session)

    # If kms key isn't provided use the default key on the bucket
    if not kms_id:
        logger.info("No KMS Key was provided, getting the default key from the S3 Bucket")
        response = client.get_bucket_encryption(
            Bucket=bucket_name
        )
        kms_id = response['ServerSideEncryptionConfiguration']['Rules'][0][
            'ApplyServerSideEncryptionByDefault']['KMSMasterKeyID']
        logger.info(f"kms_id:{kms_id}")

    try:
        response = client.upload_file(
            input_file_name,
            bucket_name,
            s3_key,
            ExtraArgs=
            {
                "ServerSideEncryption": "aws:kms",
                "SSEKMSKeyId": kms_id
            }
        )

    except BaseException as e:
        raise exceptions.S3ObjectException(
            f"Failed to upload to key {s3_key} in bucket {bucket_name}: {str(e)}"
        )

    return response

    