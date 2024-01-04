variable "cluster_domain" {
  type    = string
  default = "cluster.local"
}

variable "k3s_version" {
  type    = string
  default = "v1.28.5+k3s1"
}

variable "swarm_private_key" {
  type        = string
  description = "Base64 encoded private key PEM."
  sensitive   = true
}

variable "cidr_pods" {
  type = string
}

variable "cidr_services" {
  type = string
}

variable "k3s_install_env_vars" {
  type = map(any)
  default = {}
}

variable "global_flags" {
  type = list(string)
  default = []
}

variable "drain_timeout" {
  type    = string
  default = "60s"
}

variable "containers_master" {
  type = list(object({
    name         = string
    ipv4_address = string
    profiles     = list(string)
  }))
}

variable "containers_worker" {
  type = list(object({
    name         = string
    ipv4_address = string
    profiles     = list(string)
  }))
}

variable "autostart" {
  type = bool
}

variable "exec_enabled" {
  type    = bool
  default = true
}

variable "image" {
  type    = string
  default = "images:debian/bookworm"
}

variable "nicparent" {
  type = string
}
