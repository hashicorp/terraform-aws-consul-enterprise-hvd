#!/usr/bin/env bash
set -eu

echo "Waiting for Consul agent to start"
while ! curl --fail --insecure --silent -H "X-Consul-Token: ${snapshot_agent.token}" https://127.0.0.1:8501/v1/status/leader; do
  echo "Local Consul agent not yet initialized. Retrying in 5 seconds..."
  sleep 5
done

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_REGION="$(curl -s http://169.254.169.254/latest/meta-data/placement/region -H "X-aws-ec2-metadata-token: $TOKEN" )"

mkdir -p /etc/consul-snapshot.d
tee /etc/consul-snapshot.d/consul-snapshot.json <<EOF
{
  "snapshot_agent": {
    "http_addr": "https://127.0.0.1:8501",
    "ca_file": "/etc/consul.d/tls/consul-ca.pem",
    "token": "${snapshot_agent.token}",
    "license_path": "/etc/consul.d/consul.hclic",
    "tls_server_name": "server.dc1.consul",
    "snapshot": {
      "interval": "${snapshot_agent.interval}",
      "retain": ${snapshot_agent.retention},
      "deregister_after": "8h"
    },
    "backup_destinations": {
      "aws_storage": [{
        "s3_key_prefix": "consul-snapshot",
        "s3_region": "$AWS_REGION",
        "s3_bucket": "${snapshot_agent.s3_bucket_id}"
      }]
    }
  }
}
EOF


tee /lib/systemd/system/consul-snapshot.service <<EOF
[Unit]
Description="HashiCorp Consul snapshot-agent"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul-snapshot.d/consul-snapshot.json

[Service]
Type=simple
User=consul
Group=consul
ExecStart=/usr/local/bin/consul snapshot agent -config-file=/etc/consul-snapshot.d/consul-snapshot.json
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

chown -R consul:consul /etc/consul-snapshot.d
systemctl daemon-reload && systemctl enable --now consul-snapshot.service
