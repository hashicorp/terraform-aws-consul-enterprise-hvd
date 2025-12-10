# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
