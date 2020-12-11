variable "airflow_deployment_name" {
    type = string
    description = "Name of airflow deployment."
}

variable "prometheus_deployment_name" {
    type = string
    description = "Name of prometheus deployment."
}

variable "keda_deployment_name" {
    type = string
    description = "Name of keda deployment."
}