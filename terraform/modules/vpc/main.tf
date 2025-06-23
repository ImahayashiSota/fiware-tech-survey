# vpc https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "${var.env}-vpc"
  cidr = "${var.vpc_cidr}"

  azs             = ["${var.region}a", "${var.region}d"]
  private_subnets = ["${var.private_subnet_a}", "${var.private_subnet_d}"]
  public_subnets  = ["${var.public_subnet_a}", "${var.public_subnet_d}"]

  enable_dns_hostnames    = true  # VPC内のインスタンスにDNSホスト名を割り当てる
  enable_nat_gateway      = true  # NATゲートウェイを有効にする
  map_public_ip_on_launch = true  # パブリックサブネットのインスタンスにパブリックIPを割り当てる
  single_nat_gateway      = true  # 単一のNATゲートウェイを使用する

  tags = {
    Name        = "${var.env}-vpc"
    Terraform   = "true"
    Environment = "${var.env}"
  }

  igw_tags = {
    Name = "${var.env}-vpc-igw"
  }

  nat_gateway_tags = {
    Name = "${var.env}-vpc-natgw"
  }

  public_route_table_tags = {
    Name = "${var.env}-vpc-public-rt"
  }

  private_route_table_tags = {
    Name = "${var.env}-vpc-private-rt"
  }

  public_subnet_tags_per_az = {
    "${var.region}a" = {
      Name = "${var.env}-vpc-public-${var.region}a"
    }
    "${var.region}d" = {
      Name = "${var.env}-vpc-public-${var.region}d"
    }
  }

  private_subnet_tags_per_az = {
    "${var.region}a" = {
      Name = "${var.env}-vpc-private-${var.region}a"
    }
    "${var.region}d" = {
      Name = "${var.env}-vpc-private-${var.region}d"
    }
  }
}
