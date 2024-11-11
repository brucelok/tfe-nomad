provider "aws" {
  region = "ap-southeast-2"
}

resource "null_resource" "speedtest" {
  provisioner "local-exec" {
    command = "curl -fSL https://releases.hashicorp.com/terraform-provider-aws/5.54.1/terraform-provider-aws_5.54.1_linux_amd64.zip -o /dev/null"
  }
  triggers = {
    always_run = timestamp()
  }
}
