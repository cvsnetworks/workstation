#
# Workstation Launch Template
#

data "aws_ami" "ubuntu" {
  name_regex  = "^engineering-workstation-"
  most_recent = true

  owners = [
    var.account_id
  ]
}

data "cloudinit_config" "engineering" {
  gzip          = false
  base64_encode = true
  boundary      = "//"

  part {
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/etc/engineering-userdata", {
      efs_id = aws_efs_file_system.engineering.id
    })
  }
}

resource "aws_launch_template" "engineering" {
  name_prefix            = "engineering-workstation-"
  image_id               = data.aws_ami.ubuntu.id
  update_default_version = true
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.workstations.key_name
  user_data              = data.cloudinit_config.engineering.rendered

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [
      aws_security_group.engineering_workstation.id
    ]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 100
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      "Name" = "engineering-workstation"
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.workstation.name
  }
}

#
# Workstation Auto Scaling Group
#

resource "aws_autoscaling_group" "engineering" {
  name_prefix         = "engineering-workstation-"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = values(module.private_subnet)[*].id

  launch_template {
    id = aws_launch_template.engineering.id
  }
}

#
# Workstation Storage
#

resource "aws_kms_key" "engineering_storage" {
  description = "This key is used to encrypt the engineering workstation file system."
  key_usage   = "ENCRYPT_DECRYPT"
}

resource "aws_efs_file_system" "engineering" {
  encrypted        = true
  kms_key_id       = aws_kms_key.engineering_storage.arn
  performance_mode = "generalPurpose"
}

resource "aws_efs_mount_target" "engineering" {
  for_each = toset(values(module.private_subnet)[*].id)

  file_system_id = aws_efs_file_system.engineering.id
  subnet_id      = each.value

  security_groups = [
    aws_security_group.engineering_storage.id
  ]
}

#
# Workstation Security Groups
#

resource "aws_security_group" "engineering_workstation" {
  name_prefix = "engineering-workstation-"
  description = "This security group controls access to the developer workstations."
  vpc_id      = aws_vpc.workstation.id
}

resource "aws_security_group_rule" "engineering_workstation_egress_all" {
  security_group_id = aws_security_group.engineering_workstation.id
  description       = "Allow all egress traffic."
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0

  cidr_blocks = [
    "0.0.0.0/0"
  ]
}

#
# Storage Security Groups
#

resource "aws_security_group" "engineering_storage" {
  name_prefix = "engineering-storage-"
  description = "This security group controls access to the engineering workstation EFS file system."
  vpc_id      = aws_vpc.workstation.id
}

resource "aws_security_group_rule" "engineering_storage_nfs" {
  security_group_id        = aws_security_group.engineering_storage.id
  description              = "Allow NFS traffic from the engineering workstations."
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.engineering_workstation.id
}
