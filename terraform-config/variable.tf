variable "region" { 
  type = string 
} 
variable "subnets_cidr_block" { 
  type = list(string)  
} 
variable "private_subnet_name" { 
  type = string 
} 

variable "public_subnet_name" { 
  type = string 
} 

variable "gw_name" { 
  type = string 
} 

variable "frontend_instance_name" { 
  type = string 
  default = "fermat-frontend-vm"
} 

variable "backend_instance_name" { 
  type = string 
  default = "fermat-backend-vm"
} 

variable "key_name" {
  type        = string
  default     = "fermat-vm-key"
}

variable "rsa_bits" {
  description = "RSA bit length"
  type        = number
  default     = 4096
}

variable "front_security_group_name" {
  description = "the security group"
  type        = string
  default     = "fermat-front-ssh-security-group"
}

variable "back_security_group_name" {
  description = "the security group"
  type        = string
  default     = "fermat-back-ssh-security-group"
}

variable "instance_type" { 
  type = string 
  default = "t2.medium"
} 

variable "algorithm" { 
  type = string 
  default = "RSA"
} 

variable "route_table_name" { 
  type = string 
  default = "fermat_public-route-table"
} 

#DNS Settings
variable "domain_name" { 
  type = string 
  default = "devops.intuitivesoft.cloud"
} 


variable "vpc_name" {
  type = string
  default = "fermat_streaming_vpc"
  
}

variable "vpc_cidr_block" { 
  type = string
  default = "172.16.0.0/16"
} 

variable "subdomain" {
  type        = string
  default     = "fermat-stream"
}