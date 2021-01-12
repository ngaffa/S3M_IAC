provider "aws" {
   region = var.region
}
resource "aws_ecr_repository" "s3m-repo" {
    name                 = "s3m-repo"
    image_tag_mutability = "IMMUTABLE"
   
  tags = {
    "project" = "S3M"
    "tuto"="medium"
  }
}

resource "aws_ecs_cluster" "s3m-ecs-fargate-cluster" {
  name = "s3m-ecs-fargate-cluster"
   tags = {
    "project" = "S3M"
    "tuto"="medium"
  }
}

resource "aws_vpc" "s3m-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
     tags = {
    "project" = "S3M"
    "tuto"="medium"
  }
}

# TODO: figure out how to support creating multiple subnets, one for each
# availability zone.
resource "aws_subnet" "s3m-public" {
    vpc_id = aws_vpc.s3m-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = var.availability_zone_1
     tags = {
    "name"="s3m-public"
    "project" = "S3M"
    "tuto"="medium"
  }
}
resource "aws_subnet" "s3m-private-1" {
    vpc_id = aws_vpc.s3m-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = var.availability_zone_2
    tags = {
    "name"="s3m-private"
    "project" = "S3M"
    "tuto"="medium"
  }
}
resource "aws_subnet" "s3m-private-2" {
    vpc_id = aws_vpc.s3m-vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = var.availability_zone_3
    tags = {
    "name"="s3m-private"
    "project" = "S3M"
    "tuto"="medium"
  }
}

resource "aws_internet_gateway" "s3m-igw" {
    vpc_id = aws_vpc.s3m-vpc.id
}

resource "aws_eip" "s3m-eip_nat_gateway" {
  vpc = true
}


resource "aws_nat_gateway" "s3m-ngw" {
  allocation_id = aws_eip.s3m-eip_nat_gateway.id
  subnet_id     = aws_subnet.s3m-public.id
  tags = {
    "project" = "S3M"
    "tuto"="medium"
  }
}

resource "aws_default_route_table" "s3m-rt-public" {
default_route_table_id = aws_vpc.s3m-vpc.default_route_table_id
route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.s3m-igw.id
    }
}

resource "aws_route_table" "s3m-rt-private" {
    vpc_id = aws_vpc.s3m-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.s3m-ngw.id
    }
}

resource "aws_route_table_association" "s3m-rta-private-1" {
    subnet_id = aws_subnet.s3m-private-1.id
    route_table_id = aws_route_table.s3m-rt-private.id
}


resource "aws_route_table_association" "s3m-rta-private-2" {
    subnet_id = aws_subnet.s3m-private-2.id
    route_table_id = aws_route_table.s3m-rt-private.id
}


resource "aws_lb" "s3m-nlb" {
  name               = "s3mnlb"
  internal           = true
  load_balancer_type = "network"
  subnets            =  [aws_subnet.s3m-private-1.id,aws_subnet.s3m-private-2.id]
  # [aws_subnet.s3m-private-1.id, aws_subnet.s3m-private-2.id]

  enable_deletion_protection = false

 tags = {
    "project" = "S3M"
    "tuto"="medium"
  }
}

resource "aws_lb_target_group" "s3m-tg" {
  name        = "s3m-nlb-tg"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.s3m-vpc.id
  tags = {
    "project" = "S3M"
    "tuto"="medium"
  }
}

# Forward TCP apiserver traffic to containers
resource "aws_lb_listener" "s3m-container-listner" {
  load_balancer_arn = aws_lb.s3m-nlb.arn
  protocol          = "TCP"
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.s3m-tg.arn
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "s3m-ecs-task-defintion" {
  family                = "s3m-ecs-task-defintion"
  container_definitions = file("task-definitions/s3m-docker.json")
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  requires_compatibilities = [ "FARGATE" ]
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn

  tags = {
    "project" = "S3M"
    "tuto"="medium"
  }
 
}

resource "aws_ecs_service" "s3m-ecs-service" {
  name            = "s3m-ecs-service"
  cluster         = aws_ecs_cluster.s3m-ecs-fargate-cluster.id
  task_definition = aws_ecs_task_definition.s3m-ecs-task-defintion.arn
  desired_count   = 2
  force_new_deployment = true
  launch_type = "FARGATE"

  network_configuration {    
    subnets = [aws_subnet.s3m-private-1.id,aws_subnet.s3m-private-2.id]
  }


  load_balancer {
    target_group_arn = aws_lb_target_group.s3m-tg.arn
    container_name   = "s3m-docker"
    container_port   = 80
  }

}