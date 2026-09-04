#!/bin/bash

# ==========================================
# CONFIGURAÇÕES
# ==========================================

HOSTNAME_ZABBIX="Ubuntu-Server-01"
ZABBIX_SERVER="172.26.6.6"

# ==========================================
# NÃO ALTERAR ABAIXO
# ==========================================

echo "=========================================="
echo " Instalação do Zabbix Agent 2"
echo "=========================================="
echo ""
echo "Hostname : $HOSTNAME_ZABBIX"
echo "Zabbix   : $ZABBIX_SERVER"
echo ""

# Verificar se está executando como root
if [ "$EUID" -ne 0 ]; then
    echo "Execute este script como root:"
    echo "sudo bash $0"
    exit 1
fi

# Atualizar pacotes
echo "[1/6] Atualizando sistema..."
apt update

# Instalar Zabbix Agent 2
echo "[2/6] Instalando Zabbix Agent 2..."
apt install zabbix-agent2 -y

# Fazer backup da configuração
echo "[3/6] Fazendo backup da configuração..."
cp /etc/zabbix/zabbix_agent2.conf \
   /etc/zabbix/zabbix_agent2.conf.bak

# Configurar servidor e hostname
echo "[4/6] Configurando Zabbix Agent 2..."

sed -i "s/^Server=.*/Server=$ZABBIX_SERVER/" \
    /etc/zabbix/zabbix_agent2.conf

sed -i "s/^ServerActive=.*/ServerActive=$ZABBIX_SERVER/" \
    /etc/zabbix/zabbix_agent2.conf

sed -i "s/^Hostname=.*/Hostname=$HOSTNAME_ZABBIX/" \
    /etc/zabbix/zabbix_agent2.conf

# Habilitar e iniciar serviço
echo "[5/6] Iniciando Zabbix Agent 2..."

systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

# Verificar serviço
echo "[6/6] Verificando serviço..."
echo ""

if systemctl is-active --quiet zabbix-agent2; then
    echo "=========================================="
    echo " ZABBIX AGENT 2 INSTALADO COM SUCESSO"
    echo "=========================================="
    echo ""
    echo "Hostname : $HOSTNAME_ZABBIX"
    echo "Servidor : $ZABBIX_SERVER"
    echo ""
    echo "Porta 10050:"
    ss -lntp | grep 10050
    echo ""
    echo "Status:"
    systemctl --no-pager status zabbix-agent2
else
    echo "=========================================="
    echo " ERRO AO INICIAR O ZABBIX AGENT 2"
    echo "=========================================="
    echo ""
    systemctl --no-pager status zabbix-agent2
    exit 1
fi