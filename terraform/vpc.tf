#
# Workstation VPC and Subnets
#

resource "aws_vpc" "workstation" {
  cidr_block           = "10.0.4.0/25"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" = "workstation-vpc"
  }
}

resource "aws_internet_gateway" "egress" {
  vpc_id = aws_vpc.workstation.id

  tags = {
    "Name" = "workstation-igw"
  }
}

locals {
  public_subnets = {
    "a" = "10.0.4.0/28"
    "b" = "10.0.4.16/28"
  }

  private_subnets = {
    "a" = "10.0.4.32/28"
    "b" = "10.0.4.48/28"
  }
}

module "public_subnet" {
  source  = "gitlab.com/grayscale/terraform-aws-public-subnet/aws"
  version = "0.2.1"

  for_each = local.public_subnets

  vpc_id                   = aws_vpc.workstation.id
  cidr_block               = each.value
  name_prefix              = "workstation"
  gateway_id               = aws_internet_gateway.egress.id
  region                   = var.primary_region
  availability_zone_suffix = each.key
}

module "private_subnet" {
  source  = "gitlab.com/grayscale/terraform-aws-private-subnet/aws"
  version = "0.2.1"

  for_each = local.private_subnets

  vpc_id                   = aws_vpc.workstation.id
  cidr_block               = each.value
  name_prefix              = "workstation"
  region                   = var.primary_region
  availability_zone_suffix = each.key

  depends_on = [
    aws_internet_gateway.egress,
    module.public_subnet
  ]
}
