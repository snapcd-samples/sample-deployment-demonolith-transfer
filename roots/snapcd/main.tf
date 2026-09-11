# Wires the four roots into Snap CD: one snapcd_module per root, the shape
# demonolith's bootstrap generates for a split. Applying this root needs a
# running Snap CD server and is the closing act of the sample - but the
# transfer updates it either way: the moved dependency becomes a
# snapcd_module_input_from_output (and the ordering dependency a
# snapcd_depends_on_module), appended below by step 3.

data "snapcd_stack" "this" {
  name = var.stack_name
}

data "snapcd_runner" "this" {
  name = var.runner_name
}

resource "snapcd_namespace" "this" {
  name                                = var.namespace_name
  stack_id                            = data.snapcd_stack.this.id
  default_engine                      = "OpenTofu"
  default_trigger_path_filter_enabled = true
}

resource "snapcd_module" "networking" {
  name                = "networking"
  namespace_id        = snapcd_namespace.this.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "roots/networking"
  runner_id           = data.snapcd_runner.this.id
  engine              = "OpenTofu"
}

resource "snapcd_module" "cluster" {
  name                = "cluster"
  namespace_id        = snapcd_namespace.this.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "roots/cluster"
  runner_id           = data.snapcd_runner.this.id
  engine              = "OpenTofu"
}

resource "snapcd_module" "database" {
  name                = "database"
  namespace_id        = snapcd_namespace.this.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "roots/database"
  runner_id           = data.snapcd_runner.this.id
  engine              = "OpenTofu"
}

resource "snapcd_module" "app" {
  name                = "app"
  namespace_id        = snapcd_namespace.this.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "roots/app"
  runner_id           = data.snapcd_runner.this.id
  engine              = "OpenTofu"
}
