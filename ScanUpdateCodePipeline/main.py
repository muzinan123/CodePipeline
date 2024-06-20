# (c) 2020 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement
# available at http://aws.amazon.com/agreement or other written agreement between
# Customer and Amazon Web Services, Inc.

import json
import os
import re
from helper import check_codepipeline_cfn_template
from common.cp_helper import get_pipeline_info, put_job_success, put_job_failure
from common.s3_helper import get_file_contents_from_s3, download_file_from_pipeline_s3, s3_upload_file
from common.helper import get_user_params, cleanup_temp
from common.cfn_helper import create_update_stack, validate_template
from common.sts_helper import assume_role
from common.client_session_helper import boto3_session
from common.common_helper import load_file
from common.custom_logging import CustomLogger

logger = CustomLogger().logger


def lambda_handler(event, context):
    print(json.dumps(event))
    parameter_dict = dict()
    required_param_list = ['cfn_template', 'cfn_parameter']
    region = os.environ["REGION"]

    job_id = event['CodePipeline.job']['id']
    job_data = event['CodePipeline.job']['data']
    artifacts = job_data['inputArtifacts']
    dest_account = event['CodePipeline.job']['accountId']

    try:
        # Set assumed role
        credentials = assume_role(account_number=dest_account, role_name=os.environ['ROLE'])
        session = boto3_session(credentials=credentials)

    except Exception as e:
        session = boto3_session(credentials=job_data['artifactCredentials'])
        put_job_failure(job_id=job_id, message=str(e), session=session)

    try:
        # Extract the params
        params = get_user_params(
            job_data=job_data,
            required_param_list=required_param_list
        )

        # Get S3 client to access artifact with
        # Get CloudFormation files from s3
        logger.info("Get CloudFormation Parameter file from CodePipeline - S3")
        parameter_string = get_file_contents_from_s3(
            job_data=job_data,
            artifact=artifacts[0],
            file_in_zip=params['cfn_parameter']
        )
        logger.info("Get CloudFormation Template file from CodePipeline - S3")
        template_location = download_file_from_pipeline_s3(
            job_data=job_data,
            artifact=artifacts[0],
            file_in_zip=params['cfn_template']
        )

        pipeline_name, stage_name, exec_uid = get_pipeline_info(job_id=job_id, session=session)

        if parameter_string:
            # Convert string to dict for CloudFormation run
            parameter_dict = json.loads(parameter_string)

        if template_location:
            # Set Variables
            stack_name = f"{pipeline_name}-CodePipeline"
            # Check CodePipeline Template for vulnerabilities
            scan_results = check_codepipeline_cfn_template(template=template_location)

            if "Failed:" not in ",".join(scan_results):
                # If template file is larger than 51200 bytes upload to s3 before deploying
                if os.stat(template_location).st_size > 51199:
                    s3_bucket = job_data["inputArtifacts"][0]['location']['s3Location']['bucketName']
                    kms_id = job_data["encryptionKey"]
                    logger.info('CloudFormation template was larger than 51200 bytes pushing to S3 before deploying')
                    s3_key = f"_ScanUpdateCodePipeline/{pipeline_name}/{template_location.split('/')[-1]}"
                    s3_upload_file(
                        bucket_name=s3_bucket,
                        input_file_name=template_location,
                        s3_key=s3_key,
                        kms_id=kms_id['id']
                    )
                    template_location = f"https://s3.{region}.amazonaws.com/{s3_bucket}/{s3_key}"
                    # validate_template(template=template_location, session=session)

                else:
                    validate_template(template=load_file(template_location), session=session)

                # Create or Update CodePipeline Stack
                response = create_update_stack(
                    stack_name=stack_name,
                    template=template_location,
                    cfn_params=parameter_dict,
                    capability='CAPABILITY_NAMED_IAM',
                    waiter=True,
                    session=session
                )
                logger.info(f"Response from create_update_stack {response}")

            else:
                raise Exception(f"Pipeline Scan {scan_results}")
        else:
            logger.warn('No CloudFormation Template or Parameter file found.')
        put_job_success(job_id=job_id, message='Deployment was successful', session=session)

    except Exception as e:
        logger.info(e)
        if re.search(r'(CREATE_IN_PROGRESS)', str(e)):
            logger.info("CREATE_IN_PROGRESS, continuing")
            put_job_success(job_id=job_id, message='CREATE_IN_PROGRESS, continuing', session=session)
        elif len(str(e)) < 500:
            put_job_failure(job_id=job_id, message=f"{str(e)}", session=session)
        else:
            put_job_failure(job_id=job_id, message=f"{str(e).split('[ERROR]')[0]}", session=session)

    finally:
        # Clean up the /tmp folder to avoid overlap on subsequent runs
        cleanup_temp()
