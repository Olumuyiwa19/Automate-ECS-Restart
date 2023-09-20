import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    ecs_client = boto3.client('ecs')

    cluster_name = os.environ['CLUSTER_NAME']
    service_name = os.environ['SERVICE_NAME']

    try:
        logger.info(f'Restarting service {service_name} in cluster {cluster_name}')
        ecs_client.update_service(
            cluster=cluster_name,
            service=service_name,
            forceNewDeployment=True
        )
        logger.info(f'Service {service_name} restarted successfully')
    except Exception as e:
        logger.error(f'Service {service_name} restart failed: {e}')
        raise e
