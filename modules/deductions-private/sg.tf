resource "aws_security_group" "mq_sg" {
    vpc_id = module.vpc.vpc_id
    name   = "deductor-mq-sg"

    # ingress {
    #     description     = "Allow traffic from Internal ALB to MQ Admin Console"
    #     protocol        = "tcp"
    #     from_port       = "8162"
    #     to_port         = "8162"
    #     security_groups = [aws_security_group.private-alb-internal-sg.id]
    # }

    tags = {
        Name = "deductor-mq-b-sg"
    }
}

resource "aws_security_group_rule" "ingress_int_alb_to_mq_admin" {
    type                = "ingress"
    security_group_id   = aws_security_group.mq_sg.id
    description         = "Allow traffic from Internal ALB to MQ Admin Console"
    protocol            = "tcp"
    from_port           = "8162"
    to_port             = "8162"
    source_security_group_id    = aws_security_group.private-alb-internal-sg.id
}

resource "aws_security_group_rule" "vpn_to_mq" {
    type                = "ingress"
    security_group_id   = aws_security_group.mq_sg.id
    description         = "Allow traffic from VPN to MQ"
    protocol            = "tcp"
    from_port           = "0"
    to_port             = "65535"
    source_security_group_id    = data.aws_ssm_parameter.vpn_sg.value
}

resource "aws_security_group_rule" "ingress_ecs_tasks" {
  type                = "ingress"
  security_group_id   = aws_security_group.mq_sg.id
  description         = "Access to Deductions Private ECS Tasks"
  protocol            = "tcp"
  from_port           = "61614"
  to_port             = "61614"
  source_security_group_id     = aws_security_group.gp2gp-adaptor-ecs-task-sg.id
}

resource "aws_security_group_rule" "ingress_amqp_ecs_tasks" {
  type                = "ingress"
  security_group_id   = aws_security_group.mq_sg.id
  description         = "Access for Deductions Private ECS Tasks"
  protocol            = "tcp"
  from_port           = "5671"
  to_port             = "5671"
  source_security_group_id     = aws_security_group.gp2gp-adaptor-ecs-task-sg.id
}

# resource "aws_security_group_rule" "ingress_console_nlb" {
#   type                = "ingress"
#   security_group_id   = aws_security_group.mq_sg.id
#   description         = "Access to MQ Admin Console NLB"
#   protocol            = "tcp"
#   from_port           = "8162"
#   to_port             = "8162"
#   cidr_blocks         = module.vpc.public_subnets_cidr_blocks
# }

resource "aws_security_group_rule" "ingress_mhs" {
  type                = "ingress"
  security_group_id   = aws_security_group.mq_sg.id
  description         = "Access to queues from MHS VPC"
  protocol            = "tcp"
  from_port           = "5671"
  to_port             = "5671"
  cidr_blocks         = [var.mhs_cidr]
}

resource "aws_security_group_rule" "egress_all" {
  type                = "egress"
  security_group_id   = aws_security_group.mq_sg.id
  description         = "Allow All Outbound"
  protocol            = "tcp"
  from_port           = "0"
  to_port             = "0"
  cidr_blocks         = ["0.0.0.0/0"]
}

resource "aws_security_group" "generic-comp-ecs-task-sg" {
    name        = "${var.environment}-generic-comp-ecs-task-sg"
    vpc_id      = module.vpc.vpc_id

    ingress {
        description     = "Allow traffic from ALB to Generic Component Task"
        protocol        = "tcp"
        from_port       = "3000"
        to_port         = "3000"
        security_groups = [aws_security_group.deductions-private-alb-sg.id]
    }

    ingress {
        description     = "Allow traffic from ALB to to Generic Component Task"
        protocol        = "tcp"
        from_port       = "80"
        to_port         = "80"
        security_groups = [aws_security_group.deductions-private-alb-sg.id]
    }

    ingress {
        description     = "Allow traffic from Internal ALB to Generic Component Task"
        protocol        = "tcp"
        from_port       = "3000"
        to_port         = "3000"
        security_groups = [aws_security_group.private-alb-internal-sg.id]
    }

    ingress {
        description     = "Allow traffic from Internal ALB to Generic Component Task"
        protocol        = "tcp"
        from_port       = "80"
        to_port         = "80"
        security_groups = [aws_security_group.private-alb-internal-sg.id]
    }

    egress {
        description = "Allow All Outbound"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.environment}-generic-comp-ecs-task-sg"
    }
}

