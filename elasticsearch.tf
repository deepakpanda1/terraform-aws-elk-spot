module "elk_security_group" {
  source      = "terraform-aws-modules/security-group/aws"
  description = "elasticsearch traffic"
  name        = "elk"
  vpc_id      = "${data.aws_vpc.selected.id}"

  egress_rules             = ["all-all"]
  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]

  ingress_rules = [
    "http-80-tcp",
    "ssh-tcp",
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 9000
      to_port     = 9000
      protocol    = "tcp"
      description = "portainer"
    },
    {
      from_port   = 8000
      to_port     = 8000
      protocol    = "tcp"
      description = "swarm-vis"
    },
    {
      from_port   = 9200
      to_port     = 9200
      protocol    = "tcp"
      description = "elasticsearch port"
    },
    {
      from_port   = 5043
      to_port     = 5044
      protocol    = "tcp"
      description = "logstash port"
    },
    {
      from_port   = 5601
      to_port     = 5601
      protocol    = "tcp"
      description = "kibana port"
    },
  ]
}

module "elk_spot" {
  source                               = "johnypony3/ec2-spot-instance/aws"
  name                                 = "${var.product}"
  ami                                  = "${data.aws_ami.ubuntu_server.id}"
  iam_instance_profile                 = "${data.aws_iam_instance_profile.ec2-s3.name}"
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "${var.instance_type}"
  key_name                             = "${var.key_name}"
  launch_group                         = "${random_pet.launch_group.id}"
  spot_price                           = "${var.spot_price}"
  spot_type                            = "one-time"
  subnet_id                            = "${data.aws_subnet.selected.id}"
  vpc_security_group_ids               = ["${module.elk_security_group.this_security_group_id}"]
  associate_public_ip_address          = true
  monitoring                           = true
  wait_for_fulfillment                 = true

  tags = {
    Environment = "production"
    Owner       = "user"
    petname     = "${random_pet.elk.id}"
  }
}

resource "random_pet" "elk" {
  separator = "_"
}

resource "random_pet" "launch_group" {
  separator = "_"
}

resource "null_resource" "elk_deploy" {
  triggers {
    cluster_instance_ids = "${join(",", module.elk_spot.spot_instance_id)}"
  }

  provisioner "local-exec" {
    command = "${data.template_file.tags.rendered}"
  }

  connection {
    agent       = false
    host        = "${module.elk_spot.public_ip}"
    private_key = "${file(var.pem_key)}"
    timeout     = "360s"
    user        = "ubuntu"
  }

  provisioner "file" {
    source      = "${path.module}/remote_files/"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/elasticsearch.sh"
  }
}

resource "aws_route53_record" "elk" {
  name    = "${var.product}.${var.stack_name}"
  records = ["${module.elk_spot.public_ip}"]
  ttl     = 1
  type    = "CNAME"
  zone_id = "${data.aws_route53_zone.public.zone_id}"
}
