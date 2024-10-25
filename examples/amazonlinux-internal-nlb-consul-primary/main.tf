# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_version = ">=1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.65"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.2.0"
    }
  }
}
provider "aws" {
  region = var.region
}
module "default" {
  source = "../.."

  # Instance Configuration
  #ami_id = var.ami_id
  ami_id               = data.aws_ami.amazonlinux.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  vpc_id               = var.vpc_id
  instance_subnets     = var.instance_subnets
  internal_nlb_subnets = var.internal_nlb_subnets
  associate_public_ip  = var.associate_public_ip

  # Cluster Details
  consul_install_version  = var.consul_install_version
  consul_cluster_version  = var.consul_cluster_version
  consul_nodes            = var.consul_nodes
  environment_name        = var.environment_name
  tag_owner               = var.tag_owner
  server_redundancy_zones = var.server_redundancy_zones
  disk_params             = var.disk_params
  consul_agent            = var.consul_agent
  snapshot_agent          = var.snapshot_agent
}


