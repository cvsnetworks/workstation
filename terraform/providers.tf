provider "aws" {
  region = var.primary_region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/cloud-deployer"
  }

  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}

provider "cloudinit" {}
