# Required

variable "secrets" {
  type        = map(string)
  description = "Dict of all secrets used by the module. Provider info, users, passwords, etc."
}

variable "name" {
  type        = string
  description = "Name of the bucket"
}

# Optional

variable "versioning" {
  type        = string
  description = "Set Enabled to enable bucket versioning."
  default     = "Suspended"
}

