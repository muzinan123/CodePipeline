import os, json, zipfile, botocore
from common.client_session_helper import boto3_client, boto3_session, boto3_resource
from common.custom_logging import CustomLogger
from common.cp_helper import put_job_success, put_job_failure
from zipfile import ZipFile
from boto3.session import Session
from helper import assume_role

logger = CustomLogger().logger


def lambda_handler(event, context):
    response_data = dict()
    TagList = ['AWS_Build_ID', 'AWS_Build_Number', 'AWS_Commit_ID', 'Name', 'OS_Version', 'Retention_Status', 'Source_AMI_ID','Source_AMI_Name']

    logger.info(json.dumps(event))

    job_id = event['CodePipeline.job']['id']
    job_data = event['CodePipeline.job']['data']
    s3_bucket = event['CodePipeline.job']['data']['inputArtifacts'][0]['location']['s3Location']['bucketName']
    s3_key = event['CodePipeline.job']['data']['inputArtifacts'][0]['location']['s3Location']['objectKey']
    user_parameters = event['CodePipeline.job']['data']['actionConfiguration']['configuration']['UserParameters']

    user_parameters = json.loads(user_parameters)
    environment = user_parameters['AccountType']
    # TODO: TEMP - add the account ID into the ami_artifacts.json
    account = f'{environment}_ACCOUNT_ID'

    if environment == 'DEV':
        # TODO: Rename artifact file to include _dev and have ami_artifacts.json be the 'template'
        ami_artifacts = "ami_artifacts.json"
    else: 
        ami_artifacts = 'ami_artifacts_' + environment.lower() + '.json'

    logger.info(f'Creating session for CodePipeline response...')
    pipeline_account = event['CodePipeline.job']['accountId']
    pipeline_credentials = assume_role(account_number=pipeline_account, role_name=os.environ['Role'])
    pipeline_session = boto3_session(credentials=pipeline_credentials)

    try:
        logger.info(f'Downloading CodePipeline artifacts...')
        s3_resource = boto3_resource(service='s3', session=pipeline_session)
        s3_resource.meta.client.download_file(s3_bucket, s3_key, '/tmp/amiartifacts.zip')

        # TODO: TEMP - add OS Version to the ami_artifacts_*.json, until then use this section
        with zipfile.ZipFile('/tmp/amiartifacts.zip', 'r') as zip_ref:
            zip_ref.extractall('/tmp/')
        f = open('/tmp/ami_artifacts.json')
        
        ami_details = json.load(f)
        ami_operating_system = ami_details['ShortVersion']

        if environment == 'FUNCTIONAL':
            account_id = ami_details['AccountId']
        else: 
            account_id = os.environ[account]

        # File with AMI IDs for environment
        f = open('/tmp/' + ami_artifacts)
        
        ami_details = json.load(f)
        ami_details = ami_details['AMIDetails']
        
        logger.info(f'Operating System: {ami_operating_system}')
        logger.info(f'Provided AMI Details: {json.dumps(ami_details)}')
        
        for share_region in ami_details:
            if ami_details[share_region] == "" or len(ami_details) != 6:
                #return put_job_failure(job_id=job_id, message=f'Function exception: AMI is not shared with 6 regions',session=pipeline_session)
                return 'failure'

        for share_region in ami_details:
            logger.info(f'Creating session to validate AMI...')
            credentials = assume_role(account_number=account_id, role_name=os.environ['Role'])
            session = boto3_session(credentials=credentials)

            ec2 = boto3_client(service='ec2', region=share_region, session=session)

            logger.info(f'Validating AMI details in {share_region}')
            regional_ami_id = ami_details[share_region]

            logger.info(f'Executing EC2 checks for {regional_ami_id}...')
            ami_response = ec2.describe_images(ImageIds=[regional_ami_id])
            print(ami_response)
            ami_tags = ami_response['Images'][0]['Tags']
            tag_list = list()

            logger.info('Getting AMI tags...')
            for key in ami_tags:
                tag_list.append(key['Key'])

            check = all(item in tag_list for item in TagList)

            if not check:
                return put_job_failure(job_id=job_id, message=f'Function exception: Missing mandatory tags {TagList} for AMI {regional_ami_id} in {share_region}',session=pipeline_session)
            else: 
                logger.info('All required tags are present')

            EBSDetails=ami_response['Images'][0]['BlockDeviceMappings'][0]['Ebs']

            logger.info('Checking encryption status...')
            if EBSDetails['Encrypted']== False:
                return put_job_failure(job_id=job_id, message=f'Function exception: AMI {regional_ami_id} is not encrypted in {share_region}',session=pipeline_session)
            else: 
                logger.info('AMI is encrypted')
                
            if environment == 'FUNCTIONAL':
                ssm = boto3_client(service='ssm', region=share_region, session=session)
                
                ssm_parameter_key = f'/tec/golden-ami/{ami_operating_system}/ami-id'
                ssm_response = ssm.get_parameter(Name=ssm_parameter_key)['Parameter']
                ssm_value = ssm_response['Value']
                
                if ssm_value != regional_ami_id:
                    logger.error('SSM parameter has the incorrect AMI ID')

                    return put_job_failure(job_id=job_id, message=f'Function exception: {ssm_parameter_key} is not correct in {share_region}',session=pipeline_session)
                else:
                    logger.info('SSM parameter has the correct AMI ID')

            logger.info(f'{share_region}: PASS')
            
        return put_job_success(job_id=job_id, message='Deployment was successful', session=pipeline_session)
        
    except Exception as e:
        response_data['ERROR'] = str(e)
        logger.error(response_data['ERROR'])
        return put_job_failure(job_id=job_id, message=f'Function exception: {str(e)}',session=pipeline_session)
