# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "aws_launch_template" "consul" {
  name                   = local.template_name
  update_default_version = true

  image_id      = coalesce(local.ami_id_list...)
  instance_type = var.instance_type
  key_name      = var.key_name
  #user_data     = data.cloudinit_config.consul.rendered
  user_data = local.cloudinit_config_rendered

  instance_initiated_shutdown_behavior = "terminate"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      iops                  = var.disk_params.root.iops
      volume_size           = var.disk_params.root.volume_size
      volume_type           = var.disk_params.root.volume_type
    }
  }

  block_device_mappings {
    device_name = "/dev/sdf"
    ebs {
      delete_on_termination = true
      iops                  = var.disk_params.data.iops
      volume_size           = var.disk_params.data.volume_size
      volume_type           = var.disk_params.data.volume_type
    }
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups = concat([
      aws_security_group.consul_gossip.id,
      local.egress_sg_id,
      ],
      var.additional_security_group_ids
    )
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.consul.arn
  }
}

resource "aws_autoscaling_group" "consul" {
  name                      = local.asg_name
  min_size                  = var.consul_nodes
  max_size                  = var.consul_nodes
  desired_capacity          = var.consul_nodes
  wait_for_elb_capacity     = var.consul_nodes # Not evaluated for instances without ELB
  wait_for_capacity_timeout = "480s"
  health_check_grace_period = 15
  health_check_type         = "EC2"
  vpc_zone_identifier       = var.instance_subnets

  target_group_arns = aws_lb_target_group.dns[*].arn

  # Don't grab latest template if re-launching failed instances
  launch_template {
    id      = aws_launch_template.consul.id
    version = aws_launch_template.consul.latest_version
  }


  dynamic "initial_lifecycle_hook" {
    for_each = var.autopilot_health_enabled ? [1] : []
    content {
      name                 = "consul_health"
      default_result       = "ABANDON"
      heartbeat_timeout    = 7200
      lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    }
  }

  dynamic "tag" {
    for_each = { for s in local.tag_coll : s.key => s.value }
    iterator = each
    content {
      key                 = each.key
      value               = each.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    # Only update if user has incremented consul_cluster_version
    ignore_changes = [
      launch_template
    ]
  }
}

locals {

  cloudinit_config_rendered = data.cloudinit_config.consul.rendered
  #cloudinit_config_rendered = var.cloud_init_config_rendered == null ? data.cloudinit_config.consul.rendered : var.cloud_init_config_rendered
  egress_sg_id  = var.permit_all_egress ? aws_security_group.egress[0].id : ""
  template_name = "${var.environment_name}-consul"
  asg_name      = "${local.template_name}-${var.consul_cluster_version}"

  tag_coll = concat(
    [
      {
        key                 = "Cluster-Version"
        value               = var.consul_cluster_version
        propagate_at_launch = true
      },
      {
        key                 = "Environment-Name"
        value               = "${var.environment_name}-consul"
        propagate_at_launch = true
      },
      {
        key                 = "Name"
        value               = "${var.environment_name}-consul-${var.consul_cluster_version}"
        propagate_at_launch = true
      },
      {
        key                 = "Owner"
        value               = var.tag_owner
        propagate_at_launch = true
      },
    ],
    var.asg_extra_tags
  )
}
