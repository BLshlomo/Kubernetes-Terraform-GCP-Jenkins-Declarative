terraform {
  backend gcs {
    bucket = "devel-tfstate"
    prefix = "terraform/state/gke"
  }
}

locals {
  region  = "europe-west2"
  zone    = "europe-west2-c"
  project = "devel-final"
}

data terraform_remote_state gcp {
  backend = "gcs"
  config = {
    bucket = "devel-tfstate"
    prefix = "terraform/state/gcp"
  }
}

provider google {
  version = "~> 3.35"
  project = local.project
  region  = local.region
  zone    = local.zone
}

resource google_container_cluster primary {
  name     = "develeap"
  location = local.zone

  network    = "default"
  subnetwork = "default"

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource google_container_node_pool primary_preemptible_nodes {
  name     = "my-node-pool"
  location = local.zone
  cluster  = google_container_cluster.primary.name
  #cluster_autoscaling = false
  node_count = 3

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    disk_size_gb = 10

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform", # from here si only for the dns challenge
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  autoscaling {
    min_node_count = 3
    max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = false
  }
}

output cluster {
  value = google_container_cluster.primary.name
}