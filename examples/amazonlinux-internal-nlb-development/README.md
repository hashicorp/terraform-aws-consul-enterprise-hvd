# Example Scenario - Amazon Linux | Internal Network Load Balancer (NLB) | Development Consul cluster

In this deployment the requirements are kept to a minimum and should provide an example of how resources are used but **not to be used in production**.

Data sources are configured to find the default VPC in the current account and region and deploy to the public subnets. TLS certificates are generated via Terraform and an initial root token is also injected via cloud-init. TLS certificates are created with appropriate flags and are created and automatically added to SSM secrets.

## Usage

```shell
# enter default example
cd ./examples/amazonlinux-internal-nlb-development
# create the license file and save it in a files directory
mkdir ./files
echo $CONSUL_LICENSE > ./files/consul.hclic
# export AWS creds (you could use a profile too)
export AWS_ACCESS_KEY_ID=ASIABASE32ENCODEDNU5
export AWS_SECRET_ACCESS_KEY=BigLongbase64encodedtextthatissecretOEcJ
export AWS_SESSION_TOKEN=AnotherbigLongbase64encodedtext
export AWS_ACCOUNT_ID=012345678901
# and region
export AWS_DEFAULT_REGION=ap-southeast-2
# now the Terraform part
terraform init -upgrade
terraform apply

# now you should be able to SSH into the instances
ssh -i consul-server.pem ec2-user@x.x.x.x
# from there you can tune consul as needed.
sudo -i
complete -C /usr/local/bin/consul consul
export CONSUL_CACERT=/etc/consul.d/tls/consul-ca.pem
export CONSUL_HTTP_ADDR=127.0.0.1:8501
export CONSUL_HTTP_SSL=true
export CONSUL_HTTP_TOKEN=2e5d48fd-a8da-bd2e-d9de-1ad409716a4f
export CONSUL_TLS_SERVER_NAME=server.dc1.consul
consul operator raft list-peers
```

To create a DNS policy and token you can follow the deployment guide to the [Create server tokens](https://developer.hashicorp.com/consul/tutorials/get-started-vms/virtual-machine-gs-deploy#create-server-tokens) section.

```shell
tee ./acl-policy-dns.hcl > /dev/null << EOF
## dns-request-policy.hcl
node_prefix "" {
  policy = "read"
}
service_prefix "" {
  policy = "read"
}
# Required if you use prepared queries
query_prefix "" {
  policy = "read"
}
EOF
consul acl policy create -name 'acl-policy-dns' -description 'Policy for DNS endpoints' -rules @./acl-policy-dns.hcl
consul acl token create -description 'DNS - Default token' -policy-name acl-policy-dns --format json | tee ./acl-token-dns.json
consul acl set-agent-token dns <token-from-the-secret-listed-above> 
```

## Notes

For a production system you should not use some of the options set in this example:

- Bootstrap the ACLs and don't use `var.initial_token`
- Don't generate TLS certificates in Terraform

<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_consul_development"></a> [consul\_development](#module\_consul\_development) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_key_pair.server_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_s3_bucket.snapshots](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.snapshots](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_secretsmanager_secret.consul_agent_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.consul_agent_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.consul_ca_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.consul_license_text](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.consul_agent_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.consul_agent_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.consul_ca_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.consul_license_text](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [local_sensitive_file.consul_ssh](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [tls_cert_request.server](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.server](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.consul_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.server](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.server_ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.consul_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
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
| <a name="input_consul_cluster_version"></a> [consul\_cluster\_version](#input\_consul\_cluster\_version) | SemVer version string representing the cluster's deploymentiteration. Must always be incremented when deploying updates (e.g. new AMIs, updated launch config) | `string` | `"0.0.1"` | no |
| <a name="input_consul_install_version"></a> [consul\_install\_version](#input\_consul\_install\_version) | Version of Consul to install, eg. '1.19.0+ent' | `string` | `"1.19.2+ent"` | no |
| <a name="input_consul_nodes"></a> [consul\_nodes](#input\_consul\_nodes) | Number of Consul nodes to deploy. | `number` | `3` | no |
| <a name="input_disk_params"></a> [disk\_params](#input\_disk\_params) | Disk parameters to use for the cluster nodes' block devices. | <pre>object({<br/>    root = object({<br/>      volume_type = string,<br/>      volume_size = number,<br/>      iops        = number<br/>    }),<br/>    data = object({<br/>      volume_type = string,<br/>      volume_size = number,<br/>      iops        = number<br/>    })<br/>  })</pre> | <pre>{<br/>  "data": {<br/>    "iops": 5000,<br/>    "volume_size": 100,<br/>    "volume_type": "io1"<br/>  },<br/>  "root": {<br/>    "iops": 0,<br/>    "volume_size": 32,<br/>    "volume_type": "gp2"<br/>  }<br/>}</pre> | no |
| <a name="input_gossip_encryption_key"></a> [gossip\_encryption\_key](#input\_gossip\_encryption\_key) | Consul gossip encryption key (consul keygen) | `string` | `"ITyqw6xrOrApx9B6P6k+HdFH8UD9M1UXu8XL6ZzWWJM="` | no |
| <a name="input_initial_token"></a> [initial\_token](#input\_initial\_token) | A UUID to use as the initial management token/snaphot token | `string` | `"2e5d48fd-a8da-bd2e-d9de-1ad409716a4f"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type to launch. | `string` | `"m5.large"` | no |
| <a name="input_license_text"></a> [license\_text](#input\_license\_text) | Enterprise license file contents (alternatively create consul.hclic) | `string` | `""` | no |
| <a name="input_permit_all_egress"></a> [permit\_all\_egress](#input\_permit\_all\_egress) | Whether broad (0.0.0.0/0) egress should be permitted on cluster nodes. If disabled, additional rules must be added to permit HTTP(S) and other necessary network access. | `bool` | `true` | no |
| <a name="input_route53_resolver_pool"></a> [route53\_resolver\_pool](#input\_route53\_resolver\_pool) | Enable .consul domain resolution with Route53 | <pre>object({<br/>    enabled         = bool<br/>    override_domain = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_server_redundancy_zones"></a> [server\_redundancy\_zones](#input\_server\_redundancy\_zones) | Whether Consul Enterprise Redundancy Zones should be enabled. Requires an even number of server nodes spread across 3+ availability zones. | `bool` | `false` | no |
| <a name="input_snapshot_agent"></a> [snapshot\_agent](#input\_snapshot\_agent) | Config object to enable snapshot agent. | <pre>object({<br/>    enabled      = bool<br/>    interval     = string<br/>    retention    = number<br/>    s3_bucket_id = string<br/>    token        = string<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "interval": "",<br/>  "retention": 0,<br/>  "s3_bucket_id": "",<br/>  "token": ""<br/>}</pre> | no |
<!-- END_TF_DOCS -->
