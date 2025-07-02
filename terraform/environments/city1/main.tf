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

# 現在のAWSアカウントIDを取得
data "aws_caller_identity" "current" {}

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
  # cratedb_security_group_idへの参照を削除し循環依存を解消
  
  depends_on = [ 
    module.vpc,
    module.documentdb,
    module.ec2_bastion,
    module.ec2_ssh_key
    # module.ec2_cratedbへの依存関係も削除
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
  # eks_node_sg_id     = module.eks.node_security_group_id  # 循環依存を解消するため削除
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

# 循環依存を避けるため、CrateDBセキュリティグループルールを別途追加
resource "aws_security_group_rule" "eks_to_cratedb_web_ui" {
  type                     = "ingress"
  from_port                = 4200
  to_port                  = 4200
  protocol                 = "tcp"
  source_security_group_id = module.eks.node_security_group_id
  security_group_id        = module.ec2_cratedb.security_group_id
  description              = "Allow CrateDB Web UI access from EKS nodes"

  # EKSとCrateDBの両方が作成された後に適用
  depends_on = [
    module.eks,
    module.ec2_cratedb
  ]
}

# PostgreSQL互換ポートへのアクセスルールも別途追加
resource "aws_security_group_rule" "eks_to_cratedb_postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.eks.node_security_group_id
  security_group_id        = module.ec2_cratedb.security_group_id
  description              = "Allow CrateDB PostgreSQL access from EKS nodes"

  depends_on = [
    module.eks,
    module.ec2_cratedb
  ]
}

# リソーススケジューラーモジュール
module "scheduler" {
  source = "../../modules/scheduler"
  
  env    = local.env
  region = local.region
  
  # スケジュール設定（JST時間をUTC時間に変換済み）
  stop_schedule         = "cron(0 11 ? * 2-6 *)"    # JST 20:00 = UTC 11:00, 2=Mon-6=Fri
  start_schedule        = "cron(0 23 ? * 1-5 *)"    # JST 08:00 = UTC 23:00 (前日), 1=Sun-5=Thu
  weekend_stop_schedule = "cron(0 15 ? * 6 *)"    # JST 00:00 SAT = UTC 15:00 FRI, 6=Fri

  # Lambda設定
  lambda_function_name = "resource-scheduler"
  lambda_timeout       = 300
  lambda_memory_size   = 256
  
  # タグ設定
  schedule_tag_key   = "Schedule"
  schedule_tag_value = "true"
  
  # DynamoDB設定（オプション）
  enable_nodegroup_config_table = true
  nodegroup_config_table_name   = "eks-nodegroup-configs"
  
  tags = {
    Environment = local.env
    Terraform   = "true"
    Purpose     = "Cost-optimization"
  }
  
  depends_on = [
    module.vpc,
    module.ec2_bastion,
    module.ec2_cratedb,
    module.eks,
    module.documentdb
  ]
}