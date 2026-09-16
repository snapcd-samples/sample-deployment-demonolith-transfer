# The app root - the source of the transfers. Over time it accumulated
# resources that belong elsewhere: the DNS zone (and its id) belong in
# networking, the backup suffix belongs in database. A transfer moves blocks
# into one receiver, so this is two transfers, run one after the other.
#
# The first transfer (step 3) moves the two DNS blocks, each marked with a
# bare transfer comment; the receiver is named once, on the command line.
# The knots that make it interesting:
#   - endpoint_name still reads the moved dns_zone: after the move that
#     reference crosses a root boundary, so demonolith rewrites it to an
#     input variable here, adds the matching output to networking, and adds
#     the snapcd_module_input_from_output to the snapcd root.
#   - backup_suffix depends_on the moved dns_zone_id: the entry is dropped
#     from the block and becomes a snapcd_depends_on_module instead.
#
# The second transfer (step 5) marks backup_suffix the same way and moves it
# to database, together with the variable and local it reads.

resource "random_pet" "release_name" {
  length = var.release_words
}

resource "random_pet" "endpoint_name" {
  prefix = random_pet.dns_zone.id
}

# @demono:transfer
resource "random_pet" "dns_zone" {
  length = 2
}

# @demono:transfer
resource "random_uuid" "dns_zone_id" {
}

resource "random_id" "backup_suffix" {
  byte_length = local.quota_max
  depends_on  = [random_uuid.dns_zone_id]
}

locals {
  quota_max = var.quota_ceiling
}
