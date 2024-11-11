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

    volume "redis_data" {
      type      = "host"
      source    = "redis_data"
      read_only = false
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

      volume_mount {
        volume      = "redis_data"
        destination = "/data"
        read_only   = false
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

    volume "postgres_data" {
      type      = "host"
      source    = "postgres_data"
      read_only = false
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

      volume_mount {
        volume      = "postgres_data"
        destination = "/var/lib/postgresql/data"
        read_only   = false
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

    volume "minio_data" {
      type      = "host"
      source    = "minio_data"
      read_only = false
    }

    service {
      name     = "minio-svc"
      port     = "minio"
      provider = "nomad"
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

      volume_mount {
        volume      = "minio_data"
        destination = "/data"
        read_only   = false
      }
    }
  }
}
