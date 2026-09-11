# The networking root, as the split created it: the network's own naming and
# addressing, in its own state. The first transfer adds the DNS zone that
# grew up in the app root - it lands in this file, appended by demonolith.

resource "random_pet" "vpc_name" {
  length = 2
}

resource "random_uuid" "private_subnet_id" {
}
