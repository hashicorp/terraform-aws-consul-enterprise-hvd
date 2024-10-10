#/////////////////////////////////////
#/ Consul Gossip Security Group
#/ Permits Consul LAN gossip and 
#/ server RPC traffic to trusted 
#/ subnets.
#/////////////////////////////////////

resource "aws_security_group" "consul_gossip" {
  name        = "${var.environment_name}-consul-gossip"
  description = "Permit Consul gossip traffic"
  vpc_id      = data.aws_vpc.cluster.id

  # Allow Consul Server RPC.
  ingress {
    description = "Consul Server RPC"
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = local.consul_gossip_cidrs
  }

  # Allow Consul Server API.
  ingress {
    description = "Consul Server API"
    from_port   = 8500
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.cluster.cidr_block]
  }

  egress {
    description = "Consul Server RPC"
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = local.consul_gossip_cidrs
  }

  # Allow LAN gossip within trusted subnets.
  ingress {
    description = "Consul Gossip (TCP)"
    from_port   = 8301
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = local.consul_gossip_cidrs
  }

  egress {
    description = "Consul Gossip (TCP)"
    from_port   = 8301
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = local.consul_gossip_cidrs
  }

  ingress {
    description = "Consul Gossip (UDP)"
    from_port   = 8301
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = local.consul_gossip_cidrs
  }
  egress {
    description = "Consul Gossip (UDP)"
    from_port   = 8301
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = local.consul_gossip_cidrs
  }

  ingress {
    description = "Consul gRPC-TLS"
    from_port   = 8503
    to_port     = 8503
    protocol    = "tcp"
    cidr_blocks = local.consul_grpc_tls_cidrs
  }
  egress {
    description = "Consul gRPC-TLS"
    from_port   = 8503
    to_port     = 8503
    protocol    = "tcp"
    cidr_blocks = local.consul_grpc_tls_cidrs
  }

  # Allow SSH in from within the VPC
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = [data.aws_vpc.cluster.cidr_block]
  }

  # Allow inbound DNS queries from the local Route53 Resolver endpoints
  # TODO: In a 3-az setup, this fans out to 12 SG rule line items.
  #       Would it be better to just whitelist the VPC?
  dynamic "ingress" {
    for_each = var.route53_resolver_pool.enabled ? ["tcp", "udp"] : []

    content {
      description = "Consul DNS (${upper(ingress.value)})"
      from_port   = 8600
      to_port     = 8600
      protocol    = ingress.value
      cidr_blocks = local.consul_dns_cidrs
    }
  }
}

#/////////////////////////////////////
#/ General Egress Security Group
#/ (Optional) Permits all egress traffic.
#/ Controlled by var.permit_all_egress
#/////////////////////////////////////

resource "aws_security_group" "egress" {
  count       = var.permit_all_egress ? 1 : 0
  name        = "${var.environment_name}-egress"
  description = "Permit all egress traffic"
  vpc_id      = data.aws_vpc.cluster.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#/////////////////////////////////////
#/ DNS Local Forwarder Security Group
#/ Permits the Route53 Resolver LAN endpoints
#/ to forward DNS queries to the internal NLB
#/////////////////////////////////////

resource "aws_security_group" "dns_local_forwarder" {
  count       = var.route53_resolver_pool.enabled ? 1 : 0
  name        = "${var.environment_name}-resolver"
  description = "Permit Route53 resolver to communicate with DNS nodes"
  vpc_id      = data.aws_vpc.cluster.id

  egress {
    description = "DNS (TCP)"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [for eni in data.aws_network_interface.internal_nlb : "${eni.private_ip}/32"]
  }

  egress {
    description = "DNS (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [for eni in data.aws_network_interface.internal_nlb : "${eni.private_ip}/32"]
  }
}

locals {
  consul_gossip_cidrs   = concat([data.aws_vpc.cluster.cidr_block], var.additional_gossip_cidrs)
  consul_grpc_tls_cidrs = concat([data.aws_vpc.cluster.cidr_block], var.additional_grpc_tls_cidrs)
  consul_dns_cidrs = var.route53_resolver_pool.enabled ? concat(
    [for ip in aws_route53_resolver_endpoint.consul[0].ip_address[*].ip : "${ip}/32"],
    [for eni in data.aws_network_interface.internal_nlb : "${eni.private_ip}/32"] # Permit NLB active health checks
  ) : null
}
