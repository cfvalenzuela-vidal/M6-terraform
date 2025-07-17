output "dev_ec2_public_ip" {
  value       = aws_instance.dev_ec2.public_ip
  description = "IP pública de la instancia EC2 dev_ec2"
}

output "ssh_command_dev" {
  value       = "ssh -i clave-ec2 ec2-user@${aws_instance.dev_ec2.public_ip}"
  description = "Comando SSH para acceder a la instancia dev_ec2"
}

output "vpc_ids" {
  value = { for env in var.envs : env => aws_vpc.vpc[env].id }
  description = "IDs de las VPCs creadas"
}

output "subnet_ids" {
  value = {
    for env in var.envs : env => {
      public_a  = aws_subnet.public_a[env].id
      public_b  = aws_subnet.public_b[env].id
      private_a = aws_subnet.private_a[env].id
      private_b = aws_subnet.private_b[env].id
      data_a    = aws_subnet.data_a[env].id
      data_b    = aws_subnet.data_b[env].id
    }
  }
  description = "IDs de subnets por entorno"
}
