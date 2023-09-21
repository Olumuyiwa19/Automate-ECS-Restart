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
<<<<<<< HEAD
        logger.info(f'Service {service_name} restarted successfully with no issue')
=======
        logger.info(f'Service {service_name} restarted successfully')
>>>>>>> e03450248620a9bfbdda12d10fec66a7bea47f76
    except Exception as e:
        logger.error(f'Service {service_name} restart failed: {e}')
        raise e
