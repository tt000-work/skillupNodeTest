provider "docker" {  
  host = "unix:///var/run/docker.sock"  
}  

variable "container_names" {  
  type    = list(string)  
  default = ["dev", "int", "prod"]  
}  

variable "host_ports" {  
  type    = list(number)  
  default = [8081, 8082, 8083]  
}  

resource "docker_container" "container" {  
  count  = length(var.container_names)  
  name   = var.container_names[count.index]  
  image  = "ubuntu:latest"  
  command = ["sleep", "infinity"]

  ports {  
    internal = 80  # Change if necessary  
    external = var.host_ports[count.index]  
  }  
}  

output "container_ips" {  
  value = [  
    for c in docker_container.container : {  
      name = c.name  
      ip   = c.network_data[0].ip_address  
    }  
  ]  
}  
