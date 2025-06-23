#!/bin/bash
# eks_auth_setup.sh

# 変数設定
REGION="ap-northeast-1"
CLUSTER_NAME="city1-eks-cluster"
ACCOUNT_ID="320518235583"

# kubeconfig の更新
echo "Updating kubeconfig..."
aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${REGION}

# aws-auth ConfigMap の適用
echo "Applying aws-auth ConfigMap..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $(aws eks describe-nodegroup --cluster-name ${CLUSTER_NAME} --nodegroup-name city1-eks-nodegroup --region ${REGION} --query 'nodegroup.nodeRole' --output text)
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: arn:aws:iam::${ACCOUNT_ID}:role/city1-bastion-role
      username: bastion-user
      groups:
        - system:masters
    - rolearn: arn:aws:iam::${ACCOUNT_ID}:role/city1-eks-developer-role
      username: developer
      groups:
        - system:masters
EOF

echo "Setup complete!"