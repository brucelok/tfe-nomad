job "ext-svc" {
  type = "service"

  group "redis-group" {
    count = 1
    network {
      mode = "bridge"
      port "redis" {
        to = 6379
      }
    }

    service {
      name     = "redis-svc"
      port     = "redis"
      provider = "nomad"
    }

    task "redis-task" {
      driver = "docker"

      config {
        image = "redis:7"
        ports = ["redis"]
      }
    }
  }

  group "postgres-group" {
    count = 1
    network {
      mode = "bridge"
      port "postgres" {
        to = 5432
      }
    }

    service {
      name     = "postgres-svc"
      port     = "postgres"
      provider = "nomad"
    }

    task "postgres-task" {
      driver = "docker"

      config {
        image = "postgres:16"
        ports = ["postgres"]
      }
      env {
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
        POSTGRES_DB       = "tfedb"
      }
    }
  }

  group "minio-group" {
    count = 1
    network {
      mode = "bridge"
      port "minio" {
        to = 9000
      }
    }

    service {
      name     = "minio-svc"
      port     = "minio"
      provider = "nomad"
      tags     = ["minio", "s3"]
    }

    task "minio-task" {
      driver = "docker"

      config {
        image = "minio/minio:latest"
        ports = ["minio"]
        args  = ["server", "/data"]
      }

      env {
        MINIO_ROOT_USER     = "minio"
        MINIO_ROOT_PASSWORD = "minio123"
      }
    }
  }
}
