locals {
  env             = "city1"
  region          = "ap-northeast-1"
  vpc_cidr        = "10.0.0.0/16"
  instance_type   = "t3.small"
  kubernetes_version = "1.32"
  node_instance_type = "t3.medium"
  node_desired_size = 2
  node_min_size     = 1
  node_max_size     = 3
  node_disk_size    = 40
  aws_ami = {
    ami_name_filter       = "al2023-ami-2023.7.20250527.1-kernel-6.1-x86_64"
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true # trueに設定すると、インスタンス削除時にボリュームも削除される
  }
  private_subnet_a = cidrsubnet(local.vpc_cidr, 8, 0)
  private_subnet_d = cidrsubnet(local.vpc_cidr, 8, 1)
  public_subnet_a  = cidrsubnet(local.vpc_cidr, 8, 10)
  public_subnet_d  = cidrsubnet(local.vpc_cidr, 8, 11)
}
