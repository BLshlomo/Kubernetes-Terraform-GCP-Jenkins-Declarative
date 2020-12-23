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
  value = "ssh -i ${abspath(path.root)}/key.pub root@${local.pubip}"
}

output jenkins-dns {
  value = var.dns_addr
}
