variable "client_id" {
  description = "Client ID for Snap CD authentication"
  type        = string
  default     = "default"
}

variable "client_secret" {
  description = "Client Secret for Snap CD authentication"
  type        = string
  sensitive   = true
  default     = "default"
}

variable "organization_id" {
  description = "Snap CD Organization ID"
  type        = string
  default     = "10000000-0000-0000-0000-000000000000"
}

variable "snapcd_server_url" {
  description = "Snap CD Server URL, reachable both from where this root is applied and from inside the Runner"
  type        = string
  default     = "http://localhost:5000"
}

variable "stack_name" {
  description = "Name of the Stack to deploy into"
  type        = string
  default     = "default"
}

variable "runner_name" {
  description = "Name of the registered Runner that executes the modules"
  type        = string
  default     = "default"
}

variable "namespace_name" {
  description = "Name of the Namespace the roots deploy into"
  type        = string
  default     = "demonolith-transfer"
}

variable "source_url" {
  description = "Git URL of the repository holding the roots"
  type        = string
  default     = "https://github.com/snapcd-samples/sample-deployment-demonolith-transfer.git"
}

variable "source_revision" {
  description = "Git revision (branch or tag) of the roots"
  type        = string
  default     = "main"
}
