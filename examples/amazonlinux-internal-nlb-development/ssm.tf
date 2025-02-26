# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals {
  license_text = var.license_text != "" ? var.license_text : file("${path.cwd}/files/consul.hclic")
}
resource "aws_secretsmanager_secret" "consul_license_text" {
  name        = "consul_license_text"
  description = "consul_license_text"
  # This will allow to do an immediate destroy of the secret when doing a Terraform destroy
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "consul_license_text" {
  secret_id     = aws_secretsmanager_secret.consul_license_text.id
  secret_string = local.license_text
}
# resource "aws_ssm_parameter" "consul_license_text" {
#   name  = "consul_license_text"
#   type  = "SecureString"
#   value = local.license_text
#   # arn
# }
resource "aws_secretsmanager_secret" "consul_ca_cert" {
  name        = "consul_ca_cert"
  description = "consul_ca_cert"
  # This will allow to do an immediate destroy of the secret when doing a Terraform destroy
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "consul_ca_cert" {
  secret_id     = aws_secretsmanager_secret.consul_ca_cert.id
  secret_string = base64encode(tls_self_signed_cert.consul_ca.cert_pem)
}
# resource "aws_ssm_parameter" "consul_ca_cert" {
#   name  = "consul_ca_cert"
#   type  = "SecureString"
#   value = tls_self_signed_cert.consul_ca.cert_pem
#   # arn
# }
resource "aws_secretsmanager_secret" "consul_agent_cert" {
  name        = "consul-agent-cert"
  description = "consul_agent_cert"
  # This will allow to do an immediate destroy of the secret when doing a Terraform destroy
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "consul_agent_cert" {
  secret_id     = aws_secretsmanager_secret.consul_agent_cert.id
  secret_string = base64encode(tls_locally_signed_cert.server.cert_pem)
}
# resource "aws_ssm_parameter" "consul_agent_cert" {
#   name  = "consul_agent_cert"
#   type  = "SecureString"
#   value = tls_locally_signed_cert.server.cert_pem
#   # arn
# }
resource "aws_secretsmanager_secret" "consul_agent_key" {
  name        = "consul_agent_key"
  description = "consul_agent_key"
  # This will allow to do an immediate destroy of the secret when doing a Terraform destroy
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "consul_agent_key" {
  secret_id     = aws_secretsmanager_secret.consul_agent_key.id
  secret_string = base64encode(tls_private_key.server.private_key_pem)
}
# resource "aws_ssm_parameter" "consul_agent_key" {
#   name  = "consul_agent_key"
#   type  = "SecureString"
#   value = tls_private_key.server.private_key_pem
#   # arn
# }
