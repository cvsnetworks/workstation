terraform {
  backend "s3" {
    bucket               = "terraform-state-20210616191916697500000001"
    key                  = "workstations"
    workspace_key_prefix = "workstations"
    region               = "us-east-1"
    dynamodb_table       = "terraform-state-lock"
  }
}
