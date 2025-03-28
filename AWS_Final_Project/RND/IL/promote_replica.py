import boto3

def lambda_handler(event, context):
    # Change the region_name and DBInstanceIdentifier as needed
    rds = boto3.client('rds', region_name='il-central-1')
    rds.promote_read_replica(DBInstanceIdentifier='wp-db-replica')

