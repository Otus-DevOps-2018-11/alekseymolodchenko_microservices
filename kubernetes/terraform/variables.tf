variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west4"
}

variable zone {
  description = "Zone"
  default     = "europe-west4-b"
}

variable env {
  description = "Environment: production, development, staging"
  default     = "production"
}

variable source_ranges {
  description = "Allowed IP addresses"
  default     = ["0.0.0.0/0"]
}

variable "k8s_cluster_name" {
  description = "Cluster name"
}

variable "k8s_node_pool_name" {
  description = "Node pool name"
}

variable "k8s_node_machine_type" {
  description = "Node machine type"
  default     = "n1-standard-2"
}

variable "k8s_initial_node_count" {
  description = "Cluster initian node count"
  default     = 1
}

variable "k8s_node_pool_cont" {
  description = "Cluster node pool count"
  default     = 2
}

variable "k8s_node_disk_size" {
  description = "Node Disk size in Gb"
  default     = "10"
}

variable "k8s_node_disk_type" {
  description = "Node disk type"
  default     = "pd-standard"
}

variable "k8s_node_image_type" {
  description = "Node Image Type"
  default     = "COS"
}
