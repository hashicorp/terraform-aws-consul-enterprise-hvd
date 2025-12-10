# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

resource "aws_iam_role" "consul" {
  name_prefix        = "${var.environment_name}-consul"
  assume_role_policy = data.aws_iam_policy_document.ec2_assumerole.json
}

resource "aws_iam_role_policy" "consul_discovery" {
  name   = "consul-cluster-discovery"
  role   = aws_iam_role.consul.id
  policy = data.aws_iam_policy_document.consul_discovery.json
}

resource "aws_iam_role_policy" "consul_secrets" {
  name   = "consul-secrets-read"
  role   = aws_iam_role.consul.id
  policy = data.aws_iam_policy_document.consul_secrets.json
}

resource "aws_iam_role_policy" "consul_snapshots" {
  count  = var.snapshot_agent.enabled ? 1 : 0
  name   = "consul-snapshot-bucket"
  role   = aws_iam_role.consul.id
  policy = data.aws_iam_policy_document.snapshot_bucket[0].json
}

resource "aws_iam_instance_profile" "consul" {
  name = "${var.environment_name}-consul"
  role = aws_iam_role.consul.name
}

data "aws_iam_policy_document" "ec2_assumerole" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "consul_discovery" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:CompleteLifecycleAction"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "consul_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.consul_agent.license_text_arn,
      var.consul_agent.ca_cert_arn,
      var.consul_agent.agent_cert_arn,
      var.consul_agent.agent_key_arn,
    ]
  }
}

data "aws_iam_policy_document" "snapshot_bucket" {
  count = var.snapshot_agent.enabled ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${data.aws_s3_bucket.snapshot[0].arn}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:ListBucketVersions"]
    resources = [data.aws_s3_bucket.snapshot[0].arn]
  }
}

data "aws_s3_bucket" "snapshot" {
  count  = var.snapshot_agent.enabled ? 1 : 0
  bucket = var.snapshot_agent.s3_bucket_id
}
