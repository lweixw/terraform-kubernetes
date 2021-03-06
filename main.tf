provider "aws" {
  region = "ap-southeast-2"
}
//Variables
variable "region" {
  type = "string"
  default= "sydney"
}
variable "sshKey" {
  type = "string"
  default = "James.Kwok"
}

//Mapping
variable "regionId" {
  type = "map"
  default = {
    sydney = "ap-southeast-2"
    oregon = "us-west-2"
  }
}
variable "availabilityZones" {
  type = "map"
  default = {
    sydney = "ap-southeast-2a"
    oregon = "us-west-2a"
  }
}

resource "aws_security_group" "allow_ssh_http_kubes" {
  name        = "allow_ssh_http_kubes"
  description = "Allow all inbound traffic for kubernetes"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //Required to allow outbound internet connection for user_data
  egress {
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_ssh_http"
  }
}

resource "aws_instance" "Kubernetes_Master" {
  depends_on = ["aws_security_group.allow_ssh_http_kubes"]
  ami           = "ami-e2021d81"
  availability_zone = "${lookup(var.availabilityZones, var.region)}"
  key_name = "${var.sshKey}"
  instance_type = "t2.medium"
  security_groups = [ "${aws_security_group.allow_ssh_http_kubes.name}" ]
  user_data = "${file("Kubernetes_userdata.sh")}"
  root_block_device {
    volume_size = 20
  }
  /*
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get upgrade",
      "echo $(date) > /tmp/flag"
    ]
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("/Users/jameskwok/.ssh/JamesKwok.pem")}"
    }
  }
  */
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.region}-Kubernetes-Master"
  }
}
