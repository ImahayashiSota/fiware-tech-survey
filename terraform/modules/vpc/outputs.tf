output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets # IDをリストで渡す
}

output "private_subnets" {
  value = module.vpc.private_subnets # IDをリストで渡す
}
