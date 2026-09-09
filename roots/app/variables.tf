variable "release_words" {
  description = "Words in the generated release name"
  type        = number
  default     = 2
}

variable "quota_ceiling" {
  description = "Upper bound the backup suffix is sized from; read only by the moved block, so its declaration travels with it"
  type        = number
  default     = 4
}
