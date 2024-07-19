variable "container_names" {  
  default = ["dev", "int", "prod"]  # length 3  
}  

variable "host_ports" {  
  default = [8081, 8082, 8083]  # length 3  
} 