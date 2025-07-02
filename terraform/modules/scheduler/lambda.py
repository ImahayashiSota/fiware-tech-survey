import json
import boto3
import logging
import os
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    AWS リソース自動停止・開始のメインハンドラー
    EventBridge から action パラメータを受け取って処理を分岐
    """
    
    try:
        # EventBridge から action を取得
        action = event.get('action', 'unknown')
        region = os.environ.get('AWS_REGION', 'ap-northeast-1')
        
        logger.info(f"Starting resource scheduler with action: {action}")
        
        if action == 'stop':
            stop_resources(region)
        elif action == 'start':
            start_resources(region)
        else:
            logger.error(f"Unknown action: {action}")
            return {
                'statusCode': 400,
                'body': json.dumps(f'Unknown action: {action}')
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps(f'Successfully executed {action} action')
        }
        
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

def stop_resources(region):
    """
    Schedule=true タグを持つリソースを停止
    """
    logger.info("Starting resource stop operation")
    
    # EC2インスタンスを停止
    stop_ec2_instances(region)
    
    # EKSノードグループのスケーリングを0に設定
    scale_eks_nodegroups(region, 0)
    
    # DocumentDBクラスターを停止
    stop_documentdb_clusters(region)

def start_resources(region):
    """
    Schedule=true タグを持つリソースを開始
    """
    logger.info("Starting resource start operation")
    
    # EC2インスタンスを開始
    start_ec2_instances(region)
    
    # DocumentDBクラスターを開始
    start_documentdb_clusters(region)
    
    # EKSノードグループのスケーリングを元に戻す
    scale_eks_nodegroups(region, None)  # 元のサイズに戻す

def stop_ec2_instances(region):
    """
    Schedule=true タグを持つEC2インスタンスを停止
    """
    try:
        ec2 = boto3.client('ec2', region_name=region)
        
        # Schedule=true タグを持つ実行中のインスタンスを検索
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'tag:Schedule', 'Values': ['true']},
                {'Name': 'instance-state-name', 'Values': ['running']}
            ]
        )
        
        instance_ids = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])
        
        if instance_ids:
            logger.info(f"Stopping EC2 instances: {instance_ids}")
            ec2.stop_instances(InstanceIds=instance_ids)
        else:
            logger.info("No running EC2 instances found with Schedule=true tag")
            
    except Exception as e:
        logger.error(f"Error stopping EC2 instances: {str(e)}")

def start_ec2_instances(region):
    """
    Schedule=true タグを持つEC2インスタンスを開始
    """
    try:
        ec2 = boto3.client('ec2', region_name=region)
        
        # Schedule=true タグを持つ停止中のインスタンスを検索
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'tag:Schedule', 'Values': ['true']},
                {'Name': 'instance-state-name', 'Values': ['stopped']}
            ]
        )
        
        instance_ids = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])
        
        if instance_ids:
            logger.info(f"Starting EC2 instances: {instance_ids}")
            ec2.start_instances(InstanceIds=instance_ids)
        else:
            logger.info("No stopped EC2 instances found with Schedule=true tag")
            
    except Exception as e:
        logger.error(f"Error starting EC2 instances: {str(e)}")

def scale_eks_nodegroups(region, desired_capacity):
    """
    Schedule=true タグを持つEKSノードグループをスケーリング
    """
    try:
        eks = boto3.client('eks', region_name=region)
        
        # すべてのEKSクラスターを取得
        clusters_response = eks.list_clusters()
        
        for cluster_name in clusters_response['clusters']:
            # ノードグループ一覧を取得
            nodegroups_response = eks.list_nodegroups(clusterName=cluster_name)
            
            for nodegroup_name in nodegroups_response['nodegroups']:
                # ノードグループの詳細情報を取得
                nodegroup_detail = eks.describe_nodegroup(
                    clusterName=cluster_name,
                    nodegroupName=nodegroup_name
                )
                
                # Schedule=true タグをチェック
                tags = nodegroup_detail['nodegroup'].get('tags', {})
                if tags.get('Schedule') == 'true':
                    current_scaling = nodegroup_detail['nodegroup']['scalingConfig']
                    
                    if desired_capacity == 0:
                        # 停止時: 現在の設定を保存してからスケールダウン
                        logger.info(f"Scaling down EKS nodegroup: {cluster_name}/{nodegroup_name}")
                        
                        # DynamoDBに現在の設定を保存（オプション）
                        save_nodegroup_config(cluster_name, nodegroup_name, current_scaling)
                        
                        eks.update_nodegroup_config(
                            clusterName=cluster_name,
                            nodegroupName=nodegroup_name,
                            scalingConfig={
                                'minSize': 0,
                                'maxSize': current_scaling['maxSize'],
                                'desiredSize': 0
                            }
                        )
                    else:
                        # 開始時: 保存された設定を復元
                        logger.info(f"Scaling up EKS nodegroup: {cluster_name}/{nodegroup_name}")
                        
                        # DynamoDBから設定を復元（オプション）
                        saved_config = get_nodegroup_config(cluster_name, nodegroup_name)
                        
                        if saved_config:
                            eks.update_nodegroup_config(
                                clusterName=cluster_name,
                                nodegroupName=nodegroup_name,
                                scalingConfig=saved_config
                            )
                        else:
                            # デフォルト設定で復元
                            eks.update_nodegroup_config(
                                clusterName=cluster_name,
                                nodegroupName=nodegroup_name,
                                scalingConfig={
                                    'minSize': 1,
                                    'maxSize': current_scaling['maxSize'],
                                    'desiredSize': 2
                                }
                            )
        
    except Exception as e:
        logger.error(f"Error scaling EKS nodegroups: {str(e)}")

def stop_documentdb_clusters(region):
    """
    Schedule=true タグを持つDocumentDBクラスターを停止
    """
    try:
        docdb = boto3.client('docdb', region_name=region)
        
        # すべてのDocumentDBクラスターを取得
        response = docdb.describe_db_clusters()
        
        for cluster in response['DBClusters']:
            cluster_id = cluster['DBClusterIdentifier']
            
            # クラスターのタグを取得
            tags_response = docdb.list_tags_for_resource(
                ResourceName=cluster['DBClusterArn']
            )
            
            # Schedule=true タグをチェック
            schedule_tag = False
            for tag in tags_response['TagList']:
                if tag['Key'] == 'Schedule' and tag['Value'] == 'true':
                    schedule_tag = True
                    break
            
            if schedule_tag and cluster['Status'] == 'available':
                logger.info(f"Stopping DocumentDB cluster: {cluster_id}")
                docdb.stop_db_cluster(DBClusterIdentifier=cluster_id)
                
    except Exception as e:
        logger.error(f"Error stopping DocumentDB clusters: {str(e)}")

def start_documentdb_clusters(region):
    """
    Schedule=true タグを持つDocumentDBクラスターを開始
    """
    try:
        docdb = boto3.client('docdb', region_name=region)
        
        # すべてのDocumentDBクラスターを取得
        response = docdb.describe_db_clusters()
        
        for cluster in response['DBClusters']:
            cluster_id = cluster['DBClusterIdentifier']
            
            # クラスターのタグを取得
            tags_response = docdb.list_tags_for_resource(
                ResourceName=cluster['DBClusterArn']
            )
            
            # Schedule=true タグをチェック
            schedule_tag = False
            for tag in tags_response['TagList']:
                if tag['Key'] == 'Schedule' and tag['Value'] == 'true':
                    schedule_tag = True
                    break
            
            if schedule_tag and cluster['Status'] == 'stopped':
                logger.info(f"Starting DocumentDB cluster: {cluster_id}")
                docdb.start_db_cluster(DBClusterIdentifier=cluster_id)
                
    except Exception as e:
        logger.error(f"Error starting DocumentDB clusters: {str(e)}")

def save_nodegroup_config(cluster_name, nodegroup_name, config):
    """
    ノードグループの設定をDynamoDBに保存（オプション機能）
    """
    try:
        # 環境変数から設定テーブル名を取得（設定されている場合のみ）
        table_name = os.environ.get('NODEGROUP_CONFIG_TABLE')
        if not table_name:
            return
            
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(table_name)
        
        table.put_item(
            Item={
                'cluster_nodegroup': f"{cluster_name}#{nodegroup_name}",
                'minSize': config['minSize'],
                'maxSize': config['maxSize'],
                'desiredSize': config['desiredSize'],
                'timestamp': datetime.utcnow().isoformat()
            }
        )
        
    except Exception as e:
        logger.warning(f"Could not save nodegroup config: {str(e)}")

def get_nodegroup_config(cluster_name, nodegroup_name):
    """
    ノードグループの設定をDynamoDBから取得（オプション機能）
    """
    try:
        # 環境変数から設定テーブル名を取得（設定されている場合のみ）
        table_name = os.environ.get('NODEGROUP_CONFIG_TABLE')
        if not table_name:
            return None
            
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(table_name)
        
        response = table.get_item(
            Key={'cluster_nodegroup': f"{cluster_name}#{nodegroup_name}"}
        )
        
        if 'Item' in response:
            item = response['Item']
            return {
                'minSize': int(item['minSize']),
                'maxSize': int(item['maxSize']),
                'desiredSize': int(item['desiredSize'])
            }
        
    except Exception as e:
        logger.warning(f"Could not get nodegroup config: {str(e)}")
    
    return None