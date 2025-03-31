import json
import boto3
import os
from boto3.dynamodb.conditions import Key

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE_NAME'])
    case_number = event['queryStringParameters']['SerialNumber']
    response = table.query(KeyConditionExpression=Key('SerialNumber').eq(case_number))
    return {'statusCode': 200, 'body': json.dumps(response.get('Items', []))}

