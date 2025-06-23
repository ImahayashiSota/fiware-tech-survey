output "bastion_sg_id" {
  description = "BastionホストのセキュリティグループID"
  value       = aws_security_group.bastion.id
}

# この出力を追加
output "bastion_role_arn" {
  description = "BastionホストのIAMロールARN"
  value       = aws_iam_role.bastion_role.arn
}