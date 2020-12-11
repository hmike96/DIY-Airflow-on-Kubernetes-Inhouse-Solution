# Provider defines the API to use to interact with a service such as helm and cloud providers.
provider "helm" {
  kubernetes {}
}

provider "azurerm" {
  features {}
}


#### Secrets ####
data "azurerm_key_vault_secret" "airflow_username" {
  name         = "username"
  key_vault_id = "/subscriptions/0bcf6055-aa26-4fac-80b1-c86d5faa6c7e/resourceGroups/Airflow-Talk-Resources/providers/Microsoft.KeyVault/vaults/airflow-talk-vault"
}

data "azurerm_key_vault_secret" "airflow_password" {
  name         = "password"
  key_vault_id = "/subscriptions/0bcf6055-aa26-4fac-80b1-c86d5faa6c7e/resourceGroups/Airflow-Talk-Resources/providers/Microsoft.KeyVault/vaults/airflow-talk-vault"
}

#### Helm Airflow ####
resource "helm_release" "airflow" {
  name  = var.airflow_deployment_name
  chart = "../Airflow/chart"
  namespace = "airflow"
  values = [
    "${file("values_files/airflow-values.yaml")}"
  ]

  depends_on = [helm_release.keda,kubernetes_role.airflow_secrets,kubernetes_role_binding.airflow_secrets]
  set {
    name = "azureFilesShareName"
    value = "airflow-dags"
  }

  set {
    name = "webserver.defaultUser.username"
    value = data.azurerm_key_vault_secret.airflow_username.value
  }

  set {
    name = "webserver.defaultUser.password"
    value = data.azurerm_key_vault_secret.airflow_password.value
  }
}

#### Airflow RBAC ####
resource "kubernetes_role" "airflow_secrets" {
  metadata {
    name = "airflow-secrets"
    labels = {
      test = "MyRole"
    }
    namespace = "airflow"
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    verbs          = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "airflow_secrets" {
  metadata {
    name      = "airflow-secrets-binding"
    namespace = "airflow"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "airflow-secrets"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "airflow-scheduler"
    namespace = "airflow"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "airflow-webserver"
    namespace = "airflow"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "airflow-worker"
    namespace = "airflow"
  }
}

#### Helm Prometheus ####

resource "helm_release" "prometheus" {
  name = var.prometheus_deployment_name
  chart = "prometheus-community/kube-prometheus-stack"
  namespace = "airflow"
  values = [
    "${file("values_files/prometheus-values.yaml")}"
  ]
}

#### Helm Keda ####

resource "helm_release" "keda" {
  name = var.keda_deployment_name
  chart = "kedacore/keda"
  namespace = "keda"
  
  set {
    name = "image.keda.repository"
    value = "docker.io/kedacore/keda"
  }
  set {
    name = "image.metricsApiServer.repository"
    value = "docker.io/kedacore/keda-metrics-apiserver"
  } 

}


