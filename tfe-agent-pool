# deploy a agent pool container
job "agent-pool" {
  datacenters = ["dc1"]

  type = "service"

  group "agent-group" {
    count = 1

    task "tfe-agent-task" {
      driver = "docker"

      config {
        image = "hashicorp/tfc-agent:latest"
      }

      env {
        TFC_AGENT_TOKEN     = "YOUR_TOKEN"
        TFC_AGENT_NAME      = "nomad-dc1"
        TFC_ADDRESS         = "YOUR_TFE_ADDR"
        TFC_AGENT_LOG_LEVEL = "debug"
      }

      resources {
        cpu    = 750
        memory = 1048
      }
    }
  }
}
