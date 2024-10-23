
# Deployment customization

## TLS

Certificates are provided at startup via cloud-init. Follow the example to structure your certificates correctly.

## Adding a Consul license

To see an example of how to automate the addition of your Consul license to SSM, place the license file in the example directory. The Terraform module will handle the rest.

## Customizing options with tf.autovars.tfvars

Use the `terraform.tfvars.example` file to customize various options for your Consul deployment. Copy the file to a `*.tfvars` file. By then modifying this file, you can set specific values for the variables used in the module, such as the number of nodes, redundancy settings, and other configurations.  Then with your desired settings and run your Terraform workflow to apply them.

## Redundancy zones

To enable Consul Enterprise Redundancy Zones, set the `server_redundancy_zones` variable to `true`. This feature requires an even number of server nodes spread across 3 or more availability zones. Additionally, set the `consul_nodes` variable to `6` to meet this requirement.

### Configuration options

- **server_redundancy_zones**: Set to `true` to enable Consul Enterprise Redundancy Zones. This requires an even number of server nodes spread across three availability zones.
- **consul_nodes**: Set to `6` to ensure proper configuration for redundancy zones. This specifies the number of Consul nodes to deploy.


### Template customization

The `install_consul_config.sh.tpl` file is exposed as a variable

```hcl
variable "consul_config_template" {
  type        = string
  default     = null
  nullable    = true
  description = "(Optional string) name of `*.tpl` file in the `./templates` folder local to the module declaration, to replace the root `install_consul_config.sh.tpl` "
  validation {
    condition     = var.consul_config_template == null || can(fileexists("./templates/${var.consul_config_template}"))
    error_message = "File not found or not readable"
  }
}
```

you can copy the existing template form the module to your root module `./templates/install_consul_config.sh.tpl` folder and provide the files basename i.e `consul_config_template = install_consul_config.sh.tpl` and the file will replace the default server config.
