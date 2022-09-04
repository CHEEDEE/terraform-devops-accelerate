variable "resource_group_name" {
  default = "devopsrg"
}

variable "azure_location" {
  default = "East US"
}

variable "subnet_name" {
  default = "devops-subnet"
}
 
variable "network_name" {
    type = string
    default="devopsvnet"
}

variable "network_security_group" {
    type = string
    default="devopsvnetnsg"
}
 
variable "vm_name" {
    type = list
    default = [
        "devopsvm1",
    ]
}

variable "network_card" {
    type = list
    default = [
        "devopsvm1-nic1",
    ]
}

variable "public_ip" {
    type = list
    default = [
        "devopsvm1puplicip1",
    ]
}
