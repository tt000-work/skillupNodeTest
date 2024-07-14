provider "docker" {}

resource "docker_container" "dev" {
  image = "ubuntu:latest"
  name  = "dev-container"
  ports {
    internal = 80
    external = 8080
  }
}

resource "docker_container" "int" {
  image = "ubuntu:latest"
  name  = "int-container"
  ports {
    internal = 80
    external = 8081
  }
}

resource "docker_container" "prod" {
  image = "ubuntu:latest"
  name  = "prod-container"
  ports {
    internal = 80
    external = 8082
  }
}
//TODO:Change all the placeholders with accurate values - eg: image[Name]