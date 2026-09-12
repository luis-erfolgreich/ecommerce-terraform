output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.app.public_ip
}

output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.app.id
}

output "sqs_queue_url" {
  description = "URL da fila SQS"
  value       = aws_sqs_queue.pedidos.url
}
