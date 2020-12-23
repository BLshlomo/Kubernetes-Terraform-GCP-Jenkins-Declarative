data template_file kubeconfig {
  template = file("${path.module}/kubeconfig_template.yaml")

  vars = {
    cluster_name    = google_container_cluster.primary.name
    endpoint        = google_container_cluster.primary.endpoint
    user_name       = google_container_cluster.primary.master_auth.0.username
    user_password   = google_container_cluster.primary.master_auth.0.password
    cluster_ca      = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
    client_cert     = google_container_cluster.primary.master_auth.0.client_certificate
    client_cert_key = google_container_cluster.primary.master_auth.0.client_key
    access_token    = data.google_client_config.provider.access_token
  }
}

resource local_file kubeconfig {
  content = data.template_file.kubeconfig.rendered
  #filename = try(var.kubeconfig, "${path.module}/kubeconfig")
  filename = "${path.module}/kubeconfig"
}

output auth {
  value = google_container_cluster.primary.master_auth
}

output cluster {
  value     = google_container_cluster.primary
  sensitive = true
}

data google_client_config provider {}

output client_config {
  value = data.google_client_config.provider
}

output cluster-name {
  value = google_container_cluster.primary.name
}

output kubeconfig {
  value = local_file.kubeconfig.filename
}

output kube-test {
  value = try(var.kubeconfig, "${path.module}/kubeconfig")
}
