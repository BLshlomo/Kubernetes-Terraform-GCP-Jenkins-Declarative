terraform {
  backend gcs {
    bucket = "devel-tfstate"
    prefix = "terraform/state/gcp"
  }
}

locals {
  region = "us-east1"
  zone   = "us-east1-c"
  pubip  = google_compute_instance.compute.network_interface.0.access_config.0.nat_ip
}

provider null {
  version = "~> 3.0"
}

provider google {
  version = "~> 3.35"
  project = "devel-final"
  region  = local.region
  zone    = local.zone
}

resource google_container_registry registry {
  #  project  = "my-project"
  #  location = "EU"
}

resource google_service_account jenkins_push {
  account_id   = "jenkins-push"
  display_name = "Jenkins Push GCR"
}

resource google_storage_bucket_iam_member jenkins_push_role {
  bucket = google_container_registry.registry.id
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_compute_instance.compute.service_account[0].email}"
  #member = "serviceAccount:${google_service_account.jenkins_push.email}"
}

resource google_compute_network vpc {
  name = "final-vpc"
}

resource google_compute_network vpc_network {
  name                    = "network"
  auto_create_subnetworks = false
}

resource google_compute_subnetwork main-subnet {
  name          = "main-subnet"
  ip_cidr_range = "10.0.0.0/8"
  region        = local.region
  network       = google_compute_network.vpc_network.id
  secondary_ip_range {
    range_name    = "secondary-range"
    ip_cidr_range = "192.168.0.0/16"
  }
}

variable dns_addr {
  default = "jenkins.ddnsgeek.com"
}

# Password must be at least 8 characters, letters and numbers are must.
variable jenkins_password {}

#resource google_compute_address static {
#  name         = "public"
#  address_type = "EXTERNAL"
#}

data google_compute_image jenkins {
  name    = "bitnami-jenkins-2-235-4-0-linux-debian-10-x86-64-nami"
  project = "bitnami-launchpad"
}

resource google_compute_disk jenkins-home {
  name  = "jenkins-home"
  image = data.google_compute_image.jenkins.self_link
  size  = 10
  #type  = "pd-ssd"
  zone = local.zone
  labels = {
    name = "jenkins-home"
  }
}

// A single Compute Engine instance
resource google_compute_instance compute {
  name                      = "jenkins"
  machine_type              = "n1-standard-1"
  zone                      = local.zone
  allow_stopping_for_update = true
  can_ip_forward            = true
  depends_on = [
    google_compute_disk.jenkins-home
  ]

  boot_disk {
    auto_delete = false
    source      = google_compute_disk.jenkins-home.self_link
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.main-subnet.self_link
    access_config {
      // Include this section to give the VM an external ip address
      #nat_ip = google_compute_address.static.address
    }
  }

  metadata = {
    startup-script        = file("init.sh")
    ssh-keys              = "root:${file("key.pub")}"
    bitnami-base-password = var.jenkins_password
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  service_account {
    scopes = [ #"userinfo-email", "compute-ro", "storage-ro"]
      #google_service_account.jenkins_push.email,
      "storage-rw"
    ]
  }
}

resource google_compute_firewall compute {
  name    = "compute-jenkins"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "22"]
  }

  allow {
    protocol = "icmp"
  }
}

resource null_resource set-dns {
  depends_on = [
    google_compute_instance.compute
  ]
  provisioner local-exec {
    command = "curl -X GET 'https://api.dynu.com/nic/update?hostname=${var.dns_addr}&myip=${local.pubip}' -H \"Authorization: Basic ${var.dynu_ip_auth}\""
  }
}

variable dynu_ip_auth {
  description = "dynu api change ip"
}
