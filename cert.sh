#!/bin/bash

clear

echo "╔══════════════════════════════════╗"
echo "║     INSTALADOR DE CERTIFICADO    ║"
echo "║             DROPNET              ║"
echo "╠══════════════════════════════════╣"
echo "║                                  ║"
echo "║  [1] INSTALAR CERTIFICADO SSL    ║"
echo "║  [0] SAIR                        ║"
echo "║                                  ║"
echo "╚══════════════════════════════════╝"
echo

read -p "Digite uma opção: " OPCAO

case "$OPCAO" in
    1)
        echo
        echo "Iniciando instalador..."
        echo

        read -p "Digite o domínio: " DOMINIO
        if [ -z "$DOMINIO" ]; then
            echo "Domínio não informado!"
            exit 1
        fi
        apt update -y
        apt install certbot -y
        systemctl stop xray 2>/dev/null
        certbot certonly --standalone -d $DOMINIO --non-interactive --agree-tos --register-unsafely-without-email
        mkdir -p /usr/local/etc/xray/ssl
        cp /etc/letsencrypt/live/$DOMINIO/fullchain.pem /usr/local/etc/xray/ssl/cert.pem
        cp /etc/letsencrypt/live/$DOMINIO/privkey.pem /usr/local/etc/xray/ssl/priv.key
        chmod 644 /usr/local/etc/xray/ssl/cert.pem
        chmod 600 /usr/local/etc/xray/ssl/priv.key
        tee /etc/systemd/system/xray.service > /dev/null << 'SERVICE'
[Unit]
Description=XRay Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE
        systemctl daemon-reload
        systemctl start xray
        echo "Concluido! Certificado para $DOMINIO instalado"
        ;;
    0)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida!"
        exit 1
        ;;
esac