resource "aws_security_group" "administration-portal-ecs-task-sg" {
    name        = "${var.environment}-administration-portal-ecs-task-sg"
    vpc_id      = module.vpc.vpc_id

    ingress {
        description     = "Allow traffic from ALB to Administration Portal Task"
        protocol        = "tcp"
        from_port       = "3000"
        to_port         = "3000"
        security_groups = [aws_security_group.deductions-private-alb-sg.id]
    }

    ingress {
        description     = "Allow traffic from ALB to Administration Portal Task"
        protocol        = "tcp"
        from_port       = "80"
        to_port         = "80"
        security_groups = [aws_security_group.deductions-private-alb-sg.id]
    }

    ingress {
        description     = "Allow traffic from Internal ALB to Administration Portal Task"
        protocol        = "tcp"
        from_port       = "3000"
        to_port         = "3000"
        security_groups = [aws_security_group.private-alb-internal-sg.id]
    }

    ingress {
        description     = "Allow traffic from Internal ALB to Administration Portal Task"
        protocol        = "tcp"
        from_port       = "80"
        to_port         = "80"
        security_groups = [aws_security_group.private-alb-internal-sg.id]
    }

    egress {
        description = "Allow All Outbound"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.environment}-administration-portal-ecs-task-sg"
    }
}

resource "aws_security_group" "gp2gp-adaptor-ecs-task-sg" {
    name        = "${var.environment}-gp2gp-adaptor-ecs-task-sg"
    vpc_id      = module.vpc.vpc_id

    ingress {
        description     = "Allow traffic from ALB to GP2GP Adaptor Task"
        protocol        = "tcp"
        from_port       = "3000"
        to_port         = "3000"
        security_groups = [aws_security_group.deductions-private-alb-sg.id]
    }

    ingress {
        description     = "Allow traffic from ALB to to GP2GP Task"
        protocol        = "tcp"
        from_port       = "80"
        to_port         = "80"
        security_groups = [aws_security_group.deductions-private-alb-sg.id]
    }

    ingress {
        description     = "Allow traffic from Internal ALB to GP2GP Adaptor Task"
        protocol        = "tcp"
        from_port       = "3000"
        to_port         = "3000"
        security_groups = [aws_security_group.private-alb-internal-sg.id]
    }

    ingress {
        description     = "Allow traffic from Internal ALB to to GP2GP Task"
        protocol        = "tcp"
        from_port       = "80"
        to_port         = "80"
        security_groups = [aws_security_group.private-alb-internal-sg.id]
    }

    egress {
        description = "Allow All Outbound"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.environment}-gp2gp-adaptor-ecs-task-sg"
    }
}


resource "aws_security_group" "deductions-private-alb-sg" {
    name        = "${var.environment}-${var.component_name}-alb-sg"
    description = "controls access to the ALB"
    vpc_id      = module.vpc.vpc_id

    ingress {
        description = "Allow Whitelisted Traffic to access PDS Adaptor ALB"
        protocol    = "tcp"
        from_port   = 80
        to_port     = 80
        cidr_blocks = var.allowed_public_ips
    }

    ingress {
        protocol    = "tcp"
        from_port   = 443
        to_port     = 443
        cidr_blocks = var.allowed_public_ips
    }

    egress {
        description = "Allow All Outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.environment}-deductions-private-alb-sg"
    }
}

