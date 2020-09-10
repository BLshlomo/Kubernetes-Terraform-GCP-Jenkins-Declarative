locals {
  region = "europe-west2"
  zone   = "europe-west2-c"
}

provider google {
  version = "3.5.0"

  #credentials = file("<NAME>.json")

  project = "devel-final"
  region = local.region
  zone   = local.zone
}

data google_billing_account account {
  display_name = "My Billing Account"
}

resource google_project project {
  name       = "final"
  project_id = "devel-final"
  billing_account = data.google_billing_account.account.id
}

resource google_storage_bucket terraform_state {
  name     = "devel-tfstate"
  location = local.region
  project = "devel-final"
  versioning {
    enabled = true
  }
}

resource google_project_service cloud {
  service                    = "cloudapis.googleapis.com"
  disable_dependent_services = true
}

resource google_project_service compute {
  #service    = "[compute.googleapis.com](http://compute.googleapis.com/)"
  service                    = "compute.googleapis.com"
  disable_dependent_services = true
}

resource google_project_service kubernetes {
  service                    = "container.googleapis.com"
  disable_dependent_services = true
}

resource google_project_service dns {
  service                    = "dns.googleapis.com"
  disable_dependent_services = true
}

resource google_project_service billing {
  service                    = "cloudbilling.googleapis.com"
  disable_dependent_services = true
}

resource google_project_service resource-manager {
  service                    = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

resource google_project_service iam {
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
}

resource google_project_service service-usage {
  service                    = "serviceusage.googleapis.com"
  disable_dependent_services = true
}




