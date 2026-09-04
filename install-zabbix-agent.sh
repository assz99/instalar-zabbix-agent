#!/bin/bash

# ==========================================
# CONFIGURAÇÕES
# ==========================================

HOSTNAME_ZABBIX="Ubuntu-Server-01"
ZABBIX_SERVER="172.26.6.6"

# Versão do Zabbix
ZABBIX_VERSION="7.0"

# ==========================================
# NÃO ALTERAR ABAIXO
# ==========================================

set -Eeuo pipefail

echo "=========================================="
echo " Instalação do Zabbix Agent 2"
echo "=========================================="
echo ""

# ------------------------------------------
# Verificar ROOT
# ------------------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "ERRO: Execute o script como root."
    echo ""
    echo "Exemplo:"
    echo "sudo ./instalar_zabbix.sh"
    exit 1
fi

# ------------------------------------------
# Verificar Ubuntu
# ------------------------------------------

if [ ! -f /etc/os-release ]; then
    echo "ERRO: Não foi possível identificar o sistema operacional."
    exit 1
fi

source /etc/os-release

if [ "$ID" != "ubuntu" ]; then
    echo "ERRO: Este script foi desenvolvido para Ubuntu."
    echo "Sistema encontrado: $ID"
    exit 1
fi

echo "Sistema: Ubuntu $VERSION_ID"
echo "Hostname Zabbix: $HOSTNAME_ZABBIX"
echo "Servidor Zabbix: $ZABBIX_SERVER"
echo ""

# ------------------------------------------
# Atualizar sistema
# ------------------------------------------

echo "[1/7] Atualizando lista de pacotes..."

apt update

echo "OK"
echo ""

# ------------------------------------------
# Instalar dependências
# ------------------------------------------

echo "[2/7] Instalando dependências..."

apt install -y wget

echo "OK"
echo ""

# ------------------------------------------
# Adicionar repositório oficial Zabbix
# ------------------------------------------

echo "[3/7] Adicionando repositório oficial do Zabbix..."

wget -q \
    https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu${VERSION_ID}_all.deb \
    -O /tmp/zabbix-release.deb

if [ ! -f /tmp/zabbix-release.deb ]; then
    echo "ERRO: Não foi possível baixar o repositório do Zabbix."
    exit 1
fi

dpkg -i /tmp/zabbix-release.deb

apt update

echo "OK"
echo ""

# ------------------------------------------
# Instalar Zabbix Agent 2
# ------------------------------------------

echo "[4/7] Instalando Zabbix Agent 2..."

apt install -y zabbix-agent2 zabbix-agent2-plugin-*

echo "OK"
echo ""

# ------------------------------------------
# Configurar Zabbix Agent
# ------------------------------------------

echo "[5/7] Configurando Zabbix Agent 2..."

CONFIG="/etc/zabbix/zabbix_agent2.conf"

if [ ! -f "$CONFIG" ]; then
    echo "ERRO: Arquivo de configuração não encontrado:"
    echo "$CONFIG"
    exit 1
fi

# Backup
cp "$CONFIG" "${CONFIG}.backup"

# Configurar Server
sed -i "s/^Server=.*/Server=$ZABBIX_SERVER/" "$CONFIG"

# Configurar ServerActive
sed -i "s/^ServerActive=.*/ServerActive=$ZABBIX_SERVER/" "$CONFIG"

# Configurar Hostname
sed -i "s/^Hostname=.*/Hostname=$HOSTNAME_ZABBIX/" "$CONFIG"

echo "OK"
echo ""

# ------------------------------------------
# Habilitar serviço
# ------------------------------------------

echo "[6/7] Habilitando Zabbix Agent 2..."

systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

echo "OK"
echo ""

# ------------------------------------------
# Verificar serviço
# ------------------------------------------

echo "[7/7] Verificando Zabbix Agent 2..."

if ! systemctl is-active --quiet zabbix-agent2; then
    echo ""
    echo "ERRO: O Zabbix Agent 2 não iniciou corretamente."
    echo ""
    systemctl status zabbix-agent2 --no-pager
    exit 1
fi

echo ""
echo "=========================================="
echo " ZABBIX AGENT 2 INSTALADO COM SUCESSO"
echo "=========================================="
echo ""
echo "Hostname : $HOSTNAME_ZABBIX"
echo "Servidor : $ZABBIX_SERVER"
echo ""
echo "Porta 10050:"
ss -lntp | grep 10050 || true
echo ""
echo "Status:"
systemctl status zabbix-agent2 --no-pager