# Example deployment

In this example deployment the requirements are ket to a minimum and should provide examples of how resources are use but not to be used in production.

Data sources are configured to find the default VPC in the current account and region and deploy to the public subnets. TLS certificates are generated via Terraform and an initial root token is also injected via cloud-init. TLS certificates are created with appropriate flags are created and automatically added to SSM secrets.

## Usage

    # enter default example
    cd examples/default
    # create the license file
    echo $CONSUL_LICENSE > consul.hclic
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

To create a DNS policy and token you can follow the guide at [Create server tokens](https://developer.hashicorp.com/consul/tutorials/get-started-vms/virtual-machine-gs-deploy#create-server-tokens)

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
    consul acl set-agent-token dns token-from-the-secret-listed-above

## Notes

For a production system you should not use some of the options set in this example:
 - dont use the var.initial_token and instead bootstrap the ACLs instead.
 - extending ACL bootstrap, Agent, Anonymous and DNS tokens.
 - dont generate TLS certificates in terraform.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.60.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.5 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_servers"></a> [servers](#module\_servers) | git@github.com:hashicorp-services/terraform-aws-consul-ec2.git | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_key_pair.server_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_s3_bucket.snapshots](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.snapshots](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_ssm_parameter.consul_agent_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.consul_agent_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.consul_ca_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.consul_license_text](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
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
| <a name="input_gossip_encryption_key"></a> [gossip\_encryption\_key](#input\_gossip\_encryption\_key) | Consul gossip encryption key (consul keygen) | `string` | `"ITyqw6xrOrApx9B6P6k+HdFH8UD9M1UXu8XL6ZzWWJM="` | no |
| <a name="input_initial_token"></a> [initial\_token](#input\_initial\_token) | A UUID to use as the initial management token/snaphot token | `string` | `"2e5d48fd-a8da-bd2e-d9de-1ad409716a4f"` | no |
| <a name="input_license_text"></a> [license\_text](#input\_license\_text) | Enterprise license file contents (alternatively create consul.hclic) | `string` | `""` | no |
