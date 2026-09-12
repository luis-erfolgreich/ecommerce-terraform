from flask import Flask, jsonify, request
import boto3
import json
import os

app = Flask(__name__)

sqs = boto3.client("sqs", region_name="us-east-1")
QUEUE_URL = os.environ["SQS_QUEUE_URL"]


@app.route("/pedidos", methods=["POST"])
def criar_pedido():
    pedido = request.get_json()

    if not pedido:
        return jsonify({
            "erro": "O JSON do pedido é obrigatório"
        }), 400

    response = sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps(pedido)
    )

    return jsonify({
        "mensagem": "Pedido enviado para SQS",
        "message_id": response["MessageId"]
    }), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
