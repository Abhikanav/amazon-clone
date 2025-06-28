resource "aws_security_group" "Jenkins-sg" {
  name        = "Jenkins-Security Group"
  description = "Open 22,443,80,8080,9000,9100"

  tags = {
    Name = "Jenkins-sg"
  }
}

variable "allowed_ports" {
  default = ["22", "80", "443", "8080", "9000", "9100","3000"]
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {

  for_each = toset(var.allowed_ports)
  security_group_id = aws_security_group.Jenkins-sg.id
  from_port         = each.value
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  to_port           = each.value
  
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.Jenkins-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_instance" "web" {
  ami                    = "ami-020cba7c55df1f615"
  instance_type          = "t2.medium"
  key_name               = "default-ec2"
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]
  user_data              = templatefile("./install_tools.sh", {})

  tags = {
    Name = "amazon clone"
  }
  root_block_device {
    volume_size = 30
  }
}
