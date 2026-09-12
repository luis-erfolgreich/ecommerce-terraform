# ==============================
# AMI Amazon Linux 2023
# ==============================

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ==============================
# Instância EC2
# ==============================

resource "aws_instance" "app" {
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t3.micro"
  key_name      = "luis-atividade"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_app.name

  user_data = templatefile("${path.module}/user_data.sh", {
    produtos_app  = file("${path.module}/app/produtos/app.py")
    pedidos_app   = file("${path.module}/app/pedidos/app.py")
    sqs_queue_url = aws_sqs_queue.pedidos.url
  })

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

# ==============================
# IAM Role da EC2
# ==============================

resource "aws_iam_role" "ec2_app" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ==============================
# Permissão da EC2 para enviar pedidos à SQS
# ==============================

resource "aws_iam_role_policy" "ec2_sqs" {
  name = "${var.project_name}-ec2-sqs-policy"
  role = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:SendMessage"
        ]

        Resource = aws_sqs_queue.pedidos.arn
      }
    ]
  })
}

# ==============================
# Instance Profile da EC2
# ==============================

resource "aws_iam_instance_profile" "ec2_app" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_app.name
}
