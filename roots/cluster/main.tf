# The cluster root: a bystander. It is part of the landscape and wired into
# Snap CD, but the transfer never touches it — its code, its state, and its
# snapcd_module all stay exactly as they are.

resource "random_pet" "cluster_name" {
  length = 2
}
