variable "workshop_title" {}
variable "github_token" {}
variable "github_organization" {}
provider "github" {
    token = var.github_token
    organization = var.github_organization
}

resource "github_repository" "workshop"{
    name = "workshop-${var.workshop_title}"
    description = "${var.workshop_title} workshop on ${formatdate("DD/MM/YYYY", timestamp())}"

    template {
        owner = "Zelgius"
        repository = "intro-to-devops-workshop-terraform-template"
    }
}