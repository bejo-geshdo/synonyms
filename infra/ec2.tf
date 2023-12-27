# --- EC2 IAM ---

#Allows EC2 to use the role
data "aws_iam_policy_document" "ec2_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#This role will be used by our EC2 instances
resource "aws_iam_role" "ec2_role" {
  name_prefix        = "${var.name}-${var.env}-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_doc.json
}

#Used to be able to use the IAM role in EC2
resource "aws_iam_instance_profile" "ec2_role" {
  name_prefix = "${var.name}-${var.env}-ec2-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.ec2_role.name
}


#Allows EC2 to pull the docker image from ECR
data "aws_iam_policy_document" "ecr_pull_policy" {
  statement {
    sid    = "AllowPullFromECR"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]

    resources = [aws_ecr_repository.app.arn]
  }

  statement {
    sid    = "AllowGetAuthorizationToken"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_pull_policy" {
  name_prefix = "${var.name}-${var.env}-ECR-pull-policy"
  description = "Used to give a role access  to pull a specific image from ECR"
  policy      = data.aws_iam_policy_document.ecr_pull_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_ECR_pull_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}

# --- Security group ---
resource "aws_security_group" "ec2_docker_sg" {
  name_prefix = "ec2-docker-sg-"
  description = "Allow all traffic within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Launch template ---

#Find the latest AMI for amz linux 2 for x86
data "aws_ami" "amz_linux_2023" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  ecr_url = split("/", aws_ecr_repository.app.repository_url)[0]
}

resource "aws_launch_template" "ec2_docker_template" {
  name_prefix   = "${var.name}-${var.env}-ec2-docker-"
  image_id      = data.aws_ami.amz_linux_2023.image_id
  instance_type = var.instance_type
  key_name =  "test-key"
  #Look into the SG
  vpc_security_group_ids = [aws_security_group.ecs_node_sg.id, aws_security_group.ec2_docker_sg.id]

  iam_instance_profile { arn = aws_iam_instance_profile.ec2_role.arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
        #!/bin/bash
        echo "Installing Docker"
        yum update -y
        yum install docker -y
        service docker start
        usermod -a -G docker ec2-user

        echo "Setting up ECR access"
        aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${local.ecr_url}
        echo "Pulling docker image"
        docker pull "${aws_ecr_repository.app.repository_url}:latest"
        echo "Running container"
        docker run -d -p 80:80 --env PORT=80 ${aws_ecr_repository.app.repository_url}:latest
      EOF
  )
}

# --- ASG ---

resource "aws_autoscaling_group" "ec2_docker" {
  name                      = "${var.name}-${var.env}-ec2-asg-"
  vpc_zone_identifier       = aws_subnet.public[*].id
  min_size                  = 1
  max_size                  = 1
  health_check_grace_period = 90
  health_check_type         = "ELB"
  protect_from_scale_in     = false
  target_group_arns = [aws_lb_target_group.ec2_docker_alb.arn]

  launch_template {
    id      = aws_launch_template.ec2_docker_template.id
    version = aws_launch_template.ec2_docker_template.latest_version
  }

  instance_maintenance_policy {
    min_healthy_percentage = 100
    max_healthy_percentage = 200
  }

  #Automaticly updates the instances in the ASG
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      skip_matching          = false
    }
    triggers = ["launch_template"]
  }

  tag {
    key = "Name"
    value = "synonyms-api"
    propagate_at_launch = true
  }
}

# --- ALB ---

resource "aws_lb" "ec2_docker" {
  name               = "${var.name}-${var.env}-docker-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.http.id]
}

resource "aws_lb_target_group" "ec2_docker_alb" {
  name_prefix = "ec2-"
  vpc_id      = aws_vpc.main.id
  protocol    = "HTTP"
  port        = 80
  target_type = "instance"

  #TODO add an other path in API that returns 200 for helth checks
  health_check {
    enabled             = true
    path                = "/find"
    port                = 80
    matcher             = 400
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }
}

#How we access the lb
resource "aws_lb_listener" "ec2_docker_https" {
  depends_on        = [time_sleep.api_ec2_cert_dns]
  load_balancer_arn = aws_lb.ec2_docker.id
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_docker_alb.id
  }

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.api_ec2_cert.arn
}

# --- ACM for custom Domain ---

resource "aws_acm_certificate" "api_ec2_cert" {
  domain_name       = "api-ec2.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "api_ec2_cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.api_ec2_cert.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.api_ec2_cert.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.api_ec2_cert.domain_validation_options)[0].resource_record_type
  zone_id         = var.hosted_zone_id
  ttl             = 60
}

#Added this to give the cert time to validate before adding it to ALB
#TODO Find a better way to check if the cert has validate, if it's not validate terraform will get an error
resource "time_sleep" "api_ec2_cert_dns" {
  depends_on = [aws_route53_record.api_cert_dns]

  create_duration = "60s"
}

# --- Route 53 Custom domain ---

resource "aws_route53_record" "api_ec2" {
  zone_id = var.hosted_zone_id
  type    = "CNAME"
  ttl     = "300"
  name    = "api-ec2.${var.domain}"
  records = [aws_lb.ec2_docker.dns_name]
}

# --- IAM for gh actions ---

data "aws_iam_policy_document" "github_action_ASG_refresh_policy_doc" {
  statement {
    #TODO lock down action to only put or the same as AmazonEC2ContainerRegistryPowerUser
    actions   = ["autoscaling:StartInstanceRefresh", "autoscaling:Describe*"]
    effect    = "Allow"
    resources = [aws_autoscaling_group.ec2_docker.arn]
  }
}

resource "aws_iam_policy" "github_action_ASG_refresh_policy" {
  name_prefix = "${var.name}-${var.env}-gh-actions-ASG_refresh-policy"
  description = "Used to allow github actions to refresh an ASG when a new docker image exists"
  policy      = data.aws_iam_policy_document.github_action_ASG_refresh_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "github_action_ASG_refresh_policy" {
  role       = aws_iam_role.github_action_ECR_role.name
  policy_arn = aws_iam_policy.github_action_ASG_refresh_policy.arn
}