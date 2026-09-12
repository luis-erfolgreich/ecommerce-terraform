#!/bin/bash

# ==============================
# Atualização e instalação
# ==============================

dnf update -y
dnf install -y python3 python3-pip nginx

# ==============================
# Diretórios da aplicação
# ==============================

mkdir -p /opt/ecommerce/produtos
mkdir -p /opt/ecommerce/pedidos

# ==============================
# API de Produtos
# ==============================

cat > /opt/ecommerce/produtos/app.py <<'EOF'
${produtos_app}
EOF

# ==============================
# API de Pedidos
# ==============================

cat > /opt/ecommerce/pedidos/app.py <<'EOF'
${pedidos_app}
EOF

# ==============================
# Ambiente Python
# ==============================

python3 -m venv /opt/ecommerce/venv

/opt/ecommerce/venv/bin/pip install --upgrade pip
/opt/ecommerce/venv/bin/pip install flask boto3

# ==============================
# Serviço da API de Produtos
# ==============================

cat > /etc/systemd/system/produtos.service <<'EOF'
[Unit]
Description=API de Produtos
After=network.target

[Service]
WorkingDirectory=/opt/ecommerce/produtos
ExecStart=/opt/ecommerce/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ==============================
# Serviço da API de Pedidos
# ==============================

cat > /etc/systemd/system/pedidos.service <<'EOF'
[Unit]
Description=API de Pedidos
After=network.target

[Service]
WorkingDirectory=/opt/ecommerce/pedidos
Environment="SQS_QUEUE_URL=${sqs_queue_url}"
ExecStart=/opt/ecommerce/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ==============================
# Configuração do Nginx
# ==============================

cat > /etc/nginx/conf.d/ecommerce.conf <<'EOF'
server {
    listen 80;
    server_name _;

    location /produtos {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /pedidos {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# ==============================
# Inicialização dos serviços
# ==============================

systemctl daemon-reload

systemctl enable produtos
systemctl enable pedidos
systemctl enable nginx

systemctl start produtos
systemctl start pedidos
systemctl restart nginx
