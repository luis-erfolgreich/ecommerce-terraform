import json


def lambda_handler(event, context):
    for record in event["Records"]:
        pedido = json.loads(record["body"])

        print("Pedido recebido pela Lambda:")
        print(pedido)

    return {
        "statusCode": 200,
        "body": "Pedido processado com sucesso"
    }
