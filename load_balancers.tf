# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

resource "aws_lb" "internal" {
  count              = var.route53_resolver_pool.enabled ? 1 : 0
  name               = "${var.environment_name}-internal"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.internal_nlb_subnets
}

data "aws_network_interface" "internal_nlb" {
  for_each = length(aws_lb.internal) > 0 ? { for idx, subnet in var.internal_nlb_subnets : idx => subnet } : {}

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.internal[0].arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [each.value]
  }
}

resource "aws_lb_target_group" "dns" {
  count                  = var.route53_resolver_pool.enabled ? 1 : 0
  name                   = "${var.environment_name}-dns"
  target_type            = "instance"
  port                   = 8600
  protocol               = "TCP_UDP"
  vpc_id                 = data.aws_vpc.cluster.id
  deregistration_delay   = 15
  connection_termination = true

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "dns" {
  count             = var.route53_resolver_pool.enabled ? 1 : 0
  load_balancer_arn = aws_lb.internal[0].id
  port              = 53
  protocol          = "TCP_UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dns[0].arn
  }
}
