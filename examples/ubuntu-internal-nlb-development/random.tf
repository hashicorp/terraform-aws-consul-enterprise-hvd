# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

resource "random_id" "gossip_encryption_key" {
  byte_length = 32
}

resource "random_uuid" "initial_token" {}

locals {
  gossip_encryption_key = random_id.gossip_encryption_key.b64_std
  initial_token         = random_uuid.initial_token.result
}
