## template: jinja
#!/usr/bin/env bash
export SHELLOPTS
set -euo pipefail

export CONSUL_HTTP_ADDR=127.0.0.1:8501
export CONSUL_CACERT=/etc/consul.d/tls/consul-ca.pem 
export CONSUL_HTTP_SSL=true

echo "Waiting for Consul agent to start"
while ! curl --fail --insecure --silent https://$${CONSUL_HTTP_ADDR}/v1/status/leader; do
  echo "Local Consul agent not yet initialized. Retrying in 5 seconds..."
  sleep 5
done

%{ if autopilot_health_enabled }
if jq -e '.acl.tokens | has("agent")' /etc/consul.d/secrets.json >/dev/null 2>&1; then
  CURL_CMD="curl --cacert /etc/consul.d/tls/consul-agent-ca.pem --fail --silent https://$${CONSUL_HTTP_ADDR}"
  LEADER=0
  VOTERS=0
  TOTAL_NEW=0

  # Wait until all new node versions are online
  until [[ $${TOTAL_NEW} -ge ${total_nodes} ]]; do
    if SVC_CONSUL=$($${CURL_CMD}/v1/catalog/service/consul); then
      TOTAL_NEW=$(echo $${SVC_CONSUL} | jq -er 'map(select(.NodeMeta.consul_cluster_version == "${consul_cluster_version}")) | length')
    else
      continue
    fi
    sleep 5
    echo "Current New Node Count: $${TOTAL_NEW}"
  done

  # Wait for a leader
  until [[ $${LEADER} -eq 1 ]]; do
    ((LEADER = 0)) || true
    echo "Fetching new node IDs"
    if SVC_CONSUL=$($${CURL_CMD}/v1/catalog/service/consul); then
      NEW_NODE_IDS=$(echo $${SVC_CONSUL} | jq -r 'map(select(.NodeMeta.consul_cluster_version == "${consul_cluster_version}")) | .[].ID')
    else
      continue
    fi
    # Wait until all new nodes are voting
    until [[ $${VOTERS} -eq ${total_voters} ]]; do
      ((VOTERS = 0)) || true
      for ID in $${NEW_NODE_IDS}; do
        sleep 2
        echo "Checking $${ID}"
        if AUTOPILOT_HEALTH=$($${CURL_CMD}/v1/operator/autopilot/health); then
          echo $${AUTOPILOT_HEALTH} | jq -e ".Servers[] | select(.ID == \"$${ID}\" and .Voter == true)" && ((VOTERS += 1)) && echo "Current Voters: $${VOTERS}"
        else
          continue
        fi
      done
    done
    echo "Checking Old Nodes"
    if SVC_CONSUL=$($${CURL_CMD}/v1/catalog/service/consul); then
      OLD_NODES=$(echo $${SVC_CONSUL} | jq -er 'map(select(.NodeMeta.consul_cluster_version != "${consul_cluster_version}")) | length')
    else
      continue
    fi
    echo "Current Old Node Count: $${OLD_NODES}"
    # Wait for old nodes to drop from voting
    until [[ $${OLD_NODES} -eq 0 ]]; do
      if SVC_CONSUL=$($${CURL_CMD}/v1/catalog/service/consul); then
        OLD_NODES=$(echo $${SVC_CONSUL} | jq -er 'map(select(.NodeMeta.consul_cluster_version != "${consul_cluster_version}")) | length')
        OLD_NODE_IDS=$(echo $${SVC_CONSUL} | jq -r 'map(select(.NodeMeta.consul_cluster_version != "${consul_cluster_version}")) | .[].ID')
        for ID in $${OLD_NODE_IDS}; do
          sleep 2
          echo "Checking Old $${ID}"
          if AUTOPILOT_HEALTH=$($${CURL_CMD}/v1/operator/autopilot/health); then
            echo $${AUTOPILOT_HEALTH} | jq -e ".Servers[] | select(.ID == \"$${ID}\" and .Voter == false)" && ((OLD_NODES -= 1)) && echo "Checking Old Nodes for Voters: $${OLD_NODES}"
          else
            continue
          fi
        done
      else
        continue
      fi
    done
    # Check if there is a leader running the newest version
    if AUTOPILOT_HEALTH=$($${CURL_CMD}/v1/operator/autopilot/health) && SVC_CONSUL=$($${CURL_CMD}/v1/catalog/service/consul); then
      LEADER_ID=$(echo $${AUTOPILOT_HEALTH} | jq -er ".Servers[] | select(.Leader == true) | .ID")
      echo $${SVC_CONSUL} | jq -er ".[] | select(.ID == \"$${LEADER_ID}\" and .NodeMeta.consul_cluster_version == \"${consul_cluster_version}\")" && ((LEADER += 1)) && echo "New Leader: $${LEADER_ID}"
    else
      continue
    fi
  done
fi

while true; do
  aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id '{{ v1.instance_id }}' --lifecycle-hook-name consul_health --auto-scaling-group-name '${asg_name}' --region '{{ v1.region }}' && break
  # Sleep for AWS race condition
  sleep 5
done
%{ else }
echo "Autopilot checks disabled, or node is not a server. Skipping cluster state validation."
%{ endif }
