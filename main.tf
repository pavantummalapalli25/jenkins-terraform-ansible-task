provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "backend" { #ubuntu.yaml NETADATA
  ami                    = "ami-0e2c8caa4b6378d8c"
  instance_type          = "t2.micro" 
  key_name               = "jenkinsmaster"
  tags = {
    Name = "u21.local" 
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo hostnamectl set-hostname U21.local
  # netdata_conf="/etc/netdata/netdata.conf"
  # Path to netdata.conf
  # actual_ip=0.0.0.0
  # Use sed to replace the IP address in netdata.conf
  # sudo sed -i "s/bind socket to IP = .*$/bind socket to IP = $actual_ip/" "$netdata_conf"
EOF

}

resource "aws_instance" "frontend" { #amazon-playbook.yaml NGINX
  ami                    = "ami-0166fe664262f664c"
  instance_type          = "t2.micro"
  key_name               = "jenkinsmaster"
  tags = {
    Name = "c8.local"
  }
  user_data = <<-EOF
  #!/bin/bash
  # New hostname and IP address
  sudo hostnamectl set-hostname c8.local
  hostname=$(hostname)
  public_ip="$(curl -s https://api64.ipify.org?format=json | jq -r .ip)"

  # Path to /etc/hosts
  echo "${aws_instance.backend.public_ip} $hostname" | sudo tee -a /etc/hosts

EOF
depends_on = [aws_instance.backend]
}

resource "local_file" "inventory" {
  filename = "./inventory.yaml"
  content  = <<EOF
[frontend]
${aws_instance.frontend.public_ip}
[backend]
${aws_instance.backend.public_ip}
EOF
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}
