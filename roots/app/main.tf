# The app root — the source of the transfer. Over time it accumulated
# resources that belong elsewhere: the DNS zone (and its id) belong in
# networking, the backup suffix belongs in database. Each carries a move
# decorator naming its destination as a directory relative to this root.
#
# The knots that make this move interesting:
#   - endpoint_name still reads the moved dns_zone: after the move that
#     reference crosses a root boundary, so demonolith rewrites it to an
#     input variable here, adds the matching output to networking, and adds
#     the snapcd_module_input_from_output to the snapcd root.
#   - backup_suffix depends_on the moved dns_zone_id: an ordering-only
#     dependency between the two receivers, which becomes a
#     snapcd_depends_on_module.
#   - backup_suffix reads local.quota_max, which reads var.quota_ceiling:
#     both declarations travel with it into database.

resource "random_pet" "release_name" {
  length = var.release_words
}

resource "random_pet" "endpoint_name" {
  prefix = random_pet.dns_zone.id
}

# @demono:move ../networking
resource "random_pet" "dns_zone" {
  length = 2
}

# @demono:move ../networking
resource "random_uuid" "dns_zone_id" {
}

# @demono:move ../database
resource "random_id" "backup_suffix" {
  byte_length = local.quota_max
  depends_on  = [random_uuid.dns_zone_id]
}

locals {
  quota_max = var.quota_ceiling
}
