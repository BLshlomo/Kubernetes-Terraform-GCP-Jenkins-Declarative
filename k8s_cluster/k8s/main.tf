terraform {
  backend gcs {
    bucket = "devel-tfstate"
    prefix = "terraform/state/k8s"
  }
}

locals {
  region  = "europe-west2"
  zone    = "europe-west2-c"
  project = "devel-final"
}

 variable muser {}
 variable mpass {}
 variable muri {}

data terraform_remote_state gke {
  backend = "gcs"
  config = {
    bucket = "devel-tfstate"
    prefix = "terraform/state/gke"
  }
}

provider google {
  version = "~> 3.35"
  project = local.project
  region  = local.region
  zone    = local.zone
}

# Retrieve an access token as the Terraform runner
data google_client_config provider {}

data google_container_cluster my_cluster {
  name     = data.terraform_remote_state.gke.outputs.cluster
  location = local.zone
}

provider kubernetes {
  load_config_file = false
  version          = "~> 1.7"

  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}

provider "helm" {
  version = "~> 1.2"
  kubernetes {
    host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
    )
  }
}

resource kubernetes_secret mongo-echo {
  metadata {
    name = "echo-mongo"
  }

  data = {
    mongodburl = var.muri
  }
}

resource kubernetes_secret dev-mongo-echo {
  metadata {
    name = "echo-mongo"
    namespace = "dev"
  }
  
  data = {
    mongodburl = var.muri
  }
}

resource kubernetes_secret prod-mongo-echo {
  metadata {
    name = "echo-mongo"
    namespace = "production"
  }
  
  data = {
    mongodburl = var.muri
  }
}

resource kubernetes_secret stag-mongo-echo {
  metadata {
    name = "echo-mongo"
    namespace = "staging"
  }
  
  data = {
    mongodburl = var.muri
  }
}

resource kubernetes_secret mongo-secret {
  metadata {
    name = "mongodb"
  }

  data = {
    user = var.muser
    password = var.mpass
  }
}

resource kubernetes_secret clouddns-secret {
  metadata {
    name = "clouddns-dns01-solver-svc-acct"
    namespace = "cert-manager"
  }
  data = {
    "key.json" = data.terraform_remote_state.gke.outputs.clouddns-key
    #base64decode(data.terraform_remote_state.gke.outputs.clouddns-key)
  }
}

resource helm_release cert-manager {
  name  = "cert-manager"
  chart = "./charts/cert-manager"
  namespace = "cert-manager"
  create_namespace = true

  values = [
    "${file("./charts/cert-manager/values.yaml")}"
  ]
}

resource helm_release nginx {
  name  = "nginx"
  chart = "./charts/nginx-ingress"
}

resource helm_release mongo {
  name  = "mongo"
  chart = "./charts/mongodb-replicaset"

  values = [
    "${file("./charts/mongodb-replicaset/values.yaml")}"
  ]
}

resource helm_release echoapp {
  name  = "echoapp"
  chart = "./charts/conf-repo/mychart"

  values = [
    "${file("./charts/conf-repo/mychart/values.yaml")}"
  ]
}

resource helm_release prod_mongo {
  name  = "mongo"
  chart = "./charts/mongodb-replicaset"
  namespace = "production"
  create_namespace = false

  values = [
    "${file("./charts/mongodb-replicaset/values.yaml")}"
  ]
}

resource helm_release fluxcd {
  name  = "flux"
  chart = "fluxcd/flux"
  #repository = "https://charts.fluxcd.io"
  namespace = "fluxcd"
  create_namespace = true
  wait = true

  set {
    name  = "git.url"
    value = "git@github.com:BLsolomon/fluxcd-config-repo.git"
  }
}

resource helm_release fluxcd-chart {
  name  = "flux-chart"
  chart = "fluxcd/helm-operator"
  #repository = "https://charts.fluxcd.io"
  namespace = "fluxcd"
  create_namespace = true

  set {
    name  = "git.ssh.secretName"
    value = "flux-git-deploy"
  }
  
  set {
    name  = "helm.versions"
    value = "v3"
  }
}
/*
resource helm_release cluster-secret {
  name  = "cls-secret"
  chart = "./charts/cluster-secret"
}
*/
resource helm_release logger {
  name  = "logger"
  chart = "/home/Admin/docker/ke/22_efk_echo/kube-logging/"
}
