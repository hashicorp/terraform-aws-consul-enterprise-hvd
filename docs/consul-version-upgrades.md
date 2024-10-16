# Consul version upgrades

First review the standard documentation for [upgrading Consul](https://developer.hashicorp.com/consul/docs/upgrading).

## Automated upgrades

This feature requires HashiCorp Cloud Platform (HCP) or self-managed Consul Enterprise. Refer to [the upgrade documentation](https://developer.hashicorp.com/consul/docs/enterprise/upgrades) for additional information.
Consul Enterprise enables the capability of automatically upgrading a cluster of Consul servers to a new version as updated server nodes join the cluster. This automated upgrade will spawn a process which monitors the amount of voting members currently in a cluster. When an equal amount of new server nodes are joined running the desired version, the lower versioned servers will be demoted to non voting members. Demotion of legacy server nodes will not occur until the voting members on the new version match. Once this demotion occurs, the previous versioned servers can be removed from the cluster safely.

Review the [Consul operator autopilot](https://developer.hashicorp.com/consul/commands/operator/autopilot) documentation and complete the [Automated Upgrade](https://developer.hashicorp.com/consul/tutorials/datacenter-operations/autopilot-datacenter-operations#upgrade-migrations) tutorial to learn more about automated upgrades.

### Module support


The module supports specifying the deployment version.

```json
variable "consul_install_version" {
  type        = string
  description = "Version of Consul to install, eg. '1.19.0+ent'"
  default     = "1.19.2+ent"
}
```

The module includes a variable `autopilot_health_enabled` which defaults to true and supports the validation of new servers upgraded following the above process.

The `module.<name>.aws_autoscaling_group.consul` resource supports the deployment with automated upgrades.

```json

resource "aws_autoscaling_group" "consul" {
...
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
...

  lifecycle {
    create_before_destroy = true
    # Only update if user has incremented consul_cluster_version
    ignore_changes = [
      launch_template
    ]
  }
}
```

This means you should (where possible and to prevent data loss) follow the standard operating procedure and ensure a backup and recovery process is in place and used accordingly. See the tutorial on [backup and restore](https://developer.hashicorp.com/consul/tutorials/operate-consul/backup-and-restore ).

Use the automated upgrade process. Once the upgrade is successful you can update the `var.consul_install_version` in your deployment and replace the `aws_launch_template` which will then mean any future server failures in the `aws_autoscaling_group.consul` resource will relaunch on the correct version.
