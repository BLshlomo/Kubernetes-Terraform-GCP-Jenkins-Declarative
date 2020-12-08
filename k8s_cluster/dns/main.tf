terraform {
  backend gcs {
    bucket = "devel-tfstate"
    prefix = "terraform/state/dns"
  }
}

variable public-ip {}

locals {
  region  = "europe-west2"
  zone    = "europe-west2-c"
  project = "devel-final"
  ip = var.public-ip
  domain = "devops2020.ddnsgeek.com."
}

provider google {
  version = "~> 3.35"
  project = local.project
  region  = local.region
  zone    = local.zone
}

resource google_service_account dns01-solver {
  account_id   = "dns01-solver"
  display_name = "dns01-solver"
}

resource google_project_iam_binding clouddns-admin {
  role = "roles/dns.admin"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
  ]
}

resource google_service_account_key clouddns-key {
  service_account_id = google_service_account.dns01-solver.name
}

resource kubernetes_secret clouddns-secret {
  metadata {
    name = "clouddns-dns01-solver-svc-acct"
  }
  data = {
    "key.json" = base64decode(google_service_account_key.clouddns-key.private_key)
  }
}

# from here as welll, should try with the elimnation system, the next roles are not nesseceray
resource google_project_iam_binding iam {
  role = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
  ]
}

resource google_project_iam_binding cluster-admin {
  role = "roles/container.clusterAdmin"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
  ]
}

resource google_project_iam_binding container-dev {
  role = "roles/container.developer"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
  ]
}

resource google_project_iam_binding container-service-agent {
  role = "roles/container.serviceAgent"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
  ]
}

resource google_project_iam_binding compute-viewer {
  role = "roles/compute.viewer"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
  ]
}

# from here its extra dangerous and should be deleted after testing !

resource google_project_iam_binding owner {
  role = "roles/owner"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
    #"user:bl.shlomi@gmail.com"
  ]
}

resource google_project_iam_binding storage {
  role = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
  ]
}

resource google_project_iam_binding viewer {
  role = "roles/viewer"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
  ]
}

resource google_project_iam_binding editor {
  role = "roles/editor"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}"
  ]
}

resource google_project_iam_binding billing {
  role = "roles/billing.admin"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}",
    "user:bl.shlomi@gmail.com"
  ]
}

resource google_project_iam_binding billing-user {
  role = "roles/billing.user"
  members = [
    "serviceAccount:${google_service_account.dns01-solver.email}",
    "user:bl.shlomi@gmail.com"
  ]
}

resource google_dns_managed_zone dns {
  name     = "dns"
  dns_name = local.domain
}

resource google_dns_record_set host {
  name         = google_dns_managed_zone.dns.dns_name
  managed_zone = google_dns_managed_zone.dns.name
  type         = "A"
  ttl          = 300

  rrdatas = [local.ip]
}

resource google_dns_record_set def {
  name         = "def.${google_dns_managed_zone.dns.dns_name}"
  managed_zone = google_dns_managed_zone.dns.name
  type         = "A"
  ttl          = 300

  rrdatas = [local.ip]
}

resource google_dns_record_set dev {
  name         = "dev.${google_dns_managed_zone.dns.dns_name}"
  managed_zone = google_dns_managed_zone.dns.name
  type         = "A"
  ttl          = 300

  rrdatas = [local.ip]
}

resource google_dns_record_set staging {
  name         = "staging.${google_dns_managed_zone.dns.dns_name}"
  managed_zone = google_dns_managed_zone.dns.name
  type         = "A"
  ttl          = 300

  rrdatas = [local.ip]
}

output clouddns-key {
  value = google_service_account_key.clouddns-key.private_key
  sensitive   = true
}
output email {
  value = google_service_account.dns01-solver.email
}
output dns {
  value = google_dns_managed_zone.dns.name
}
output host {
  value = google_dns_managed_zone.dns.dns_name
}
