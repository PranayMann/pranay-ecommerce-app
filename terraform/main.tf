provider "aws" {
  region = "${var.aws_region}"
  profile = "default"
}

# Create a VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks_vpc"
  }
}

#Create and attach internet gateway to VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks_igw"
  }
}

#Create route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "eks_rt"
  }
}
#Create a subnet
resource "aws_subnet" "eks_subnet" {
  count = 2
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "eks_subnet_${count.index + 1}"
  }
}

#Associate route tabel with subnet 
resource "aws_route_table_association" "rta" {
  count = 2
  subnet_id      = element(aws_subnet.eks_subnet.*.id, count.index)
  route_table_id = aws_route_table.rt.id
}

#Associate NAT gateway with the public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.eks_subnet.*.id, 0)
  tags = {
    Name = "eks_nat_gw"
  }
}

#Make NAT ip as elastic
resource "aws_eip" "nat_eip" {
  vpc = true
}

#Create EKS cluster with node group and access entry
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "Test-cluster"
  cluster_version = "1.30" # Specify the Kubernetes version
  subnet_ids        = aws_subnet.eks_subnet[*].id
  vpc_id          = aws_vpc.eks_vpc.id
  cluster_endpoint_public_access  = true
  eks_managed_node_groups = {
    eks_nodes = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.large"]

      min_size     = 2
      max_size     = 10
      desired_size = 2
    }
    }
  enable_cluster_creator_admin_permissions = true
  access_entries = {
    # One access entry with a policy associated
    admin = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::123456789012:role/eksclusterrole"

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }

  tags = {
    Environment = "Test-cluster"
    Terraform   = "true"
  }

}

