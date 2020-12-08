terraform {
  backend gcs {
    bucket = "devel-tfstate"
    prefix = "terraform/state/gcp"
  }
}

locals {
  region = "europe-west2"
  zone   = "europe-west2-c"
}

provider google {
  version = "3.5.0"
  project = "devel-final"
  region  = local.region
  zone    = local.zone
}

resource google_compute_network vpc {
  name = "final-vpc"
}

resource google_compute_network vpc_network {
  name = "network"
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

variable jenkins_password {}

resource google_compute_address static {
  name         = "public"
  address_type = "EXTERNAL"
}

data google_compute_image jenkins {
  name    = "bitnami-jenkins-2-235-4-0-linux-debian-10-x86-64-nami"
  project = "bitnami-launchpad"
}

resource google_compute_disk jenkins-home {
  name  = "jenkins-home"
  image = data.google_compute_image.jenkins.self_link
  size  = 10
  type  = "pd-ssd"
  zone  = local.zone
  labels = {
    name = "jenkins-home"
  }
}

// A single Compute Engine instance
resource google_compute_instance compute {
  name         = "jenkins"
  machine_type = "n1-standard-1"
  zone         = local.zone
  allow_stopping_for_update = true
  can_ip_forward = true
  depends_on = [
    google_compute_disk.jenkins-home
  ]

  boot_disk {
    auto_delete = false
    source = google_compute_disk.jenkins-home.self_link
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.main-subnet.self_link
    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = google_compute_address.static.address
    }
  }
  metadata = {
    startup-script = file("init.sh")
    ssh-keys = "root:${file("key.pub")}"
    bitnami-base-password  = var.jenkins_password
  }

  scheduling {
    automatic_restart = true
  }
}

resource google_compute_firewall compute {
  name    = "compute-jenkins"
  network = google_compute_network.vpc_network.id
  
  allow {
    protocol = "tcp"
    ports    = ["80","443", "22"]
  }
  
  allow {
    protocol = "icmp"
  }
}

output public-ip {
  value = google_compute_instance.compute.network_interface.0.access_config.0.nat_ip
}

output vpc {
  value = google_compute_network.vpc.self_link
}

output network {
  value = google_compute_network.vpc_network.self_link
}

output subnet {
  value = google_compute_subnetwork.main-subnet.self_link
}

