#
# Workstation IAM Instance Profile
#

resource "aws_iam_role" "workstation" {
  name_prefix        = "workstation-"
  assume_role_policy = file("${path.module}/etc/workstation-trust-policy.json")
}

resource "aws_iam_role_policy_attachment" "workstation_ssm_core" {
  role       = aws_iam_role.workstation.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "workstation" {
  name_prefix = "workstation-"
  role        = aws_iam_role.workstation.name
}

#
# VPC Endpoints
#

locals {
  workstation_security_groups = toset([
    aws_security_group.engineering_workstation.id
  ])
}

resource "aws_security_group" "systems_manager" {
  name_prefix = "systems-manager-"
  description = "Controls access to the AWS systems manager VPC endpoints."
  vpc_id      = aws_vpc.workstation.id
}

resource "aws_security_group_rule" "systems_manager_ingress_engineering" {
  security_group_id        = aws_security_group.systems_manager.id
  source_security_group_id = aws_security_group.engineering_workstation.id
  description              = "Allows HTTPS traffic from engineering workstations."
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}

# SSM

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.workstation.id
  service_name        = "com.amazonaws.${var.primary_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

resource "aws_vpc_endpoint_subnet_association" "ssm" {
  for_each = toset(values(module.private_subnet)[*].id)

  vpc_endpoint_id = aws_vpc_endpoint.ssm.id
  subnet_id       = each.value
}

resource "aws_vpc_endpoint_security_group_association" "ssm" {
  vpc_endpoint_id             = aws_vpc_endpoint.ssm.id
  security_group_id           = aws_security_group.systems_manager.id
  replace_default_association = true
}

# SSM Messages

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.workstation.id
  service_name        = "com.amazonaws.${var.primary_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

resource "aws_vpc_endpoint_subnet_association" "ssm_messages" {
  for_each = toset(values(module.private_subnet)[*].id)

  vpc_endpoint_id = aws_vpc_endpoint.ssm_messages.id
  subnet_id       = each.value
}

resource "aws_vpc_endpoint_security_group_association" "ssm_messages" {
  vpc_endpoint_id             = aws_vpc_endpoint.ssm_messages.id
  security_group_id           = aws_security_group.systems_manager.id
  replace_default_association = true
}

# EC2

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.workstation.id
  service_name        = "com.amazonaws.${var.primary_region}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

resource "aws_vpc_endpoint_subnet_association" "ec2" {
  for_each = toset(values(module.private_subnet)[*].id)

  vpc_endpoint_id = aws_vpc_endpoint.ec2.id
  subnet_id       = each.value
}

resource "aws_vpc_endpoint_security_group_association" "ec2" {
  vpc_endpoint_id             = aws_vpc_endpoint.ec2.id
  security_group_id           = aws_security_group.systems_manager.id
  replace_default_association = true
}

# EC2 Messages

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.workstation.id
  service_name        = "com.amazonaws.${var.primary_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

resource "aws_vpc_endpoint_subnet_association" "ec2_messages" {
  for_each = toset(values(module.private_subnet)[*].id)

  vpc_endpoint_id = aws_vpc_endpoint.ec2_messages.id
  subnet_id       = each.value
}

resource "aws_vpc_endpoint_security_group_association" "ec2_messages" {
  vpc_endpoint_id             = aws_vpc_endpoint.ec2_messages.id
  security_group_id           = aws_security_group.systems_manager.id
  replace_default_association = true
}
