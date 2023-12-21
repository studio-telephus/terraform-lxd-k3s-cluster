locals {
  container_mount_dirs = [
    "${path.module}/filesystem-shared-ca-certificates",
    "${path.module}/filesystem",
  ]
  username              = "root"
  container_exec        = "/mnt/install.sh"
  container_environment = {}
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

data "tls_public_key" "swarm_public_key" {
  private_key_pem = base64decode(var.swarm_private_key)
}

resource "local_sensitive_file" "swarm_public_key_openssh_to_authorized_keys" {
  filename = pathexpand("./filesystem/root/.ssh/authorized_keys")
  content  = data.tls_public_key.swarm_public_key.public_key_openssh
}

module "lxd_swarm" {
  source       = "github.com/studio-telephus/terraform-lxd-swarm.git?ref=1.0.1"
  image        = var.image
  nicparent    = var.nicparent
  containers   = concat(local.containers_master, local.containers_worker)
  autostart    = var.autostart
  exec_enabled = true
  depends_on = [
    local_sensitive_file.swarm_public_key_openssh_to_authorized_keys
  ]
}

module "k3s" {
  source         = "xunleii/k3s/module"
  k3s_version    = var.k3s_version
  cluster_domain = var.cluster_domain
  k3s_install_env_vars = {
    "K3S_KUBECONFIG_MODE" = "644"
  }
  drain_timeout  = var.drain_timeout
  managed_fields = ["label", "taint"]
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
      }
      labels = { "node.kubernetes.io/type" = "master" }
      taints = { "node.k3s.io/type" = "server:NoSchedule" }
    }
  }
  agents = {
    for i, item in var.containers_worker : "agent-${i}" => {
      ip = item.ipv4_address
      connection = {
        user        = local.username
        host        = item.ipv4_address
        private_key = trimspace(base64decode(var.swarm_private_key))
      }
      labels = { "node.kubernetes.io/pool" = "service-pool" }
    }
  }
  depends_on_ = module.lxd_swarm
  depends_on  = [module.lxd_swarm]
}