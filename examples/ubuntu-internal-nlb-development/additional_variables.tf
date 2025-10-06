# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Provider
#------------------------------------------------------------------------------
variable "region" {
  type        = string
  description = "AWS region where consul will be deployed."
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
variable "gossip_encryption_key" {
  type        = string
  description = "Consul gossip encryption key (consul keygen)"
  default     = "ITyqw6xrOrApx9B6P6k+HdFH8UD9M1UXu8XL6ZzWWJM="
}

variable "initial_token" {
  default     = "2e5d48fd-a8da-bd2e-d9de-1ad409716a4f"
  type        = string
  description = "A UUID to use as the initial management token/snaphot token"
}

variable "license_text" {
  default     = ""
  type        = string
  description = "Enterprise license file contents (alternatively create consul.hclic)"
}
