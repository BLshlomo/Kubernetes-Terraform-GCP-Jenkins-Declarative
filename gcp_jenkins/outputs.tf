output vpc {
  value = google_compute_network.vpc.self_link
}

output network {
  value = google_compute_network.vpc_network.self_link
}

output subnet {
  value = google_compute_subnetwork.main-subnet.self_link
}

output public-ip {
  value = local.pubip
}

output ssh-command {
  value = "ssh -o StrictHostKeyChecking=no -i ${abspath(path.root)}/key root@${local.pubip}"
}

output jenkins-dns {
  value = var.dns_addr
}

output registry {
  value = google_container_registry.registry
}

data google_container_registry_image chatapp {
  name = "chatapp"
}

output gcr_location {
  value = data.google_container_registry_image.chatapp #.image_url
}

output instance {
  value = google_compute_instance.compute.service_account
}
