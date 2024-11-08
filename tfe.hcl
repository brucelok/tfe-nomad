variable "tfe_image" {
  description = "The TFE image to use"
  type        = string
  default     = "images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202410-1"
}

variable "tfe_image_username" {
  description = "Username for the registry to download TFE image"
  type        = string
}

variable "tfe_image_password" {
  description = "Password for the registry to download TFE image"
  type        = string
}

variable "namespace" {
  description = "The Nomad namespace to run the job"
  type        = string
  default     = "default"
}

job "tfe-job" {
  datacenters = ["dc1"]
  namespace   = var.namespace
  type        = "service"

  group "tfe-group" {
    count = 1

    reschedule {
      attempts  = 0
      unlimited = false
    }

    restart {
      attempts = 9
      delay    = "30s"
      interval = "10m"
      mode     = "fail"
    }

    update {
      max_parallel      = 1
      min_healthy_time  = "30s"
      healthy_deadline  = "15m"
      progress_deadline = "20m"
      health_check      = "checks"
    }

    network {
      mode = "bridge"

      port "tfe" {
        # Static port is not required if a load balancer is used.
        static = 443
        to     = 8443
      }
      port "tfehttp" {
        static = 80
        to     = 8080
      }
      port "vault" {
        to = 8201
      }
    }

    service {
      name     = "tfe-svc"
      port     = "tfe"
      provider = "nomad"
      #check {
      #  name     = "tfe_probe"
      #  type     = "http"
      #  protocol = "https"
      #  port     = "tfe"
      #  path     = "/_health_check"
      #  interval = "15s"
      #  timeout  = "15s"
      #  method   = "GET"
      #}
    }

    task "tfe-task" {
      driver = "docker"

      identity {
        env = true
      }

      template {
        data        = <<EOF
              {{- with nomadVar "nomad/jobs/tfe-job/tfe-group/tfe-task" -}}
              TFE_LICENSE={{ .tfe_license }}
              TFE_HOSTNAME={{ .tfe_hostname }}
              {{- end -}}
              EOF
        destination = "secrets/env.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = <<EOF
              {{- with nomadVar "nomad/jobs/tfe-job/tfe-group/tfe-task" -}}
              {{ base64Decode .tfe_tls_cert_file.Value }}
              {{- end -}}
              EOF
        destination = "secrets/cert.pem"
        env         = false
        change_mode = "restart"
      }

      template {
        data        = <<EOF
              {{- with nomadVar "nomad/jobs/tfe-job/tfe-group/tfe-task" -}}
              {{ base64Decode .tfe_tls_key_file.Value }}
              {{- end -}}
              EOF
        destination = "secrets/key.pem"
        env         = false
        change_mode = "restart"
      }

      template {
        data        = <<EOF
              {{- with nomadVar "nomad/jobs/tfe-job/tfe-group/tfe-task" -}}
              {{ base64Decode .tfe_tls_ca_bundle_file.Value }}
              {{- end -}}
              EOF
        destination = "secrets/bundle.pem"
        env         = false
        change_mode = "restart"
      }

      # Retrieve variables from external services
      template {
        data = <<EOF
{{ range nomadService "redis-svc" }}
TFE_REDIS_HOST="{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "postgres-svc" }}
TFE_DATABASE_HOST="{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "minio-svc" }}
TFE_OBJECT_STORAGE_S3_ENDPOINT="http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        env         = true
        destination = "secrets/ext.env"
      }

      config {
        image = var.tfe_image
        ports = ["tfe", "tfehttp", "vault"]

        auth {
          username = var.tfe_image_username
          password = var.tfe_image_password
        }

        volumes = ["secrets:/etc/ssl/private/terraform-enterprise"]
      }

      resources {
        cpu    = 2500
        memory = 2048
      }

      env {
        # TFE_DATABASE_HOST       = "from template"
        TFE_DATABASE_USER       = "postgres"
        TFE_DATABASE_PASSWORD   = "PASSWORD"
        TFE_DATABASE_NAME       = "tfedb"
        TFE_DATABASE_PARAMETERS = "sslmode=disable"
        TFE_OBJECT_STORAGE_TYPE                 = "s3"
        # TFE_OBJECT_STORAGE_S3_ENDPOINT          = "from template"
        TFE_OBJECT_STORAGE_S3_ACCESS_KEY_ID     = "minio"
        TFE_OBJECT_STORAGE_S3_SECRET_ACCESS_KEY = "PASSWORD"
        TFE_OBJECT_STORAGE_S3_REGION            = "ap-southeast-2"
        TFE_OBJECT_STORAGE_S3_BUCKET            = "tfebucket"
        #TFE_REDIS_HOST     = "from template"
        TFE_REDIS_USE_TLS  = "false"
        TFE_REDIS_USE_AUTH = "false"
        TFE_RUN_PIPELINE_DRIVER = "nomad"
        TFE_VAULT_DISABLE_MLOCK = "true"
        TFE_ENCRYPTION_PASSWORD = "PASSWORD"
        TFE_VAULT_CLUSTER_ADDRESS = "http://${NOMAD_HOST_ADDR_vault}"
        TFE_HTTP_PORT = "8080"
        TFE_HTTPS_PORT = "8443"
        TFE_TLS_CERT_FILE      = "/etc/ssl/private/terraform-enterprise/cert.pem"
        TFE_TLS_KEY_FILE       = "/etc/ssl/private/terraform-enterprise/key.pem"
        TFE_TLS_CA_BUNDLE_FILE = "/etc/ssl/private/terraform-enterprise/bundle.pem"
      }
    }
  }
}
