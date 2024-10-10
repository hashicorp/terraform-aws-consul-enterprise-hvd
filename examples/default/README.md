# Example deployment

In this deployment the requirements are kept to a minimum and should provide an example of how resources are used but **not to be used in production**.

Data sources are configured to find the default VPC in the current account and region and deploy to the public subnets. TLS certificates are generated via Terraform and an initial root token is also injected via cloud-init. TLS certificates are created with appropriate flags and are created and automatically added to SSM secrets.

## Usage

    ```shell
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
    ```

    To create a DNS policy and token you can follow the deployment guide t the [Create server tokens](https://developer.hashicorp.com/consul/tutorials/get-started-vms/virtual-machine-gs-deploy#create-server-tokens) section.

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
    consul acl set-agent-token dns token-from-the-secret-listed-above
    ```

## Notes

For a production system you should not use some of the options set in this example:

- Bootstrap the ACLs and don't use `var.initial_token`
- Don't generate TLS certificates in Terraform
