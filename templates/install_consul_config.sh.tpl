#!/usr/bin/env bash
set -eu

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600")
AVAILABILITY_ZONE="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone -H "X-aws-ec2-metadata-token: $TOKEN" )"
REGION="$(curl -s http://169.254.169.254/latest/meta-data/placement/region -H "X-aws-ec2-metadata-token: $TOKEN" )"
INSTANCE="$(curl -s http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $TOKEN" )"

useradd --system --home /etc/consul.d --shell /bin/false consul

mkdir -p /etc/consul.d/tls

aws ssm get-parameter --with-decryption --name ${license_path} --query "Parameter.Value" --output text > /etc/consul.d/consul.hclic

aws ssm get-parameter --with-decryption --name ${ca_cert_path} --query "Parameter.Value" --output text > /etc/consul.d/tls/consul-ca.pem

aws ssm get-parameter --with-decryption --name ${agent_cert_path} --query "Parameter.Value" --output text > /etc/consul.d/tls/consul-cert.pem

aws ssm get-parameter --with-decryption --name ${agent_key_path} --query "Parameter.Value" --output text > /etc/consul.d/tls/consul-key.pem

tee /etc/consul.d/consul.hcl <<EOF
node_name = "$INSTANCE"
domain    = "${consul_agent.domain}"
data_dir  = "/var/lib/consul"
log_level = "${consul_agent.consul_log_level}"

datacenter         = "${consul_agent.datacenter}"
primary_datacenter = "${consul_agent.primary_datacenter}"

encrypt                 = "${consul_agent.gossip_encryption_key}"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true

%{ if consul_agent.bootstrap }bootstrap_expect = ${consul_nodes}%{ endif }

leave_on_terminate = true

server       = true
license_path = "/etc/consul.d/consul.hclic"

# Configure Redundancy Zones
autopilot {
%{ if consul_cluster_version != "" }  upgrade_version_tag = "cluster_version"%{ endif }
%{ if redundancy_zones }  redundancy_zone_tag = "zone"%{ endif }
  min_quorum          = ${consul_nodes}
}
node_meta {
  zone = "$AVAILABILITY_ZONE"
  cluster_version = "${consul_cluster_version}"
}

# Enable ACLs
acl {
  enabled                  = true
  default_policy           = "deny"
  down_policy              = "extend-cache"
  enable_token_replication = true
  enable_token_persistence = true
%{if consul_agent.initial_token != ""}
  tokens {
    agent              = "${consul_agent.initial_token}"
    initial_management = "${consul_agent.initial_token}"
  }
%{ endif }
}

client_addr = "0.0.0.0"

ports = {
  dns      = 8600
  grpc     = -1
  grpc_tls = 8503
  http     = -1
  https    = 8501
}

advertise_addr = "{{GetPrivateIP}}"

retry_join = ["provider=aws tag_key=Environment-Name tag_value=primary-consul"]

# TLS config
tls {
  defaults {
    verify_incoming = true
    verify_outgoing = true
    ca_file         = "/etc/consul.d/tls/consul-ca.pem"
    cert_file       = "/etc/consul.d/tls/consul-cert.pem"
    key_file        = "/etc/consul.d/tls/consul-key.pem"
  }

  # overrides tls.defaults path, if specified.
  https {
    verify_incoming = false
    verify_outgoing = true
  }
  grpc {
    verify_incoming = false
  }
  internal_rpc {
    verify_server_hostname = true
  }
}

auto_encrypt {
  allow_tls = true
}

telemetry {
  prometheus_retention_time = "480h"
  disable_hostname          = true
}

# Server performance config
limits {
  rpc_max_conns_per_client  = 100
  http_max_conns_per_client = 200
}

ui_config {
  enabled = ${consul_agent.ui}
}
EOF

tee /lib/systemd/system/consul.service <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
EnvironmentFile=-/etc/consul.d/consul.env
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

chown -R consul:consul /etc/consul.d
chown -R consul:consul /var/lib/consul
systemctl daemon-reload && systemctl enable --now consul.service
