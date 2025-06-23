output "cluster_id" {
  description = "EKS クラスタ ID"
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "EKS クラスタ名"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS コントロールプレーンのエンドポイント"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "EKS クラスタに関連付けられたセキュリティグループ ID"
  value       = aws_security_group.cluster.id
}

output "cluster_iam_role_name" {
  description = "EKS クラスタに関連付けられた IAM ロール名"
  value       = aws_iam_role.cluster.name
}

output "cluster_certificate_authority_data" {
  description = "クラスタとの通信に必要な Base64 エンコードされた証明書データ"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_group_id" {
  description = "EKS ノードグループ ID"
  value       = aws_eks_node_group.this.id
}

output "node_security_group_id" {
  description = "EKS ノードに関連付けられたセキュリティグループ ID"
  value       = aws_security_group.node.id
}

output "node_iam_role_name" {
  description = "EKS ノードに関連付けられた IAM ロール名"
  value       = aws_iam_role.node.name
}

output "node_iam_role_arn" {
  description = "EKS ノードに関連付けられた IAM ロール ARN"
  value       = aws_iam_role.node.arn
}
