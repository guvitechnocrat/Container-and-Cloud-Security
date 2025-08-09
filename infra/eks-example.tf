provider "aws" {
  region                  = "us-east-1"
  access_key              = "AKIA1234567890INSECURE"
  secret_key              = "hardcoded-secret-key-here"
}

# 🚨 Insecure VPC — overly permissive CIDR block
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "eks-vpc-insecure"
  cidr = "0.0.0.0/0" # 🚨 open to the world

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# 🚨 EKS cluster without encryption, public endpoint enabled
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.14.0"

  cluster_name    = "demo-eks-insecure"
  cluster_version = "1.21" # 🚨 outdated version
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  cluster_endpoint_public_access = true  # 🚨 publicly accessible

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1

      instance_types = ["t2.micro"] # 🚨 too small for production
      disk_size      = 8            # 🚨 very small disk

      remote_access = {
        ec2_ssh_key               = "eks-insecure-key"
        source_security_group_ids = ["sg-1234567890"] # 🚨 overly permissive SG
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "DevSecOps-Insecure-Lab"
  }
}

# Output cluster info
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = "us-east-1"
}
