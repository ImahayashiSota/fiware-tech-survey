module "vpc" {
  source             = "../../modules/vpc"
  env                = local.env
  region             = local.region
  vpc_cidr           = local.vpc_cidr
  public_subnet_a    = local.public_subnet_a
  public_subnet_d    = local.public_subnet_d
  private_subnet_a   = local.private_subnet_a
  private_subnet_d   = local.private_subnet_d
}

module "ec2_ssh_key" {
  source             = "../../modules/ec2/ssh_key"
  env                = local.env
  region             = local.region
}

module "ec2_bastion" {
  source             = "../../modules/ec2/bastion"
  env                = local.env
  region             = local.region
  instance_type      = local.instance_type
  vpc_id             = module.vpc.vpc_id
  subnet_id          = module.vpc.public_subnets[0]
  key_name           = module.ec2_ssh_key.key_name
  aws_ec2 = {
    ami_name_filter       = local.aws_ami.ami_name_filter
    volume_type           = local.aws_ami.volume_type
    volume_size           = local.aws_ami.volume_size
    delete_on_termination = local.aws_ami.delete_on_termination
  }
  depends_on = [ 
    module.vpc,
    module.ec2_ssh_key
  ]
}

module "ec2_cratedb" {
  source             = "../../modules/ec2/cratedb"
  env                = local.env
  region             = local.region
  vpc_id             = module.vpc.vpc_id
  key_name           = module.ec2_ssh_key.key_name
  instance_type      = local.instance_type
  subnet_id          = module.vpc.private_subnets[0]
  bastion_sg_id      = module.ec2_bastion.bastion_sg_id
  eks_node_sg_id     = module.eks.node_security_group_id
  aws_ec2 = {
    ami_name_filter       = local.aws_ami.ami_name_filter
    volume_type           = local.aws_ami.volume_type
    volume_size           = local.aws_ami.volume_size
    delete_on_termination = local.aws_ami.delete_on_termination
  }

  depends_on = [
    module.vpc,
    module.ec2_ssh_key,
    module.ec2_bastion
  ]
}

module "documentdb" {
  source           = "../../modules/documentdb"
  env              = local.env
  region           = local.region
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnets # DocumentDBはプライベートサブネットに配置
  bastion_sg_id    = module.ec2_bastion.bastion_sg_id
  instance_class   = "db.t3.medium"
  master_username  = "docdbadmin"
  master_password  = "YourSecurePassword123!" 
  engine_version   = "4.0.0" 
  instance_count   = 1
  
  depends_on = [
    module.vpc,
    module.ec2_bastion
  ]
}

# 現在のAWSアカウントIDを取得
data "aws_caller_identity" "current" {}

module "eks" {
  source = "../../modules/eks"
  
  env                     = local.env
  region                  = local.region
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnets
  cluster_name            = "${local.env}-eks-cluster"
  kubernetes_version      = local.kubernetes_version
  node_instance_type      = local.node_instance_type
  node_desired_size       = local.node_desired_size
  node_min_size           = local.node_min_size
  node_max_size           = local.node_max_size
  node_disk_size          = local.node_disk_size
  bastion_security_group_id = module.ec2_bastion.bastion_sg_id
  documentdb_security_group_id = module.documentdb.documentdb_security_group_id
}

# EKS開発者アクセス用のIAMロール
resource "aws_iam_role" "eks_developer_role" {
  name = "${local.env}-eks-developer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            # rootを使用して同じAWSアカウント内の全ユーザーに許可
          ]
        }
      }
    ]
  })

  tags = {
    Name        = "${local.env}-eks-developer-role"
    Environment = local.env
  }
  # 既存のロールが存在する可能性があるため競合を避ける
  lifecycle {
    ignore_changes = [assume_role_policy]
  }
}

# EKS開発者ロールにEKSクラスターポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "eks_developer_policy" {
  role       = aws_iam_role.eks_developer_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# # EKSノードからDocumentDBへのアクセスを許可
# resource "aws_security_group_rule" "eks_to_documentdb" {
#   type                     = "ingress"
#   from_port                = 27017
#   to_port                  = 27017
#   protocol                 = "tcp"
#   source_security_group_id = module.eks.node_security_group_id
#   security_group_id        = module.documentdb.documentdb_security_group_id
#   description              = "Allow MongoDB connection from EKS nodes"

#   depends_on = [
#     module.documentdb,
#     module.eks
#   ]
# }