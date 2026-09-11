# The database root, a living receiver: it already has its own resources and
# its own state. The second transfer appends the backup suffix that grew
# up in the app root, together with the variable and local it reads.

resource "random_pet" "db_name" {
  length = 2
}

resource "random_password" "admin" {
  length  = 16
  special = false
}
