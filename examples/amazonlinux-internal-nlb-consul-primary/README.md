# Example Scenario - Amazon Linux | Internal Network Load Balancer (NLB) | Primary Consul cluster



<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.65 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >= 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.65 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_default"></a> [default](#module\_default) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ami.amazonlinux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_subnets.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI to launch ASG instances from. | `string` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Unique environment name to prefix and disambiguate resources using. | `string` | n/a | yes |
| <a name="input_instance_subnets"></a> [instance\_subnets](#input\_instance\_subnets) | List of AWS subnet IDs for instance(s) to be deployed into. | `list(string)` | n/a | yes |
| <a name="input_internal_nlb_subnets"></a> [internal\_nlb\_subnets](#input\_internal\_nlb\_subnets) | List of subnet IDs to provision internal NLB interfaces within. | `list(string)` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key name, already registered in AWS, to use for instance access | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where consul will be deployed. | `string` | n/a | yes |
| <a name="input_tag_owner"></a> [tag\_owner](#input\_tag\_owner) | Denotes the user/entity responsible for deployment of this cluster. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the AWS VPC resources are deployed into. | `string` | n/a | yes |
| <a name="input_additional_gossip_cidrs"></a> [additional\_gossip\_cidrs](#input\_additional\_gossip\_cidrs) | List of additional CIDR blocks to permit Consul Gossip traffic to/from | `list(string)` | `[]` | no |
| <a name="input_additional_grpc_tls_cidrs"></a> [additional\_grpc\_tls\_cidrs](#input\_additional\_grpc\_tls\_cidrs) | List of additional CIDR blocks to permit Consul gRPC-TLS (peering, dataplane) traffic to/from. Automatically includes the local subnet. | `list(string)` | `[]` | no |
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | List of AWS security group IDs to apply to all cluster nodes. | `list(string)` | `[]` | no |
| <a name="input_asg_extra_tags"></a> [asg\_extra\_tags](#input\_asg\_extra\_tags) | Additional tags to apply to the Consul auto scaling group. See the Terraform Registry for syntax. | `list(map(string))` | `[]` | no |
| <a name="input_associate_public_ip"></a> [associate\_public\_ip](#input\_associate\_public\_ip) | Whether public IPv4 addresses should automatically be attached to cluster nodes. | `bool` | `false` | no |
| <a name="input_autopilot_health_enabled"></a> [autopilot\_health\_enabled](#input\_autopilot\_health\_enabled) | Whether autopilot upgrade migration validation is performed for server nodes at boot-time | `bool` | `true` | no |
| <a name="input_consul_agent"></a> [consul\_agent](#input\_consul\_agent) | Config object for the Consul Agent (Server/Client) | <pre>object({<br/>    bootstrap             = optional(bool, true)<br/>    domain                = optional(string, "consul")<br/>    datacenter            = string<br/>    gossip_encryption_key = string<br/>    consul_log_level      = string<br/>    license_text_arn      = string<br/>    primary_datacenter    = string<br/>    ca_cert_arn           = string<br/>    agent_cert_arn        = string<br/>    agent_key_arn         = string<br/>    initial_token         = string<br/>    ui                    = optional(bool, true)<br/>  })</pre> | <pre>{<br/>  "agent_cert_arn": "",<br/>  "agent_key_arn": "",<br/>  "bootstrap": true,<br/>  "ca_cert_arn": "",<br/>  "consul_log_level": "",<br/>  "datacenter": "dc1",<br/>  "domain": "consul",<br/>  "gossip_encryption_key": "",<br/>  "initial_token": "",<br/>  "license_text_arn": "",<br/>  "primary_datacenter": "dc1",<br/>  "ui": true<br/>}</pre> | no |
| <a name="input_consul_cluster_version"></a> [consul\_cluster\_version](#input\_consul\_cluster\_version) | SemVer version string representing the cluster's deployent iteration. Must always be incremented when deploying updates (e.g. new AMIs, updated launch config) | `string` | `"0.0.1"` | no |
| <a name="input_consul_install_version"></a> [consul\_install\_version](#input\_consul\_install\_version) | Version of Consul to install, eg. '1.19.0+ent' | `string` | `"1.19.2+ent"` | no |
| <a name="input_consul_nodes"></a> [consul\_nodes](#input\_consul\_nodes) | Number of Consul nodes to deploy. | `number` | `3` | no |
| <a name="input_disk_params"></a> [disk\_params](#input\_disk\_params) | Disk parameters to use for the cluster nodes' block devices. | <pre>object({<br/>    root = object({<br/>      volume_type = string,<br/>      volume_size = number,<br/>      iops        = number<br/>    }),<br/>    data = object({<br/>      volume_type = string,<br/>      volume_size = number,<br/>      iops        = number<br/>    })<br/>  })</pre> | <pre>{<br/>  "data": {<br/>    "iops": 5000,<br/>    "volume_size": 100,<br/>    "volume_type": "io1"<br/>  },<br/>  "root": {<br/>    "iops": 0,<br/>    "volume_size": 32,<br/>    "volume_type": "gp2"<br/>  }<br/>}</pre> | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type to launch. | `string` | `"m5.large"` | no |
| <a name="input_permit_all_egress"></a> [permit\_all\_egress](#input\_permit\_all\_egress) | Whether broad (0.0.0.0/0) egress should be permitted on cluster nodes. If disabled, additional rules must be added to permit HTTP(S) and other necessary network access. | `bool` | `true` | no |
| <a name="input_route53_resolver_pool"></a> [route53\_resolver\_pool](#input\_route53\_resolver\_pool) | Enable .consul domain resolution with Route53 | <pre>object({<br/>    enabled         = bool<br/>    override_domain = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_server_redundancy_zones"></a> [server\_redundancy\_zones](#input\_server\_redundancy\_zones) | Whether Consul Enterprise Redundancy Zones should be enabled. Requires an even number of server nodes spread across 3+ availability zones. | `bool` | `false` | no |
| <a name="input_snapshot_agent"></a> [snapshot\_agent](#input\_snapshot\_agent) | Config object to enable snapshot agent. | <pre>object({<br/>    enabled      = bool<br/>    interval     = string<br/>    retention    = number<br/>    s3_bucket_id = string<br/>    token        = string<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "interval": "",<br/>  "retention": 0,<br/>  "s3_bucket_id": "",<br/>  "token": ""<br/>}</pre> | no |
<!-- END_TF_DOCS -->
