# Consul Enterprise HVD on AWS EC2

Terraform module aligned with HashiCorp Validated Designs (HVD) to deploy Consul Enterprise on Amazon Web Services (AWS) using EC2 instances. It provides options for defining the size of the cluster and options to use redundancy zones.

![Consul architecture](https://developer.hashicorp.com/.extracted/hvd/img/consul/solution-design-guides/consul-enterprise/consul-aws-arch-vms.png)

## Prerequisites

This module requires the following to already be in place in AWS:

- An AWS account
- A VPC with at least 3 availability zones
- An S3 Bucket for snapshots
- Certificates added to AWS Systems Manager (SSM)
- Consul License added to AWS Systems Manager (SSM)
- An AMI to launch ASG instances from
- List of AWS subnet IDs for instance(s) to be deployed into
- List of subnet IDs to provision internal NLB interfaces within (optional)
- SSH key name, already registered in AWS, to use for instance access
- ID of the AWS VPC resources are deployed into

## Examples

The `examples/amazonlinux-internal-nlb-consul-primary` folder contains the default deployment setup demonstrating the default options and providing place holders for reuse.

The `examples/amazonlinux-internal-nlb-development` folder uses public subnets and self-signed certificates for a **non-production environment** but illustrates how to enable all features of the root module.

## Docs

Additional documentation for customization and usage can be found in the [docs](./docs/) folder.

## Module support

This open source software is maintained by the HashiCorp Technical Field Organization, independently of our enterprise products. While our Support Engineering team provides dedicated support for our enterprise offerings, this open source software is not included.

- For help using this open source software, please engage your account team.
- To report bugs/issues with this open source software, please open them directly against this code repository using the GitHub issues feature.

Please note that there is no official Service Level Agreement (SLA) for support of this software as a HashiCorp customer. This software falls under the definition of Community Software/Versions in your Agreement. We appreciate your understanding and collaboration in improving our open source projects.

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
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | >= 2.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.consul_discovery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.consul_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.consul_snapshots](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_launch_template.consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_resolver_endpoint.consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_endpoint) | resource |
| [aws_route53_resolver_rule.fwd_consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53_resolver_rule_association.consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule_association) | resource |
| [aws_security_group.consul_gossip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.dns_local_forwarder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.amzn2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.centos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.rhel](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.consul_discovery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.consul_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ec2_assumerole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.snapshot_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_network_interface.internal_nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_subnet.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [cloudinit_config.consul](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Unique environment name to prefix and disambiguate resources using. | `string` | n/a | yes |
| <a name="input_instance_subnets"></a> [instance\_subnets](#input\_instance\_subnets) | List of AWS subnet IDs for instance(s) to be deployed into. | `list(string)` | n/a | yes |
| <a name="input_internal_nlb_subnets"></a> [internal\_nlb\_subnets](#input\_internal\_nlb\_subnets) | List of subnet IDs to provision internal NLB interfaces within. | `list(string)` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key name, already registered in AWS, to use for instance access | `string` | n/a | yes |
| <a name="input_tag_owner"></a> [tag\_owner](#input\_tag\_owner) | Denotes the user/entity responsible for deployment of this cluster. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the AWS VPC resources are deployed into. | `string` | n/a | yes |
| <a name="input_additional_gossip_cidrs"></a> [additional\_gossip\_cidrs](#input\_additional\_gossip\_cidrs) | List of additional CIDR blocks to permit Consul Gossip traffic to/from | `list(string)` | `[]` | no |
| <a name="input_additional_grpc_tls_cidrs"></a> [additional\_grpc\_tls\_cidrs](#input\_additional\_grpc\_tls\_cidrs) | List of additional CIDR blocks to permit Consul gRPC-TLS (peering, dataplane) traffic to/from. Automatically includes the local subnet. | `list(string)` | `[]` | no |
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | List of AWS security group IDs to apply to all cluster nodes. | `list(string)` | `[]` | no |
| <a name="input_asg_extra_tags"></a> [asg\_extra\_tags](#input\_asg\_extra\_tags) | Additional tags to apply to the Consul auto scaling group. See the Terraform Registry for syntax. | `list(map(string))` | `[]` | no |
| <a name="input_associate_public_ip"></a> [associate\_public\_ip](#input\_associate\_public\_ip) | Whether public IPv4 addresses should automatically be attached to cluster nodes. | `bool` | `false` | no |
| <a name="input_autopilot_health_enabled"></a> [autopilot\_health\_enabled](#input\_autopilot\_health\_enabled) | Whether autopilot upgrade migration validation is performed for server nodes at boot-time | `bool` | `true` | no |
| <a name="input_consul_agent"></a> [consul\_agent](#input\_consul\_agent) | Config object for the Consul Agent (Server/Client) | <pre>object({<br/>    bootstrap             = optional(bool, true)<br/>    domain                = optional(string, "consul")<br/>    datacenter            = string<br/>    gossip_encryption_key = string<br/>    consul_log_level      = string<br/>    license_text_arn      = string<br/>    primary_datacenter    = string<br/>    ca_cert_arn           = string<br/>    agent_cert_arn        = string<br/>    agent_key_arn         = string<br/>    initial_token         = string<br/>    ui                    = optional(bool, true)<br/>  })</pre> | <pre>{<br/>  "agent_cert_arn": "",<br/>  "agent_key_arn": "",<br/>  "bootstrap": true,<br/>  "ca_cert_arn": "",<br/>  "consul_log_level": "",<br/>  "datacenter": "dc1",<br/>  "domain": "consul",<br/>  "gossip_encryption_key": "",<br/>  "initial_token": "",<br/>  "license_text_arn": "",<br/>  "primary_datacenter": "dc1",<br/>  "ui": true<br/>}</pre> | no |
| <a name="input_consul_cluster_version"></a> [consul\_cluster\_version](#input\_consul\_cluster\_version) | SemVer version string representing the cluster's deploymentiteration. Must always be incremented when deploying updates (e.g. new AMIs, updated launch config) | `string` | `"0.0.1"` | no |
| <a name="input_consul_config_template"></a> [consul\_config\_template](#input\_consul\_config\_template) | (Optional string) name of `*.tpl` file in the `./templates` folder local to the module decleration, to replace the root `install_consul_config.sh` | `string` | `null` | no |
| <a name="input_consul_install_version"></a> [consul\_install\_version](#input\_consul\_install\_version) | Version of Consul to install, eg. '1.19.0+ent' | `string` | `"1.19.2+ent"` | no |
| <a name="input_consul_nodes"></a> [consul\_nodes](#input\_consul\_nodes) | Number of Consul nodes to deploy. | `number` | `3` | no |
| <a name="input_disk_params"></a> [disk\_params](#input\_disk\_params) | Disk parameters to use for the cluster nodes' block devices. | <pre>object({<br/>    root = object({<br/>      volume_type = string,<br/>      volume_size = number,<br/>      iops        = number<br/>    }),<br/>    data = object({<br/>      volume_type = string,<br/>      volume_size = number,<br/>      iops        = number<br/>    })<br/>  })</pre> | <pre>{<br/>  "data": {<br/>    "iops": 5000,<br/>    "volume_size": 100,<br/>    "volume_type": "io1"<br/>  },<br/>  "root": {<br/>    "iops": 0,<br/>    "volume_size": 32,<br/>    "volume_type": "gp2"<br/>  }<br/>}</pre> | no |
| <a name="input_ec2_ami_id"></a> [ec2\_ami\_id](#input\_ec2\_ami\_id) | Custom AMI ID for Boundary EC2 Launch Template. If specified, value of `os_distro` must coincide with this custom AMI OS distro. | `string` | `null` | no |
| <a name="input_ec2_os_distro"></a> [ec2\_os\_distro](#input\_ec2\_os\_distro) | Linux OS distribution for Boundary EC2 instance. Choose from `amzn2`, `ubuntu`, `rhel`, `centos`. | `string` | `"ubuntu"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type to launch. | `string` | `"m5.large"` | no |
| <a name="input_permit_all_egress"></a> [permit\_all\_egress](#input\_permit\_all\_egress) | Whether broad (0.0.0.0/0) egress should be permitted on cluster nodes. If disabled, additional rules must be added to permit HTTP(S) and other necessary network access. | `bool` | `true` | no |
| <a name="input_route53_resolver_pool"></a> [route53\_resolver\_pool](#input\_route53\_resolver\_pool) | Enable .consul domain resolution with Route53 | <pre>object({<br/>    enabled         = bool<br/>    override_domain = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_server_redundancy_zones"></a> [server\_redundancy\_zones](#input\_server\_redundancy\_zones) | Whether Consul Enterprise Redundancy Zones should be enabled. Requires an even number of server nodes spread across 3+ availability zones. | `bool` | `false` | no |
| <a name="input_snapshot_agent"></a> [snapshot\_agent](#input\_snapshot\_agent) | Config object to enable snapshot agent. | <pre>object({<br/>    enabled      = bool<br/>    interval     = string<br/>    retention    = number<br/>    s3_bucket_id = string<br/>    token        = string<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "interval": "",<br/>  "retention": 0,<br/>  "s3_bucket_id": "",<br/>  "token": ""<br/>}</pre> | no |
<!-- END_TF_DOCS -->
