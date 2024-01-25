variable "vpc_cidr" {
  default     = "10.0.0.0/16"
}

variable "subnet1_cidr" {
  default     = "10.0.0.0/24"
}

variable "subnet2_cidr" {
  default     = "10.0.1.0/24"
}

variable "amiid" {
   default = "ami-0d758c1134823146a"
}

variable "type" {
   default = "t2.micro"
}

variable "pemfile" {
   default = "master"
}