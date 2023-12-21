variable "cluster_domain" {
  type    = string
  default = "cluster.local"
}

variable "k3s_version" {
  type    = string
  default = "v1.28.4+k3s2"
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

variable "image" {
  type    = string
  default = "images:debian/bookworm"
}

variable "nicparent" {
  type = string
}
