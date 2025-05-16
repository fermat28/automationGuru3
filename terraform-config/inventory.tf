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


locals {
  generic_config_content = templatefile("${path.module}/../ansible-project/vars/generic.yml.tmpl", {
    domain         = "${aws_route53_record.guru3route.name}"
    frontend_private_ip    = aws_instance.front_ec2_instance.private_ip
    backend_subnet = var.subnets_cidr_block[1]
  })
}

resource "local_file" "ansible_generic_vars" {
  content  = local.generic_config_content
  filename = "${path.module}/../ansible-project/vars/generic.yml"
}


