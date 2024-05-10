variable "primary_region" {
  description = "The primary region where infrastructure will be deployed."
  type        = string
}

variable "account_id" {
  description = "The ID of the account where infrastructure will be deployed."
  type        = string
}

variable "environment" {
  description = "The environment of the deployed resources."
  type        = string
}

variable "cicd_ngw_id" {
  description = "The CI/CD cluster NAT gateway."
  type        = string
}
