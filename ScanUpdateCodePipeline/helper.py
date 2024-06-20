# (c) 2020 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement
# available at http://aws.amazon.com/agreement or other written agreement between
# Customer and Amazon Web Services, Inc.

import yaml
import os
import boto3
from boto3.dynamodb.types import TypeDeserializer
from common.dynamodb_helper import scan_dynamodb
from common.custom_logging import CustomLogger

logger = CustomLogger().logger


def check_codepipeline_cfn_template(template):
    """Checks CodePipeline (CloudFormation Template) against DynamoDB Rules database
    to ensure security / governance policies

    Args:
        template (str): AWS CloudFormation template local location

    Returns:
        :obj: Returns list of results from security scan
    """
    cp_found = False
    scan_stages = None
    results = list()
    logger.info(f"Checking CodePipeline Template for Compliance")

    # Get Rules from DynamoDB Table
    scan_results = scan_dynamodb(table=os.environ['DYNAMODB_TABLE'])
    logger.info(f"Parsing through rules. {scan_results}")
    if not scan_results:
        logger.warn(f"No Items found in DynamoDBTable:{os.environ['DYNAMODB_TABLE']}")
        results.append("NoItemsFound")
        return results

    yaml.add_multi_constructor('!', lambda l, suffix, node: None)
    with open(template, 'r') as stream:
        _json = yaml.load(stream, Loader=yaml.Loader)
        # _json = yaml.safe_load(stream)

    # Make sure current cfn file has CodePipeline in it
    for k, v in _json['Resources'].items():
        for _k, _v in v.items():
            if _k == "Type" and _v == "AWS::CodePipeline::Pipeline":
                cp_found = True

            if cp_found and type(_v) is dict and _k == 'Properties':
                scan_stages = _v

    # Scan each item in table
    if scan_stages:
        for x in scan_results['Items']:
            if x['PatternType']['S'] == 'All':
                results.append(compare_template_items(x, scan_stages))

    else:
        logger.warn(f"No CodePipeline Template found to Scan against.")
        results.append("NoPipelineStagesFound")

    logger.info(f"Scan Results:{results}")
    return results


def compare_template_items(dynamodb_item, cp_template):
    """Does the actual DynamoDB rule and CloudFormation Template compare

    Args:
        dynamodb_item (dict): Security / governance rule policy to scan against
        cp_stages (dict): AWS CodePipeline Stages to be scanned

    Returns:
        :obj: Returns scan results
    """

    # Update DynamoDB Item from Mapping to Dictionary
    deserializer = boto3.dynamodb.types.TypeDeserializer()
    new_dynamodb_item = {k: deserializer.deserialize(v) for k, v in dynamodb_item.items()}
    logger.info(f"DynamoDB Item:{new_dynamodb_item}")
    logger.info("Determining whether DynamoDB Item is scanning for a Stage or an Action")

    dyn_scan_stages = new_dynamodb_item['Contents'].get('Stages')
    dyn_scan_actions = new_dynamodb_item['Contents'].get('Actions')
 

    if dyn_scan_stages:
        _result = scan_for_stage(dyn_scan_stages[0], cp_template['Stages'])

    elif dyn_scan_actions:
        _result = scan_for_action(dyn_scan_actions[0], cp_template['Stages'])

    if _result:
        return f"Passed:{dynamodb_item['RuleNumber']['S']}"
    else:
        return f"Failed:{new_dynamodb_item}"


def scan_for_stage(dynamodb_item_stage, cp_stages):
    """This will compare the DynamoDB Stage Item against all CodePipeline Stages

    Args:
        dynamodb_item_stage (dict): Security / governance rule policy to scan against
        cp_stages (list): AWS CodePipeline Stages to be scanned

    Returns:
        :obj: Returns scan results
    """
    logger.info("Executing Stage Scan")
    dyn_item_actions = dynamodb_item_stage['Actions'][0]

    # Parse each stage in the CodePipeline Template
    for cp_stage in cp_stages:
        if cp_stage and (cp_stage.get("Name") == dynamodb_item_stage.get("Name")):
            for cp_action in cp_stage['Actions']:
                if dyn_item_actions['Configuration'].items() <= cp_action['Configuration'].items() and \
                    dyn_item_actions['ActionTypeId'].items() <= cp_action['ActionTypeId'].items() and \
                        dyn_item_actions.get('Name') == cp_action.get('Name'):
                    return True

    return False


def scan_for_action(dynamodb_item_action, cp_stages):
    """This will compare the DynamoDB Action Item against all CodePipeline Stages

    Args:
        dynamodb_item_action (dict): Security / governance rule policy to scan against
        cp_stages (list): AWS CodePipeline Stages to be scanned

    Returns:
        :obj: Returns scan results
    """
    logger.info("Executing Action Scan")
    logger.debug(f"dynamodb_item_action:{dynamodb_item_action}")
    # Parse each stage in the CodePipeline Template
    for cp_stage in cp_stages:
        logger.debug(f"cp_stage:{cp_stage}")
        logger.info(f"Scanning CodePipeline Stage:{cp_stage['Name']}")
        for cp_action in cp_stage['Actions']:
            logger.debug(f"cp_action:{cp_action}")
            if cp_action.get('Configuration') and \
                    dynamodb_item_action['Configuration'].items() <= cp_action['Configuration'].items() and \
                    dynamodb_item_action['ActionTypeId'].items() <= cp_action['ActionTypeId'].items() and \
                    dynamodb_item_action.get('Name') == cp_action.get('Name'):
                return True

    return False
