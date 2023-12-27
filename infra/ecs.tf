# --- ECS Cluster ---

#Creates the cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.name}-${var.env}-cluster"
}

# --- ECS Node Role ---

#Allows EC2 to use the role
data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#This role will be used by our EC2 instances in the ECS cluster
resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = "${var.name}-${var.env}-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

#Gives the nessery rights
resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

#Used to be able to use the IAM role in EC2
resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "${var.name}-${var.env}-ecs-node-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}

# --- ECS Launch Template ---

#Get's the ecs AMI
data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

#What instances to launch
resource "aws_launch_template" "ecs_ec2" {
  name_prefix            = "${var.name}-${var.env}-ecs-ec2-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ecs_node_sg.id]

  iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
  monitoring { enabled = true }

  #In user_data you are required to pass ECS cluster name, so AWS can register EC2 instance as node of ECS cluster
  #Connets your instances to the cluster
  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

# --- ECS ASG ---
#The auto scaling group
#We set it 1 becuse we want to allways connect to the same instance
#TODO Look into useing sticky sessions, needs a cookie to work
resource "aws_autoscaling_group" "ecs" {
  name_prefix               = "${var.name}-${var.env}-ecs-asg-"
  vpc_zone_identifier       = aws_subnet.public[*].id
  min_size                  = 1
  max_size                  = 1
  health_check_grace_period = 30
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-${var.env}-ecs-cluster"
    propagate_at_launch = true
  }

  #AmazonECSManaged tag is required by AWS.
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

# --- ECS Capacity Provider ---

#Creates the instance that will handel scaling
resource "aws_ecs_capacity_provider" "main" {
  name = "${var.name}-${var.env}-ecs-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

#Connect to ECS cluster to the Capacity Provider??
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }
}



# --- Cloud Watch Logs ---

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}-${var.env}"
  retention_in_days = 14
}