from flask import Flask, jsonify

app = Flask(__name__)

produtos = [
    {
        "id": 1,
        "nome": "Notebook",
        "preco": 3500.00
    },
    {
        "id": 2,
        "nome": "Mouse",
        "preco": 80.00
    },
    {
        "id": 3,
        "nome": "Teclado",
        "preco": 150.00
    }
]


@app.route("/produtos", methods=["GET"])
def listar_produtos():
    return jsonify(produtos)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
