resource "aws_route53_resolver_endpoint" "consul" {
  count     = var.route53_resolver_pool.enabled ? 1 : 0
  name      = "${var.environment_name}-resolver"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.dns_local_forwarder[0].id]

  dynamic "ip_address" {
    for_each = { for idx, subnet in var.instance_subnets : idx => subnet }
    content {
      subnet_id = ip_address.value
    }
  }
}

resource "aws_route53_resolver_rule" "fwd_consul" {
  count                = var.route53_resolver_pool.enabled ? 1 : 0
  domain_name          = var.route53_resolver_pool.override_domain == null ? var.consul_agent.domain : var.route53_resolver_pool.override_domain
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.consul[0].id

  dynamic "target_ip" {
    for_each = data.aws_network_interface.internal_nlb
    content {
      ip = target_ip.value.private_ip
    }
  }
}

resource "aws_route53_resolver_rule_association" "consul" {
  count            = var.route53_resolver_pool.enabled ? 1 : 0
  resolver_rule_id = aws_route53_resolver_rule.fwd_consul[0].id
  vpc_id           = data.aws_vpc.cluster.id
}
