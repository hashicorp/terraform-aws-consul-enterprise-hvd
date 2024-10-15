# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals {
  license_text = var.license_text != "" ? var.license_text : file("${path.cwd}/files/consul.hclic")
}

resource "aws_ssm_parameter" "consul_license_text" {
  name  = "consul_license_text"
  type  = "SecureString"
  value = local.license_text
  # arn
}

resource "aws_ssm_parameter" "consul_ca_cert" {
  name  = "consul_ca_cert"
  type  = "SecureString"
  value = tls_self_signed_cert.consul_ca.cert_pem
  # arn
}

resource "aws_ssm_parameter" "consul_agent_cert" {
  name  = "consul_agent_cert"
  type  = "SecureString"
  value = tls_locally_signed_cert.server.cert_pem
  # arn
}

resource "aws_ssm_parameter" "consul_agent_key" {
  name  = "consul_agent_key"
  type  = "SecureString"
  value = tls_private_key.server.private_key_pem
  # arn
}
