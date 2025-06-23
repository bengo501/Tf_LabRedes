#!/bin/bash

# ==============================================================================
# Script de Geração de Tráfego Diverso para Teste
#
# Funcionalidade:
# Gera diferentes tipos de tráfego para testar o monitor:
# - ICMP (ping)
# - TCP (HTTP, HTTPS, SSH)
# - UDP (DNS, NTP)
# - Tráfego local e externo
#
# ==============================================================================

echo "=== GERADOR DE TRÁFEGO DIVERSO ==="
echo ""

# Verifica se a interface tun0 está ativa
if ! ip link show tun0 > /dev/null 2>&1; then
    echo "❌ Interface tun0 não está ativa!"
    echo "Certifique-se de que o túnel está funcionando."
    exit 1
fi

echo "✓ Interface tun0 ativa"
echo "Iniciando geração de tráfego diverso..."
echo ""

# Função para gerar tráfego com delay
gerar_trafego() {
    local descricao="$1"
    local comando="$2"
    
    echo "🔄 $descricao..."
    eval "$comando" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ $descricao - Sucesso"
    else
        echo "⚠️  $descricao - Parcialmente bem-sucedido"
    fi
    sleep 1
}

# === TRÁFEGO ICMP (PING) ===
echo "=== TRÁFEGO ICMP ==="
gerar_trafego "Ping para servidor local" "ping -c 3 172.31.66.1"
gerar_trafego "Ping para gateway" "ping -c 2 8.8.8.8"
gerar_trafego "Ping para Google" "ping -c 2 google.com"

# === TRÁFEGO TCP (HTTP/HTTPS) ===
echo ""
echo "=== TRÁFEGO TCP ==="
gerar_trafego "HTTP - Example.com" "curl --interface tun0 --connect-timeout 5 http://example.com"
gerar_trafego "HTTP - HTTPBin" "curl --interface tun0 --connect-timeout 5 http://httpbin.org/ip"
gerar_trafego "HTTPS - Google" "curl --interface tun0 --connect-timeout 5 https://www.google.com"
gerar_trafego "HTTPS - GitHub" "curl --interface tun0 --connect-timeout 5 https://api.github.com"

# === TRÁFEGO UDP (DNS) ===
echo ""
echo "=== TRÁFEGO UDP ==="
gerar_trafego "DNS - Google (8.8.8.8)" "dig @8.8.8.8 google.com"
gerar_trafego "DNS - Cloudflare (1.1.1.1)" "dig @1.1.1.1 github.com"
gerar_trafego "DNS - Local" "dig @172.31.66.1 google.com" 2>/dev/null || echo "⚠️  DNS Local - Não disponível"

# === TRÁFEGO TCP DIVERSO ===
echo ""
echo "=== TRÁFEGO TCP DIVERSO ==="
gerar_trafego "SSH (porta 22)" "nc -z -w 3 8.8.8.8 22"
gerar_trafego "HTTP (porta 80)" "nc -z -w 3 example.com 80"
gerar_trafego "HTTPS (porta 443)" "nc -z -w 3 google.com 443"

# === TRÁFEGO LOCAL ===
echo ""
echo "=== TRÁFEGO LOCAL ==="
gerar_trafego "Conexão local TCP" "nc -z -w 2 172.31.66.1 80" 2>/dev/null || echo "⚠️  Conexão local - Porta 80 fechada"
gerar_trafego "Ping local" "ping -c 2 172.31.66.101"

# === TRÁFEGO DE TESTE ADICIONAL ===
echo ""
echo "=== TRÁFEGO DE TESTE ADICIONAL ==="
gerar_trafego "Download pequeno" "curl --interface tun0 --connect-timeout 5 -o /dev/null http://speedtest.ftp.otenet.gr/files/test100k.db"
gerar_trafego "API REST" "curl --interface tun0 --connect-timeout 5 https://jsonplaceholder.typicode.com/posts/1"

echo ""
echo "=== RESUMO ==="
echo "✅ Tráfego ICMP gerado (ping)"
echo "✅ Tráfego TCP gerado (HTTP/HTTPS)"
echo "✅ Tráfego UDP gerado (DNS)"
echo "✅ Tráfego local gerado"
echo ""
echo "Agora verifique o monitor para ver os contadores atualizados!"
echo "Comandos úteis:"
echo "  tail -f logs/camada3.csv"
echo "  tail -f logs/camada4.csv"
echo "" 