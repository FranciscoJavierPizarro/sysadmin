# Linode Provider definition
terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.0.0"
    }
  }
}

provider "linode" {
  token = var.token
}

# Create the K3s server instance
resource "linode_instance" "k3s_server" {
  label       = "k3s-server"
  image       = "linode/ubuntu20.04"
  region      = "us-east"
  type        = "g6-standard-1"
  root_pass   = var.root_pass
  authorized_keys = [var.authorized_keys]
}

# Create the K3s agent instances
resource "linode_instance" "k3s_agent_1" {
  label       = "k3s-agent-1"
  image       = "linode/ubuntu20.04"
  region      = "us-east"
  type        = "g6-standard-1"
  root_pass   = var.root_pass
  authorized_keys = [var.authorized_keys]
}

resource "linode_instance" "k3s_agent_2" {
  label       = "k3s-agent-2"
  image       = "linode/ubuntu20.04"
  region      = "us-east"
  type        = "g6-standard-1"
  root_pass   = var.root_pass
  authorized_keys = [var.authorized_keys]
}

# Create the K3s cluster using k3sup
resource "null_resource" "k3s_cluster" {
  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | sh -",
      "sudo k3sup install --ip ${linode_instance.k3s_server.ip_address} --user root --ssh-key ${file("~/.ssh/id_linode_rsa")} --k3s-extra-args '--disable traefik'",
      "sudo k3sup join --ip ${linode_instance.k3s_agent_1.ip_address} --server-ip ${linode_instance.k3s_server.ip_address} --user root --ssh-key ${file("~/.ssh/id_linode_rsa")}",
      "sudo k3sup join --ip ${linode_instance.k3s_agent_2.ip_address} --server-ip ${linode_instance.k3s_server.ip_address} --user root --ssh-key ${file("~/.ssh/id_linode_rsa")}",
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_linode_rsa")
      host        = "${linode_instance.k3s_server.ip_address}"
    }
  }
}