output "documentdb_cluster_id" {
  description = "DocumentDBクラスターのID"
  value       = aws_docdb_cluster.documentdb.id
}

output "documentdb_endpoint" {
  description = "DocumentDBクラスターのエンドポイント"
  value       = aws_docdb_cluster.documentdb.endpoint
}

output "documentdb_reader_endpoint" {
  description = "DocumentDBクラスターのリーダーエンドポイント"
  value       = aws_docdb_cluster.documentdb.reader_endpoint
}

output "documentdb_security_group_id" {
  description = "DocumentDBのセキュリティグループID"
  value       = aws_security_group.documentdb.id
}
