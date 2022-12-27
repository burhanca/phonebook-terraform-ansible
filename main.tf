
//This Terraform Template creates 1 Ansible Machines on EC2 Instances and Triggers CFN stack
//Ansible Machine(Control Node) will run on Amazon Linux 2 with custom security group
//allowing SSH (22) and HTTP (80) connections from anywhere.
//User needs to select appropriate variables form "tfvars" file when launching the instance.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.40.0"
    }
  }
}

provider "aws" {
  
 region = var.region
}

locals {
  user = "burhan"
}

# K8s  Cluster trigger
resource "aws_cloudformation_stack" "tf_kubernetes_cluster" {

  name          = "k8s-stack"
  on_failure    = "ROLLBACK"
  template_body = file("k8s-cfn.yml")   # to trigger CFN template

  capabilities = ["CAPABILITY_IAM"]
}


# ANSIBLE  CONTROL NODE EC2

data "aws_ami" "amazon_linux2" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-5.10*"]
  }
}

# ANSIBLE CONTROL NODE
resource "aws_instance" "nodes" {
  ami = data.aws_ami.amazon_linux2.id
  instance_type = var.instancetype
  count = var.num
  key_name = var.mykey
  iam_instance_profile = aws_iam_instance_profile.ec2full.name
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  tags = {
    Name = "${element(var.tags, count.index)}-${local.user}"
  }
}

resource "aws_security_group" "tf-sec-gr" {
  name = "ansible-sec-gr-${local.user}"
  tags = {
    Name = "ansible-session-sec-gr-${local.user}"
  }


  dynamic "ingress" {
    for_each = var.secgr-dynamic-ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "null_resource" "config" {
  depends_on = [aws_instance.nodes[0]]
  connection {
    host = aws_instance.nodes[0].public_ip
    type = "ssh"
    user = "ec2-user"
    private_key = file("~/.ssh/${var.mykey}.pem")
    # Do not forget to define your key file path correctly!
  }

  provisioner "file" {
    source = "./ansible.cfg"
    destination = "/home/ec2-user/ansible.cfg"
  }

   # Copy K8s  manifest files to ansible control node
   provisioner "file" {
    source = "./k8s"
    destination = "/home/ec2-user/k8s"
  }

   # Copy Ansible playbooks
   provisioner "file" {
    source = "./Ansible"
    destination = "/home/ec2-user/Ansible"
  } 

 provisioner "file" {
    source = "./inventory_aws_ec2.yml"
    destination = "/home/ec2-user/inventory_aws_ec2.yml"
  }
  provisioner "file" {
    # Do not forget to define your key file path correctly!
    source = "~/.ssh/${var.mykey}.pem"
    destination = "/home/ec2-user/${var.mykey}.pem"
  }
   provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname Control-Node",
      "sudo yum update -y",
      "sudo amazon-linux-extras install ansible2 -y",
      "sudo yum install pip -y ",
      "pip install --user boto3 botocore",
      "chmod 400 ${var.mykey}.pem"
    ]
  }
}



