locals {
  inventory_content = templatefile("${path.module}/../ansible-project/inventory.ini.tmpl", {
    frontend_ip = aws_instance.front_ec2_instance.public_ip
    backend_ip  = aws_instance.back_ec2_instance.private_ip
  })
}




resource "local_file" "ansible_inventory" {
  content  = local.inventory_content
  filename = "${path.module}/../ansible-project/inventory.ini"
}
