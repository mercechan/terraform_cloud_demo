provider "aws" {
  region = var.aws_region
}

#Create your webserver instance
resource "aws_instance" "Web" {
  ami           = "ami-078f16034794ecfbd"
  instance_type = "t2.micro"
  tags = {
    Name = "Node-Red-Server"
  }
  count                  = 1
  key_name               = "generic-ssh-key"
  subnet_id              = aws_subnet.node-red-vpc-subnet-public1-us-west-1a.id
  vpc_security_group_ids = [aws_security_group.nodered-sg.id]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/keyfiles/generic-ssh-key.pem")
      host        = aws_instance.Web[0].public_ip
    }

    inline = [
      "docker run -d -p 1880:1880 -v node_red_data:/data --name mynodered nodered/node-red:latest"
    ]
  }
}
