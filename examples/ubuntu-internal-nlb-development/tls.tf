# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "tls_private_key" "consul_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
  # private_key_pem
  # public_key_pem
}

resource "tls_self_signed_cert" "consul_ca" {
  private_key_pem = tls_private_key.consul_ca.private_key_pem

  subject {
    common_name    = "Consul Agent CA"
    country        = "US"
    locality       = "San Francisco"
    street_address = ["101 Second Street"]
    organization   = "HashiCorp Inc."
    postal_code    = "94105"
    province       = "CA"
  }

  validity_period_hours = 91 * 24

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "crl_signing",
  ]

  is_ca_certificate  = true
  set_subject_key_id = true

  # cert_pem
}

resource "tls_private_key" "server" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
  # private_key_pem
  # public_key_pem
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name = "server.dc1.consul"
  }

  dns_names = [
    "server.dc1.consul",
    "localhost",
  ]

  ip_addresses = [
    "127.0.0.1"
  ]

  # cert_request_pem
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_private_key_pem = tls_private_key.consul_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.consul_ca.cert_pem

  validity_period_hours = 31 * 24

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]

  set_subject_key_id = true

  # cert_pem
}

resource "tls_private_key" "server_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "server_ssh" {
  key_name_prefix = "consul-server-"
  public_key      = tls_private_key.server_ssh.public_key_openssh
}

resource "local_sensitive_file" "consul_ssh" {
  content  = tls_private_key.server_ssh.private_key_openssh
  filename = "${path.module}/consul-server.pem"

  file_permission = "0600"
}
