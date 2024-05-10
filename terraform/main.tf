#
# SSH Keys
#

resource "aws_key_pair" "workstations" {
  key_name_prefix = "workstations-"
  public_key      = file("${path.module}/etc/workstations.pub")
}

#
# Shared Resources
#

module "cidr_blocks" {
  source  = "gitlab.com/grayscale/terraform-aws-cidr-blocks/aws"
  version = "1.2.1"
}
