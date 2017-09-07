data "aws_iam_policy_document" "consul_task_policy" {
  statement {
    actions = [
      "ec2:Describe*",
      "autoscaling:Describe*",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
    ]

    resources = ["*"]
  }

  ##
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_backup_bucket}",
      "arn:aws:s3:::${var.s3_backup_bucket}/*",
    ]
  }

  ##
}

data "aws_iam_policy_document" "assume_role_consul_task" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "consul_task" {
  name               = "tf-${data.aws_vpc.vpc.tags["Name"]}-consul-ecsTaskRole"
  path               = "${var.iam_path}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_consul_task.json}"
}

resource "aws_iam_role_policy" "consul_ecs_task" {
  name   = "tf-${data.aws_vpc.vpc.tags["Name"]}-consul-ecsTaskPolicy"
  role   = "${aws_iam_role.consul_task.id}"
  policy = "${data.aws_iam_policy_document.consul_task_policy.json}"
}

# ecsServiceRole for consul

resource "aws_iam_role" "ecsServiceRole" {
  name = "tf-${data.aws_vpc.vpc.tags["Name"]}-consul-ecsServiceRole"
  path = "${var.iam_path}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
      "Service": ["ecs.amazonaws.com"]

    },
    "Effect": "Allow",
    "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-ecsServiceRole" {
  role       = "${aws_iam_role.ecsServiceRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
