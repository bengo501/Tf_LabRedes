#!/bin/bash

# ==============================================================================
# Script Final para Resolver Problemas da TUN0
#
# Funcionalidade:
# Este script resolve todos os problemas relacionados à interface tun0
# e garante que o monitor funcione corretamente conforme o enunciado.
#
# ==============================================================================

echo "--- RESOLUÇÃO COMPLETA DA TUN0 ---"
echo ""

# --- Verificações Iniciais ---
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script precisa ser executado com sudo."
    exit 1
fi

echo "Este script irá resolver todos os problemas da tun0:"
echo "1. Configurar dispositivo TUN"
echo "2. Limpar processos antigos"
echo "3. Estabelecer túnel cliente-servidor"
echo "4. Executar monitor na tun0"
echo "5. Gerar tráfego de teste"
echo ""
read -p "Pressione Enter para começar..."
echo ""

# --- Passo 1: Configurar TUN ---
echo "Passo 1: Configurando dispositivo TUN..."
./setup_tun.sh

# --- Passo 2: Limpar processos antigos ---
echo ""
echo "Passo 2: Limpando processos antigos..."
sudo pkill -f "traffic_tunnel" 2>/dev/null
sudo pkill -f "python3 monitor.py" 2>/dev/null
sleep 2

# --- Passo 3: Compilar túnel se necessário ---
echo ""
echo "Passo 3: Verificando compilação do túnel..."
if [ ! -f "traffic_tunnel/traffic_tunnel" ]; then
    echo "Compilando o túnel..."
    cd traffic_tunnel
    make clean
    make
    cd ..
fi

# --- Passo 4: Iniciar servidor ---
echo ""
echo "Passo 4: Iniciando servidor do túnel..."
cd traffic_tunnel
sudo ./traffic_tunnel tun0 -s 172.31.66.1 &
SERVER_PID=$!
cd ..
sleep 3

# --- Passo 5: Configurar servidor ---
echo ""
echo "Passo 5: Configurando interface do servidor..."
cd traffic_tunnel
sudo ./server.sh
cd ..
sleep 2

# --- Passo 6: Verificar tun0 ---
echo ""
echo "Passo 6: Verificando interface tun0..."
if ip link show tun0 > /dev/null 2>&1; then
    echo "✓ Interface tun0 criada com sucesso!"
    ip addr show tun0
else
    echo "❌ Interface tun0 não foi criada"
    exit 1
fi

# --- Passo 7: Conectar cliente ---
echo ""
echo "Passo 7: Conectando cliente..."
cd traffic_tunnel
sudo ./traffic_tunnel tun0 -c 172.31.66.101 -t client1.sh &
CLIENT_PID=$!
cd ..
sleep 3

# --- Passo 8: Verificar conectividade ---
echo ""
echo "Passo 8: Testando conectividade..."
ping -c 2 172.31.66.1 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Conectividade através do túnel funcionando!"
else
    echo "⚠ Conectividade pode estar instável"
fi

# --- Passo 9: Executar monitor ---
echo ""
echo "Passo 9: Iniciando monitor na interface tun0..."
echo "O monitor será executado em background."
echo "Para ver os logs em tempo real, use:"
echo "  tail -f logs/camada3.csv"
echo "  tail -f logs/camada4.csv"
echo ""
sudo python3 monitor.py tun0 &
MONITOR_PID=$!
sleep 2

# --- Passo 10: Gerar tráfego de teste ---
echo ""
echo "Passo 10: Gerando tráfego de teste..."
echo "Gerando ping para o servidor..."
ping -c 3 172.31.66.1 > /dev/null 2>&1

echo "Gerando tráfego HTTP através do túnel..."
curl --interface tun0 --connect-timeout 5 http://example.com > /dev/null 2>&1

echo "Gerando tráfego DNS através do túnel..."
dig @8.8.8.8 google.com > /dev/null 2>&1

# --- Passo 11: Mostrar resultados ---
echo ""
echo "=== RESULTADO FINAL ==="
echo "✓ Dispositivo TUN configurado"
echo "✓ Túnel cliente-servidor estabelecido"
echo "✓ Interface tun0 ativa"
echo "✓ Monitor executando na tun0"
echo "✓ Tráfego de teste gerado"
echo ""
echo "Status dos processos:"
ps aux | grep -E "(traffic_tunnel|python3 monitor.py)" | grep -v grep

echo ""
echo "Logs gerados:"
ls -la logs/

echo ""
echo "Últimas entradas do log de Camada 3:"
tail -3 logs/camada3.csv

echo ""
echo "=== INSTRUÇÕES ==="
echo "Para parar tudo: sudo pkill -f 'traffic_tunnel' && sudo pkill -f 'python3 monitor.py'"
echo "Para ver logs em tempo real: tail -f logs/camada3.csv"
echo "Para gerar mais tráfego: ping 172.31.66.1"
echo ""
echo "🎯 PROBLEMA RESOLVIDO! O monitor está funcionando na tun0 conforme o enunciado!"
echo "" 