# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0


variable "tag_owner" {
  type        = string
  description = "Denotes the user/entity responsible for deployment of this cluster."
}

variable "consul_nodes" {
  type        = number
  default     = 3
  description = "Number of Consul nodes to deploy."
}

variable "environment_name" {
  type        = string
  description = "Unique environment name to prefix and disambiguate resources using."
}

#------------------------------------------------------------------------------
# Consul
#------------------------------------------------------------------------------

variable "consul_install_version" {
  type        = string
  description = "Version of Consul to install, eg. '1.19.0+ent'"
  default     = "1.19.2+ent"
}

variable "consul_cluster_version" {
  type        = string
  description = "SemVer version string representing the cluster's deploymentiteration. Must always be incremented when deploying updates (e.g. new AMIs, updated launch config)"
  default     = "0.0.1"
}




variable "consul_agent" {
  type = object({
    bootstrap             = optional(bool, true)
    domain                = optional(string, "consul")
    datacenter            = string
    gossip_encryption_key = string
    consul_log_level      = string
    license_text_arn      = string
    primary_datacenter    = string
    ca_cert_arn           = string
    agent_cert_arn        = string
    agent_key_arn         = string
    initial_token         = string
    ui                    = optional(bool, true)
  })
  description = "Config object for the Consul Agent (Server/Client)"
  default = {
    bootstrap             = true
    domain                = "consul"
    datacenter            = "dc1"
    gossip_encryption_key = ""
    consul_log_level      = ""
    license_text_arn      = ""
    primary_datacenter    = "dc1"
    ca_cert_arn           = ""
    agent_cert_arn        = ""
    agent_key_arn         = ""
    initial_token         = ""
    ui                    = true
  }
}

variable "snapshot_agent" {
  type = object({
    enabled      = bool
    interval     = string
    retention    = number
    s3_bucket_id = string
    token        = string
  })
  default = {
    enabled      = false
    interval     = ""
    retention    = 0
    s3_bucket_id = ""
    token        = ""
  }
  description = "Config object to enable snapshot agent."
}
variable "consul_config_template" {
  type        = string
  default     = null
  nullable    = true
  description = "(Optional string) name of `*.tpl` file in the `./templates` folder local to the module decleration, to replace the root `install_consul_config.sh` "
  validation {
    condition     = var.consul_config_template == null || can(fileexists("${path.cwd}/templates/${var.consul_config_template}"))
    error_message = "File not found or not readable"
  }
}

variable "route53_resolver_pool" {
  type = object({
    enabled         = bool
    override_domain = optional(string)
  })
  default = {
    enabled = false
  }
  description = "Enable .consul domain resolution with Route53"
}

variable "autopilot_health_enabled" {
  type        = bool
  default     = true
  description = "Whether autopilot upgrade migration validation is performed for server nodes at boot-time"
}

variable "server_redundancy_zones" {
  type        = bool
  default     = false
  description = "Whether Consul Enterprise Redundancy Zones should be enabled. Requires an even number of server nodes spread across 3+ availability zones."
}

#------------------------------------------------------------------------------
# compute
#------------------------------------------------------------------------------
variable "asg_extra_tags" {
  type        = list(map(string))
  default     = []
  description = "Additional tags to apply to the Consul auto scaling group. See the Terraform Registry for syntax."
}


variable "ec2_os_distro" {
  type        = string
  description = "Linux OS distribution for Boundary EC2 instance. Choose from `amzn2`, `ubuntu`, `rhel`, `centos`."
  default     = "ubuntu"

  validation {
    condition     = contains(["amzn2", "ubuntu", "rhel", "centos"], var.ec2_os_distro)
    error_message = "Supported values are `amzn2`, `ubuntu`, `rhel` or `centos`."
  }
}
variable "ec2_ami_id" {
  type        = string
  description = "Custom AMI ID for Boundary EC2 Launch Template. If specified, value of `os_distro` must coincide with this custom AMI OS distro."
  default     = null

  validation {
    condition     = try((length(var.ec2_ami_id) > 4 && substr(var.ec2_ami_id, 0, 4) == "ami-"), var.ec2_ami_id == null)
    error_message = "Value must start with \"ami-\"."
  }
}
variable "key_name" {
  type        = string
  description = "SSH key name, already registered in AWS, to use for instance access"
}


variable "instance_type" {
  type        = string
  default     = "m5.large"
  description = "EC2 instance type to launch."
}

variable "additional_security_group_ids" {
  type        = list(string)
  default     = []
  description = "List of AWS security group IDs to apply to all cluster nodes."
}

variable "associate_public_ip" {
  type        = bool
  default     = false
  description = "Whether public IPv4 addresses should automatically be attached to cluster nodes."
}

variable "disk_params" {
  type = object({
    root = object({
      volume_type = string,
      volume_size = number,
      iops        = number
    }),
    data = object({
      volume_type = string,
      volume_size = number,
      iops        = number
    })
  })
  default = {
    root = {
      volume_type = "gp2"
      volume_size = 32
      iops        = 0
    }
    data = {
      volume_type = "io1"
      volume_size = 100
      iops        = 5000
    }
  }
  description = "Disk parameters to use for the cluster nodes' block devices."
}


#------------------------------------------------------------------------------
# Network
#------------------------------------------------------------------------------
variable "vpc_id" {
  type        = string
  description = "ID of the AWS VPC resources are deployed into."
  nullable    = true
}

variable "additional_gossip_cidrs" {
  type        = list(string)
  default     = []
  description = "List of additional CIDR blocks to permit Consul Gossip traffic to/from"
}

variable "additional_grpc_tls_cidrs" {
  type        = list(string)
  default     = []
  description = "List of additional CIDR blocks to permit Consul gRPC-TLS (peering, dataplane) traffic to/from. Automatically includes the local subnet."
}

variable "permit_all_egress" {
  type        = bool
  default     = true
  description = "Whether broad (0.0.0.0/0) egress should be permitted on cluster nodes. If disabled, additional rules must be added to permit HTTP(S) and other necessary network access."
}


variable "instance_subnets" {
  type        = list(string)
  description = "List of AWS subnet IDs for instance(s) to be deployed into."
}

variable "internal_nlb_subnets" {
  type        = list(string)
  description = "List of subnet IDs to provision internal NLB interfaces within."
}
