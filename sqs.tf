# ==============================
# Fila SQS
# ==============================

resource "aws_sqs_queue" "pedidos" {
  name = "pedidos-a-processar"

  visibility_timeout_seconds = 180

  tags = {
    Name = "${var.project_name}-sqs"
  }
}
