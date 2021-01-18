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