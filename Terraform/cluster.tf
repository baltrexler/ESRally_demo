resource "google_container_cluster" "primary" {
  name     = "elastic-testbed"
  location = "us-east4"

  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "searchnodes" {
  name       = "searchnodes"
  location   = "us-east4"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "e2-highmem-8"
    disk_size_gb = 50

    taint {
      key    = "apptype"
      value  = "search"
      effect = "NO_SCHEDULE"
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = var.service_account_id
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_container_node_pool" "generic" {
  name           = "generic"
  location       = "us-east4"
  node_locations = ["us-east4-a"]
  cluster        = google_container_cluster.primary.name
  node_count     = 1

  node_config {
    preemptible  = false
    machine_type = "e2-standard-2"
    disk_size_gb = "50"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = var.service_account_id
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  autoscaling {
    min_node_count = 1
    max_node_count = 2
  }
}

resource "google_container_node_pool" "rally" {
  name           = "rally"
  location       = "us-east4"
  node_locations = ["us-east4-a"]
  cluster        = google_container_cluster.primary.name
  node_count     = 1

  node_config {
    preemptible  = false
    machine_type = "e2-standard-4"
    disk_size_gb = "20"

    taint {
      key    = "apptype"
      value  = "rally"
      effect = "NO_SCHEDULE"
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = var.service_account_id
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }
}