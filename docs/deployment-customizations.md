
# Deployment customization

## TLS

Certificates are provided at startup via cloud-init. Follow the example to structure your certificates correctly.

## Adding a Consul license

To see an example of how to automate the addition of your Consul license to SSM, place the license file in the example directory. The Terraform module will handle the rest.

## Customizing options with tf.autovars.tfvars

Use the `consul.auto.tfvars.example` file to customize various options for your Consul deployment. By modifying this file, you can set specific values for the variables used in the module, such as the number of nodes, redundancy settings, and other configurations. Copy the file to `consul.auto.tfvars` file with your desired settings and run your Terraform commands to apply them.

## Redundancy zones

To enable Consul Enterprise Redundancy Zones, set the `server_redundancy_zones` variable to `true`. This feature requires an even number of server nodes spread across 3 or more availability zones. Additionally, set the `consul_nodes` variable to `6` to meet this requirement.

### Configuration options

- **server_redundancy_zones**: Set to `true` to enable Consul Enterprise Redundancy Zones. This requires an even number of server nodes spread across three availability zones.
- **consul_nodes**: Set to `6` to ensure proper configuration for redundancy zones. This specifies the number of Consul nodes to deploy.
