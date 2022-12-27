//variable "aws_secret_key" {}
//variable "aws_access_key" {}
variable "region" {}
variable "mykey" {}
variable "tags" {}
# variable "myami" {
#   description = "1 amazon linux 2 "
# }
variable "instancetype" {}
variable "num" {}

variable "secgr-dynamic-ports" {
 description = "shh , http connection "
}