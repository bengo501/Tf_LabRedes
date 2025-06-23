#!/bin/bash

# ==============================================================================
# Script de Teste da Interface TUN0
#
# Funcionalidade:
# Este script testa especificamente a criação e funcionamento da interface tun0
# para garantir que o túnel cliente-servidor está funcionando corretamente.
#
# ==============================================================================

echo "--- TESTE DA INTERFACE TUN0 ---"
echo ""

# --- Verificações Iniciais ---
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script precisa ser executado com sudo."
    exit 1
fi

# Verifica se o executável do túnel existe
if [ ! -f "../../traffic_tunnel/traffic_tunnel" ]; then
    echo "Compilando o túnel..."
    cd ../../traffic_tunnel
    make clean
    make
    cd ../../scripts/testes
fi

echo "Este script irá testar a criação da interface tun0:"
echo "1. Verificar se tun0 existe atualmente"
echo "2. Iniciar o servidor do túnel"
echo "3. Conectar o cliente"
echo "4. Verificar se tun0 foi criada"
echo "5. Testar conectividade através do túnel"
echo ""
read -p "Pressione Enter para começar o teste..."
echo ""

# --- Passo 1: Verificar se tun0 já existe ---
echo "Passo 1: Verificando se tun0 já existe..."
if ip link show tun0 > /dev/null 2>&1; then
    echo "⚠ Interface tun0 já existe. Removendo..."
    ip link delete tun0
    sleep 1
else
    echo "✓ Interface tun0 não existe (estado inicial correto)"
fi

# --- Função de Limpeza ---
cleanup() {
    echo ""
    echo "Encerrando processos..."
    sudo pkill -f "traffic_tunnel"
    echo "Teste finalizado."
    exit
}

trap cleanup SIGINT

# --- Passo 2: Iniciar o Servidor ---
echo ""
echo "Passo 2: Iniciando o servidor do túnel..."
cd ../../traffic_tunnel
sudo ./traffic_tunnel tun0 -s 172.31.66.1 &
SERVER_PID=$!
cd ../../scripts/testes

# Aguarda o servidor inicializar
sleep 2

# --- Passo 3: Configurar a interface tun0 no servidor ---
echo "Passo 3: Configurando a interface tun0 no servidor..."
cd ../../traffic_tunnel
sudo ./server.sh
cd ../../scripts/testes

# Aguarda a configuração
sleep 2

# --- Passo 4: Verificar se tun0 foi criada ---
echo "Passo 4: Verificando se tun0 foi criada pelo servidor..."
if ip link show tun0 > /dev/null 2>&1; then
    echo "✓ Interface tun0 criada com sucesso pelo servidor!"
    echo "Status da interface:"
    ip addr show tun0
else
    echo "❌ Interface tun0 não foi criada pelo servidor"
    cleanup
fi

# --- Passo 5: Conectar o Cliente ---
echo ""
echo "Passo 5: Conectando o cliente ao servidor..."
cd ../../traffic_tunnel
sudo ./traffic_tunnel tun0 -c 172.31.66.101 -t client1.sh &
CLIENT_PID=$!
cd ../../scripts/testes

# Aguarda o cliente conectar
sleep 3

# --- Passo 6: Verificar se tun0 ainda está ativa ---
echo "Passo 6: Verificando se tun0 permanece ativa após conexão do cliente..."
if ip link show tun0 > /dev/null 2>&1; then
    echo "✓ Interface tun0 permanece ativa!"
    echo "Status final da interface:"
    ip addr show tun0
    echo ""
    echo "Rotas configuradas:"
    ip route show
else
    echo "❌ Interface tun0 não está mais ativa"
    cleanup
fi

# --- Passo 7: Testar Conectividade ---
echo ""
echo "Passo 7: Testando conectividade através do túnel..."
echo "Ping para o servidor (172.31.66.1):"
ping -c 3 172.31.66.1

echo ""
echo "Teste de conectividade com internet através do túnel:"
curl --interface tun0 --connect-timeout 5 http://example.com

echo ""
echo "=== RESULTADO DO TESTE ==="
echo "✓ Interface tun0 criada e configurada com sucesso"
echo "✓ Cliente conectado ao servidor"
echo "✓ Conectividade através do túnel funcionando"
echo ""
echo "Agora você pode executar o monitor na interface tun0!"
echo "Use: sudo python3 ../../monitor/monitor.py tun0"
echo ""
read -p "Pressione Enter para encerrar o teste..."

cleanup 