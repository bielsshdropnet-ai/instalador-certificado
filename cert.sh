
#!/bin/bash

clear

remover_certificado() {
    echo
    echo "===== CERTIFICADOS INSTALADOS ====="
    certbot certificates

    echo
    read -rp "Digite o domínio que deseja remover: " DOMINIO

    if [ -z "$DOMINIO" ]; then
        echo "Domínio não informado!"
        return
    fi

    if [ ! -d "/etc/letsencrypt/live/$DOMINIO" ]; then
        echo "Certificado não encontrado!"
        return
    fi

    echo
    echo "Domínio selecionado: $DOMINIO"
    read -rp "Confirma a remoção? (s/n): " CONFIRMA

    if [[ "$CONFIRMA" == "s" || "$CONFIRMA" == "S" ]]; then
        certbot delete --cert-name "$DOMINIO"

        if [ -f "/usr/local/etc/xray/ssl/cert.pem" ] && \
           openssl x509 -in /usr/local/etc/xray/ssl/cert.pem -noout -ext subjectAltName 2>/dev/null | grep -q "$DOMINIO"; then
            rm -f /usr/local/etc/xray/ssl/cert.pem
            rm -f /usr/local/etc/xray/ssl/priv.key
        fi

        echo "Certificado removido!"
    else
        echo "Remoção cancelada!"
    fi
}

menu() {
    clear

    echo "╔══════════════════════════════════╗"
    echo "║         GERENCIADOR SSL          ║"
    echo "║             DROPNET              ║"
    echo "╠══════════════════════════════════╣"
    echo "║                                  ║"
    echo "║  [1] INSTALAR CERTIFICADO SSL    ║"
    echo "║  [2] REMOVER CERTIFICADO SSL     ║"
    echo "║  [0] SAIR                        ║"
    echo "║                                  ║"
    echo "╚══════════════════════════════════╝"
    echo

    read -rp "Digite uma opção: " OPCAO

    case "$OPCAO" in
        1)
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
        2)
            remover_certificado
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac
}

menu
