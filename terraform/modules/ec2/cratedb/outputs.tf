output "security_group_id" {
  description = "CrateDBインスタンスのセキュリティグループID"
  value       = aws_security_group.cratedb.id
}

output "instance_id" {
  description = "CrateDBインスタンスのID"
  value       = aws_instance.cratedb.id
}

output "private_ip" {
  description = "CrateDBインスタンスのプライベートIPアドレス"
  value       = aws_instance.cratedb.private_ip
}

# 命名規則に合わせた出力も追加（オプション）
output "cratedb_security_group_id" {
  description = "CrateDBインスタンスのセキュリティグループID"
  value       = aws_security_group.cratedb.id
}