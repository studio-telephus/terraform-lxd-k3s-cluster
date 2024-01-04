data "tls_public_key" "swarm_public_key" {
  private_key_pem = base64decode(var.swarm_private_key)
}

locals {
  container_mount_dirs = [
    "${path.module}/filesystem-shared-ca-certificates",
    "${path.module}/filesystem",
  ]
  username       = "root"
  container_exec = "/mnt/install.sh"
  container_environment = {
    SSH_AUTHORIZED_KEYS = base64encode(data.tls_public_key.swarm_public_key.public_key_openssh)
  }
  containers_master = [for i, item in var.containers_master : {
    name         = item.name
    ipv4_address = item.ipv4_address
    profiles     = item.profiles
    mount_dirs   = local.container_mount_dirs
    environment  = local.container_environment
    exec         = local.container_exec
  }]
  containers_worker = [for i, item in var.containers_worker : {
    name         = item.name
    ipv4_address = item.ipv4_address
    profiles     = item.profiles
    mount_dirs   = local.container_mount_dirs
    environment  = local.container_environment
    exec         = local.container_exec
  }]
}

module "lxd_swarm" {
  source       = "github.com/studio-telephus/terraform-lxd-swarm.git?ref=1.0.1"
  image        = var.image
  nicparent    = var.nicparent
  containers   = concat(local.containers_master, local.containers_worker)
  autostart    = var.autostart
  exec_enabled = var.exec_enabled
}

resource "time_sleep" "wait_for_lxd_swarm" {
  depends_on = [
    module.lxd_swarm
  ]
  create_duration = "5s"
}

module "k3s" {
  source               = "xunleii/k3s/module"
  k3s_version          = var.k3s_version
  cluster_domain       = var.cluster_domain
  k3s_install_env_vars = var.k3s_install_env_vars
  global_flags         = var.global_flags
  drain_timeout        = var.drain_timeout
  managed_fields       = var.managed_fields
  use_sudo             = var.use_sudo
  cidr = {
    pods     = var.cidr_pods
    services = var.cidr_services
  }
  servers = {
    for i, item in var.containers_master : "master-${i}" => {
      ip = item.ipv4_address
      connection = {
        user        = local.username
        host        = item.ipv4_address
        private_key = trimspace(base64decode(var.swarm_private_key))
        timeout     = var.node_connection_timeout
      }
      flags  = var.master_flags
      labels = { "node.kubernetes.io/type" = "master" }
      annotations = {
        "server.index" : i
      }
    }
  }
  agents = {
    for i, item in var.containers_worker : "agent-${i}" => {
      ip = item.ipv4_address
      connection = {
        user        = local.username
        host        = item.ipv4_address
        private_key = trimspace(base64decode(var.swarm_private_key))
        timeout     = var.node_connection_timeout
      }
      labels = { "node.kubernetes.io/pool" = "worker-pool" }
      annotations = {
        "worker.index" : i
      }
    }
  }
  depends_on_ = time_sleep.wait_for_lxd_swarm
  depends_on  = [time_sleep.wait_for_lxd_swarm]
}
