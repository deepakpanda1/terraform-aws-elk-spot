data "aws_vpc" "selected" {
  filter {
    name = "tag:Name"

    values = [
      "${var.stack_name}",
    ]
  }
}

data "aws_route53_zone" "public" {
  name = "theemm.com."
}

data "aws_iam_instance_profile" "ec2-s3" {
  name = "${var.stack_name}-iam-instance"
}

data "aws_ami" "ubuntu_server" {
  most_recent = true

  filter {
    name = "name"

    values = ["*ubuntu-xenial-16.04*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name = "virtualization-type"

    values = ["hvm"]
  }

  filter {
    name = "owner-id"

    values = ["099720109477"]
  }
}

data "aws_subnet" "selected" {
  filter {
    name = "tag:Name"

    values = [
      "${var.stack_name}-public-${var.aws_region}a",
    ]
  }
}

data "template_file" "tags" {
  template = "${file("${path.module}/templates/tags.tpl")}"

  vars {
    pet_id           = "${random_pet.elk.id}"
    product          = "${var.product}"
    stack_name       = "${var.stack_name}"
    spot_instance_id = "${module.elk_spot.spot_instance_id[0]}"
  }
}
