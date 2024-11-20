# a parametrized batch job for remote execution mode
# this job name must be matched with env var `TFE_RUN_PIPELINE_NOMAD_AGENT_JOB_ID` defined in the main TFE jobspec

job "remote-exe-agent" {
  type        = "batch"
  namespace   = "default"
  datacenters = ["dc1"]

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  parameterized {
    payload = "forbidden"

    meta_required = [
      "TFC_AGENT_TOKEN",
      "TFC_ADDRESS"
    ]

    meta_optional = [
      "TFE_RUN_PIPELINE_IMAGE",
      "TFC_AGENT_AUTO_UPDATE",
      "TFC_AGENT_CACHE_DIR",
      "TFC_AGENT_SINGLE",
      "HTTPS_PROXY",
      "HTTP_PROXY",
      "NO_PROXY"
    ]
  }

  group "tfe-agent-group" {
    task "tfc-agent-task" {

      driver = "docker"

      template {
        destination = "local/image.env"
        env         = true
        change_mode = "noop"
        data        = <<EOF
          {{ $image := env "NOMAD_META_TFE_RUN_PIPELINE_IMAGE" }}
          {{ if ne $image "" }}TFE_RUN_PIPELINE_IMAGE={{$image}} {{ else }}TFE_RUN_PIPELINE_IMAGE="hashicorp/tfc-agent:latest"  {{ end }}
          EOF
      }

      config {
        image = "${TFE_RUN_PIPELINE_IMAGE}"
      }

      env {
        TFC_ADDRESS           = "${NOMAD_META_TFC_ADDRESS}"
        TFC_AGENT_TOKEN       = "${NOMAD_META_TFC_AGENT_TOKEN}"
        TFC_AGENT_AUTO_UPDATE = "${NOMAD_META_TFC_AGENT_AUTO_UPDATE}"
        TFC_AGENT_CACHE_DIR   = "${NOMAD_META_TFC_AGENT_CACHE_DIR}"
        TFC_AGENT_SINGLE      = "${NOMAD_META_TFC_AGENT_SINGLE}"
        HTTPS_PROXY           = "${NOMAD_META_HTTPS_PROXY}"
        HTTP_PROXY            = "${NOMAD_META_HTTP_PROXY}"
        NO_PROXY              = "${NOMAD_META_NO_PROXY}"
      }

      resources {
        cpu    = 500
        memory = 2048
      }
    }
  }
}
