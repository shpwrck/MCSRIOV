# AWS infrastructure resources

resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_private_key_pem" {
  filename          = "${path.module}/id_rsa"
  sensitive_content = tls_private_key.global_key.private_key_pem
  file_permission   = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Temporary key pair used for SSH accesss
resource "aws_key_pair" "mcsriov_key_pair" {
  key_name_prefix = "${var.prefix}-mcsriov-"
  public_key      = tls_private_key.global_key.public_key_openssh
}

# Security group to allow all traffic
resource "aws_security_group" "mcsriov-allowall" {
  name        = "${var.prefix}-mcsriov-allowall"
  description = "MCSRIOV - allow all traffic"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Creator = "mcsriov"
  }
}

# Assume default subnet
resource "aws_default_subnet" "default_az1" {
  availability_zone = var.aws_availability_zone

  tags = {
    Creator = "mcsriov"
  }
}

# Elastic IPs
resource "aws_eip" "mcsriov-eip" {
  vpc               = true
  network_interface = aws_network_interface.mcsriov-eni[0].id
}

# Elastic network interfaces
resource "aws_network_interface" "mcsriov-eni" {
  count           = 3
  subnet_id       = aws_default_subnet.default_az1.id
  security_groups = [aws_security_group.mcsriov-allowall.id]

  tags = {
    Creator = "mcsriov"
  }
}

# Single k3s instance with interfaces
resource "aws_instance" "mcsriov-server" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = var.instance_type
  availability_zone = var.aws_availability_zone

  key_name = aws_key_pair.mcsriov_key_pair.key_name

  user_data = templatefile(
    join("/", [path.module, "files/userdata.template"]),
    {}
  )

  dynamic "network_interface" {
    for_each = aws_network_interface.mcsriov-eni.*.id
    iterator = eni
    content {
      network_interface_id = eni.value
      device_index         = eni.key
    }
  }

  root_block_device {
    volume_size = 16
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = aws_eip.mcsriov-eip.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = {
    Name    = "${var.prefix}-mcsriov-server"
    Creator = "mcsriov"
  }
}

resource "aws_eip_association" "eip_assoc" {
  allocation_id        = aws_eip.mcsriov-eip.id
  network_interface_id = aws_network_interface.mcsriov-eni[0].id
}
