locals {
  ################################################
  ### YOU HAVE TO CHANGE ME

  parameters = {
    LETSENCRYPT_DOMAIN = "your.domain.biz"
    LETSENCRYPT_EMAIL  = "your_email@web.de"

    ################################################
    ################################################


    # do not forget to change usernames below if auth is enabled
    ENABLE_AUTH   = 1
    ENABLE_GUESTS = 0

    ######
    # Advanced configuration options (you generally don't need to change these)
    ######
    AUTH_TYPE               = "internal"
    CONFIG                  = "/jitsi-meet-cfg"
    LETSENCRYPT_USE_STAGING = "1"
    HTTPS_PORT              = "443"
    HTTP_PORT               = "80"
    ENABLE_HTTP_REDIRECT    = "1"
    ENABLE_HSTS             = 1
    ENABLE_LETSENCRYPT      = "1"
    ######
  }

  jitsi_release = "stable-5142"
  users = [
    "peter",
    "maria"
  ]
}

variable "HETZNER_TOKEN" {
  type = string
}

resource "random_password" "password" {
  count       = length(local.users)
  length      = 12
  min_lower   = 2
  min_upper   = 2
  min_numeric = 2
  special     = false
}

terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.13"
}

provider "hcloud" {
  token = var.HETZNER_TOKEN
}

resource "tls_private_key" "private-key" {
  algorithm = "RSA"
}

resource "hcloud_ssh_key" "default" {
  name       = "key"
  public_key = tls_private_key.private-key.public_key_openssh
}

resource "hcloud_server" "server" {
  name        = "server-test"
  server_type = "cpx21"
  image       = "ubuntu-20.04"
  location    = "fsn1"

  user_data = data.template_file.init.rendered
  ssh_keys = [
    hcloud_ssh_key.default.id
  ]
}

data "template_file" "init" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    env_vars      = join("\n", [for key, value in local.parameters : " - export ${key}=${value}"])
    release       = local.jitsi_release
    domain        = local.parameters.LETSENCRYPT_DOMAIN
    config_folder = local.parameters.CONFIG
    create_users  = local.parameters.ENABLE_AUTH == 1 ? join("\n", [for key, value in local.users : " - docker-compose exec -T prosody prosodyctl --config /config/prosody.cfg.lua register ${value} meet.jitsi ${random_password.password[key].result}"]) : ""
  }
}

output "private_ssh_key" {
  value     = tls_private_key.private-key.private_key_pem
  sensitive = true
}

output "ipv4_address" {
  value = hcloud_server.server.ipv4_address
}

output "users" {
  value = local.parameters.ENABLE_AUTH == 1 ? join("\n", [for key, value in local.users : "Username: ${value} Password: ${random_password.password[key].result}"]) : ""
}

