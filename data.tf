# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "aws_vpc" "cluster" {
  id = var.vpc_id
}

data "aws_subnet" "instance" {
  for_each = { for idx, subnet in var.instance_subnets : idx => subnet }
  id       = each.value
}

data "cloudinit_config" "consul" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/jinja2"
    content      = templatefile("${path.module}/templates/00_init.yaml", local.install_vars)
  }
  part {
    content_type = "x-shellscript"
    content      = templatefile("${path.module}/templates/01_install_aws_cli.sh.tpl", {})
  }
  part {
    content_type = "x-shellscript"
    content      = templatefile("${path.module}/templates/install_consul.sh.tpl", { consul_version = var.consul_install_version })
  }
  part {
    content_type = "x-shellscript"
    content      = templatefile("${path.module}/templates/install_consul_config.sh.tpl", local.install_vars)
  }
  dynamic "part" {
    for_each = var.snapshot_agent.enabled ? ["enabled"] : []
    content {
      content_type = "x-shellscript"
      content      = templatefile("${path.module}/templates/install_snapshot_agent.sh.tpl", local.install_vars)
    }
  }
  part {
    content_type = "text/jinja2"
    content      = templatefile("${path.module}/templates/verify_cluster_state.sh.tpl", local.verify_vars)
  }
}

locals {
  install_vars = {
    consul_agent           = var.consul_agent
    snapshot_agent         = var.snapshot_agent
    redundancy_zones       = var.server_redundancy_zones
    consul_cluster_version = var.consul_cluster_version
    consul_nodes           = var.server_redundancy_zones ? length(toset([for i in data.aws_subnet.instance : i.availability_zone])) : var.consul_nodes
    license_path           = trimprefix(provider::aws::arn_parse(var.consul_agent.license_text_arn).resource, "parameter")
    ca_cert_path           = trimprefix(provider::aws::arn_parse(var.consul_agent.ca_cert_arn).resource, "parameter")
    agent_cert_path        = trimprefix(provider::aws::arn_parse(var.consul_agent.agent_cert_arn).resource, "parameter")
    agent_key_path         = trimprefix(provider::aws::arn_parse(var.consul_agent.agent_key_arn).resource, "parameter")
  }
  verify_vars = {
    autopilot_health_enabled = var.autopilot_health_enabled
    consul_agent             = var.consul_agent
    total_nodes              = var.consul_nodes
    total_voters             = var.server_redundancy_zones ? length(toset([for i in data.aws_subnet.instance : i.availability_zone])) : var.consul_nodes
    consul_cluster_version   = var.consul_cluster_version
    asg_name                 = local.asg_name
  }
}
