job "debug-service" {
  type = "service"

  group "debug-group" {
    count = 1

    network {
      mode = "bridge"
    }

    task "debug-task" {
      driver = "docker"

      config {
        image      = "appropriate/curl"
        entrypoint = ["/bin/sh", "-c"]
        args       = ["while true; do sleep 1000; done"]
      }

      template {
        data = <<EOF
{{ range nomadService "redis-svc" }}
TFE_REDIS_HOST="{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "postgres-svc" }}
TFE_DATABASE_HOST="{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "minio-svc" }}
TFE_OBJECT_STORAGE_S3_ENDPOINT="{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        env         = true
        destination = "secrets/ext.env"
      }
    }

    service {
      name     = "debug-service"
      provider = "nomad"
    }
  }
}