resource "aws_security_group" "gp-to-repo-ecs-task-sg" {
    name        = "${var.environment}-gp-to-repo-ecs-task-sg"
    vpc_id      = module.vpc.vpc_id

    ingress {
        description     = "Allow traffic from ALB to the GP to Repo Task"
        protocol        = "tcp"
        from_port       = "3000"
        to_port         = "3000"
        security_groups = [aws_security_group.deductions-private-alb-sg.id]
    }

    ingress {
        description     = "Allow traffic from ALB to the GP to Repo Task"
        protocol        = "tcp"
        from_port       = "80"
        to_port         = "80"
        security_groups = [aws_security_group.deductions-private-alb-sg.id]
    }

    ingress {
        description     = "Allow traffic from Internal ALB to the GP to Repo Task"
        protocol        = "tcp"
        from_port       = "3000"
        to_port         = "3000"
        security_groups = [aws_security_group.private-alb-internal-sg.id]
    }

    ingress {
        description     = "Allow traffic from Internal ALB to the GP to Repo Task"
        protocol        = "tcp"
        from_port       = "80"
        to_port         = "80"
        security_groups = [aws_security_group.private-alb-internal-sg.id]
    }

    egress {
        description = "Allow All Outbound"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.environment}-gp-to-repo-ecs-task-sg"
    }
}

resource "aws_security_group" "private-alb-internal-sg" {
    name        = "${var.environment}-${var.component_name}-alb-internal-sg"
    description = "Internal ALB for deductions-private VPC"
    vpc_id      = module.vpc.vpc_id

    ingress {
        description = "Allow traffic from deductions-private VPC"
        protocol    = "tcp"
        from_port   = 80
        to_port     = 80
        cidr_blocks = [var.cidr]
    }

    ingress {
        protocol    = "tcp"
        from_port   = 443
        to_port     = 443
        cidr_blocks = [var.cidr]
    }

    egress {
        description = "Allow All Outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.environment}-deductions-private-alb-internal-sg"
    }
}

resource "aws_security_group" "ecr-endpoint-sg" {
  name        = "${var.environment}-${var.component_name}-ecr-endpoint-sg"
  description = "Taffic for the ECR VPC endpoint."
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    security_groups = [
      aws_security_group.gp-to-repo-ecs-task-sg.id,
      aws_security_group.gp2gp-adaptor-ecs-task-sg.id,
      aws_security_group.administration-portal-ecs-task-sg.id,
      aws_security_group.generic-comp-ecs-task-sg.id
    ]
  }

  tags = {
    name            = "${var.environment}-${var.component_name}-ecr-endpoint-sg"
    Environment     = var.environment
    Deductions-VPC  = var.component_name
  }
}

resource "aws_security_group" "logs-endpoint-sg" {
  name        = "${var.environment}-${var.component_name}-logs-endpoint-sg"
  description = "Traffic for the CloudWatch Logs VPC endpoint."
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    security_groups = [
      aws_security_group.gp-to-repo-ecs-task-sg.id,
      aws_security_group.gp2gp-adaptor-ecs-task-sg.id,
      aws_security_group.administration-portal-ecs-task-sg.id,
      aws_security_group.generic-comp-ecs-task-sg.id
    ]
  }

  tags = {
    name            = "${var.environment}-${var.component_name}-logs-endpoint-sg"
    Environment     = var.environment
    Deductions-VPC  = var.component_name
  }
}

resource "aws_security_group" "state-db-sg" {
    name        = "${var.environment}-state-db-sg"
    vpc_id      = module.vpc.vpc_id

    ingress {
        description     = "Allow traffic from gp-to-repo to the db"
        protocol        = "tcp"
        from_port       = "5432"
        to_port         = "5432"
        security_groups = [aws_security_group.gp-to-repo-ecs-task-sg.id]
    }

    tags = {
        Name = "${var.environment}-state-db-sg"
    }
}
