#
# Packer Role
#

data "aws_organizations_organization" "this" {}

data "aws_iam_role" "gitlab_runner" {
  name = "gitlab-runner-job20220331144825303600000002"
}

resource "aws_iam_role" "packer" {
  name_prefix = "packer-"

  assume_role_policy = templatefile("${path.module}/etc/packer-trust-policy.json", {
    gitlab_runner_role_arn = data.aws_iam_role.gitlab_runner.arn,
    management_account_id  = data.aws_organizations_organization.this.master_account_id
  })
}

resource "aws_iam_policy" "packer" {
  name_prefix = "packer-"
  description = "This policy allows the Packer CLI to build and deploy AMIs."
  policy      = file("${path.module}/etc/packer-policy.json")
}

resource "aws_iam_role_policy_attachment" "packer" {
  role       = aws_iam_role.packer.name
  policy_arn = aws_iam_policy.packer.arn
}

#
# GitLab Runner Policy
#

resource "aws_iam_policy" "gitlab_runner_packer" {
  name_prefix = "gitlab-runner-packer-"
  description = "This policy allows GitLab Runner jobs to assume the Packer builder role."

  policy = templatefile("${path.module}/etc/gitlab-runner-policy.json", {
    packer_role_arn = aws_iam_role.packer.arn
  })
}

resource "aws_iam_role_policy_attachment" "gitlab_runner_packer" {
  role       = data.aws_iam_role.gitlab_runner.name
  policy_arn = aws_iam_policy.gitlab_runner_packer.arn
}

#
# Security Groups
#

data "aws_nat_gateway" "cicd" {
  id = var.cicd_ngw_id
}

resource "aws_security_group" "packer" {
  name_prefix = "packer-"
  description = "This security group controls access to the Packer build instances."
  vpc_id      = aws_vpc.workstation.id
}

resource "aws_security_group_rule" "packer_ingress_ssh_grayscale" {
  security_group_id = aws_security_group.packer.id
  description       = "Allow SSH traffic from the Grayscale VPN and office."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22

  cidr_blocks = module.cidr_blocks.all
}

resource "aws_security_group_rule" "packer_ingress_ssh_cicd" {
  security_group_id = aws_security_group.packer.id
  description       = "Allow SSH traffic from the CI/CD instances."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22

  cidr_blocks = [
    format("%s/32", data.aws_nat_gateway.cicd.public_ip)
  ]
}

resource "aws_security_group_rule" "packer_egress_all" {
  security_group_id = aws_security_group.packer.id
  description       = "Allow all egress traffic."
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0

  cidr_blocks = [
    "0.0.0.0/0"
  ]
}

