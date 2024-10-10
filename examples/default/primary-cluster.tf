data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazonlinux" {
  most_recent = true
  name_regex  = "^al2023-ami-"
  owners      = ["amazon"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "servers" {
  source = "../../"

  # Instance Configuration
  ami_id               = data.aws_ami.amazonlinux.id
  instance_type        = "m5.large"
  key_name             = aws_key_pair.server_ssh.id
  vpc_id               = data.aws_vpc.default.id
  instance_subnets     = data.aws_subnets.default.ids
  internal_nlb_subnets = data.aws_subnets.default.ids
  associate_public_ip  = true

  # Cluster Details
  consul_install_version = "1.19.0+ent"
  consul_cluster_version = "0.0.1"
  consul_nodes           = 3         # double the number of zones.
  environment_name       = "primary" # Used for auto-join tagging
  tag_owner              = "someone@hashicorp.com"

  server_redundancy_zones = false

  disk_params = {
    root = {
      volume_type = "gp3"
      volume_size = 32
      iops        = 3000
    },
    data = {
      volume_type = "gp3"
      volume_size = 100
      iops        = 3000
    }
  }

  consul_agent = {
    bootstrap             = true
    server                = true
    datacenter            = "dc1"
    gossip_encryption_key = var.gossip_encryption_key
    initial_token         = var.initial_token
    primary_datacenter    = "dc1"
    license_text_arn      = aws_ssm_parameter.consul_license_text.arn
    ca_cert_arn           = aws_ssm_parameter.consul_ca_cert.arn
    agent_cert_arn        = aws_ssm_parameter.consul_agent_cert.arn
    agent_key_arn         = aws_ssm_parameter.consul_agent_key.arn
    ui                    = true
    consul_log_level      = "INFO"
  }

  snapshot_agent = {
    enabled      = true
    interval     = "60m"
    retention    = 24
    s3_bucket_id = aws_s3_bucket.snapshots.id
    token        = var.initial_token
  }
}

resource "aws_s3_bucket" "snapshots" {
  bucket_prefix = "consul-snapshots-"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "snapshots" {
  bucket = aws_s3_bucket.snapshots.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "deny" {
  bucket                  = aws_s3_bucket.snapshots.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
