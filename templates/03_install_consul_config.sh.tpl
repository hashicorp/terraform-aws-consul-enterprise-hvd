#!/usr/bin/env bash
set -eu
LOGFILE="/var/log/consul-cloud-init.log"

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600")
AVAILABILITY_ZONE="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone -H "X-aws-ec2-metadata-token: $TOKEN" )"
AWS_REGION="$(curl -s http://169.254.169.254/latest/meta-data/placement/region -H "X-aws-ec2-metadata-token: $TOKEN" )"
INSTANCE="$(curl -s http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $TOKEN" )"
CONSUL_CONFIG_DIR="/etc/consul.d"
CONSUL_TLS_CERTS_DIR="$CONSUL_CONFIG_DIR/tls"
CONSUL_LICENSE_PATH="$CONSUL_CONFIG_DIR/consul.hclic"
CONSUL_DATA_DIR="/opt/consul"
SYSTEM_DIR="/etc/systemd/system"
CONSUL_BIN_DIR="/usr/local/bin"

# useradd --system --home $CONSUL_CONFIG_DIR --shell /bin/false consul

mkdir -p $CONSUL_TLS_CERTS_DIR
function log {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local log_entry="$timestamp [$level] - $message"

  echo "$log_entry" | tee -a "$LOGFILE"
}
function retrieve_license_from_awssm {
  local SECRET_ARN="$1"
  local SECRET_REGION=$AWS_REGION

  if [[ -z "$SECRET_ARN" ]]; then
    log "ERROR" "Secret ARN cannot be empty. Exiting."
    exit_script 4
  elif [[ "$SECRET_ARN" == arn:aws:secretsmanager:* ]]; then
    log "INFO" "Retrieving value of secret '$SECRET_ARN' from AWS Secrets Manager."
    CONSUL_LICENSE=$(aws secretsmanager get-secret-value --region $SECRET_REGION --secret-id $SECRET_ARN --query SecretString --output text)
    echo "$CONSUL_LICENSE" > $CONSUL_LICENSE_PATH
  else
    log "WARNING" "Did not detect AWS Secrets Manager secret ARN. Setting value of secret to what was passed in."
    CONSUL_LICENSE="$SECRET_ARN"
    echo "$CONSUL_LICENSE" > $CONSUL_LICENSE_PATH
  fi
}
log "INFO" "Retrieving CONSUL license file..."
retrieve_license_from_awssm "${license_text_arn}"

# aws ssm get-parameter --with-decryption --name \$\{license_path} --query "Parameter.Value" --output text > /etc/consul.d/consul.hclic

function retrieve_certs_from_awssm {
  local SECRET_ARN="$1"
  local DESTINATION_PATH="$2"
  local SECRET_REGION=$AWS_REGION
  local CERT_DATA

  if [[ -z "$SECRET_ARN" ]]; then
    log "ERROR" "Secret ARN cannot be empty. Exiting."
    exit_script 5
  elif [[ "$SECRET_ARN" == arn:aws:secretsmanager:* ]]; then
    log "INFO" "Retrieving value of secret '$SECRET_ARN' from AWS Secrets Manager."
    CERT_DATA=$(aws secretsmanager get-secret-value --region $SECRET_REGION --secret-id $SECRET_ARN --query SecretString --output text)
    echo "$CERT_DATA" | base64 -d > $DESTINATION_PATH
  else
    log "WARNING" "Did not detect AWS Secrets Manager secret ARN. Setting value of secret to what was passed in."
    CERT_DATA="$SECRET_ARN"
    echo "$CERT_DATA" | base64 -d > $DESTINATION_PATH
  fi
}

# aws ssm get-parameter --with-decryption --name \$\{ca_cert_path} --query "Parameter.Value" --output text > /etc/consul.d/tls/consul-ca.pem

# aws ssm get-parameter --with-decryption --name \$\{agent_cert_path} --query "Parameter.Value" --output text > /etc/consul.d/tls/consul-cert.pem

# aws ssm get-parameter --with-decryption --name \$\{agent_key_path} --query "Parameter.Value" --output text > /etc/consul.d/tls/consul-key.pem
log "INFO" "Retrieving CONSUL TLS certificate..."
retrieve_certs_from_awssm "${agent_cert_arn}" "$CONSUL_TLS_CERTS_DIR/consul-cert.pem"
log "INFO" "Retrieving CONSUL TLS private key..."
retrieve_certs_from_awssm "${agent_key_arn}" "$CONSUL_TLS_CERTS_DIR/consul-key.pem"
log "INFO" "Retrieving CONSUL TLS CA bundle..."
retrieve_certs_from_awssm "${ca_cert_arn}" "$CONSUL_TLS_CERTS_DIR/consul-ca.pem"

log "INFO" "Creating Consul configuration file at $CONSUL_CONFIG_DIR/consul.hcl"

tee $CONSUL_CONFIG_DIR/consul.hcl <<EOF
node_name = "$INSTANCE"
domain    = "${consul_agent.domain}"
data_dir  = $CONSUL_DATA_DIR
log_level = "${consul_agent.consul_log_level}"

datacenter         = "${consul_agent.datacenter}"
primary_datacenter = "${consul_agent.primary_datacenter}"

encrypt                 = "${consul_agent.gossip_encryption_key}"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true

%{ if consul_agent.bootstrap }bootstrap_expect = ${consul_nodes}%{ endif }

leave_on_terminate = true

server       = true
license_path = "$CONSUL_CONFIG_DIR/consul.hclic"

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

retry_join = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}-consul"]

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

log "INFO" "Created Consul configuration file at '$SYSTEM_DIR/consul.service'."
tee $SYSTEM_DIR/consul.service <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=$CONSUL_CONFIG_DIR/consul.hcl

[Service]
Type=notify
EnvironmentFile=$CONSUL_CONFIG_DIR/consul.env
User=consul
Group=consul
ExecStart=$CONSUL_BIN_DIR/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

tee $CONSUL_CONFIG_DIR/consul.env <<EOF

EOF

log "INFO" "Created Consul service file at '$SYSTEM_DIR/consul.service'."

log "INFO" "Setting permissions for Consul configuration directory and files..."
chown -R consul:consul $CONSUL_CONFIG_DIR
chown -R consul:consul $CONSUL_DATA_DIR

log "INFO" "Starting Consul service..."
systemctl daemon-reload && systemctl enable --now consul.service
