variable "project_id" {
  description = "My GCP Project ID"
  type        = string
  default     = "gcp-class-417400"
}

variable "shared_secret" {
  description = "Shared secret for VPN tunnels"
  type        = string
  sensitive   = true
  default     = "MySecureSecret123!"
}

# ─── Network 1 ────────────────────────────────────────────────────────────────

variable "network1_name" {
  description = "Name of the first VPC network"
  type        = string
  default     = "vpc-network-1"
}

variable "subnet1_name" {
  description = "Name of the first subnet"
  type        = string
  default     = "subnet-1"
}

variable "subnet1_cidr" {
  description = "CIDR range for subnet 1"
  type        = string
  default     = "10.1.0.0/24"
}

variable "region1" {
  description = "Region for network 1 resources"
  type        = string
  default     = "us-central1"
}

# ─── Network 2 ────────────────────────────────────────────────────────────────

variable "network2_name" {
  description = "Name of the second VPC network"
  type        = string
  default     = "vpc-network-2"
}

variable "subnet2_name" {
  description = "Name of the second subnet"
  type        = string
  default     = "subnet-2"
}

variable "subnet2_cidr" {
  description = "CIDR range for subnet 2"
  type        = string
  default     = "10.2.0.0/24"
}

variable "region2" {
  description = "Region for network 2 resources"
  type        = string
  default     = "us-east1"
}
