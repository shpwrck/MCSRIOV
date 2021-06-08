output "instance_ip" {
  value = aws_eip.mcsriov-eip.public_ip
}
