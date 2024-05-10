packer {
  required_plugins {
    amazon = {
      version = "1.1.5"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "vpc_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "terraform_version" {
  type = string
}

variable "terraform_docs_version" {
  type = string
}

variable "packer_version" {
  type = string
}

variable "python_version" {
  type = string
}

variable "poetry_version" {
  type = string
}

variable "pipx_version" {
  type = string
}

variable "aws_version" {
  type = string
}

variable "aws_sam_version" {
  type = string
}

variable "dotnet_version" {
  type = string
}

variable "gitversion_version" {
  type = string
}

variable "node_version" {
  type = string
}

variable "pnpm_version" {
  type = string
}

variable "kubectl_version" {
  type = string
}

variable "helm_version" {
  type = string
}

variable "kind_version" {
  type = string
}

variable "stunnel_version" {
  type = string
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name          = "engineering-workstation-${local.timestamp}"
  instance_type     = "t3.xlarge"
  region            = "us-east-1"
  vpc_id            = var.vpc_id
  security_group_id = var.security_group_id

  assume_role {
    role_arn = var.role_arn
  }

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }

    most_recent = true

    owners = [
      "099720109477"
    ]
  }

  subnet_filter {
    most_free = true
    random    = false

    filters = {
      "vpc-id" : var.vpc_id,
      "tag:Name" : "*-public-*"
    }
  }

  ssh_username = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "file" {
    source      = "${path.root}/etc/.gitmessage"
    destination = "~/.gitmessage"
  }

  provisioner "file" {
    source      = "${path.root}/etc/mkuser"
    destination = "~/mkuser"
  }

  provisioner "shell" {
    scripts = [
      "${path.root}/etc/pre-install",
      "${path.root}/etc/engineering",
      "${path.root}/etc/efs",
      "${path.root}/etc/post-install"
    ]

    env = {
      "ASDF_DIR" : "/opt/asdf",
      "ASDF_DATA_DIR" : "/opt/asdf",
      "PIPX_HOME" : "/opt/pipx",
      "PIPX_BIN_DIR" : "/opt/pipx/bin",
      "DOTNET_TOOLS_DIR" : "/opt/dotnet",
      "TERRAFORM_VERSION" : var.terraform_version,
      "TERRAFORM_DOCS_VERSION" : var.terraform_docs_version,
      "PACKER_VERSION" : var.packer_version,
      "PYTHON_VERSION" : var.python_version,
      "POETRY_VERSION" : var.poetry_version,
      "PIPX_VERSION" : var.pipx_version,
      "AWS_VERSION" : var.aws_version,
      "AWS_SAM_VERSION" : var.aws_sam_version,
      "DOTNET_VERSION" : var.dotnet_version,
      "GITVERSION_VERSION" : var.gitversion_version,
      "NODE_VERSION" : var.node_version,
      "PNPM_VERSION" : var.pnpm_version,
      "KUBECTL_VERSION" : var.kubectl_version,
      "HELM_VERSION" : var.helm_version,
      "KIND_VERSION" : var.kind_version,
      "STUNNEL_VERSION" : var.stunnel_version
    }
  }
}
