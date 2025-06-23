#!/bin/bash

# ==============================================================================
# Script de Demonstração ao Vivo com Túnel TUN0
#
# Funcionalidade:
# Este script estabelece o túnel cliente-servidor usando a interface tun0
# e depois executa o monitor de tráfego especificamente nesta interface.
#
# Propósito:
# Garante que o monitor capture o tráfego da interface tun0 conforme
# especificado no enunciado do trabalho.
#
# ==============================================================================

echo "--- DEMONSTRAÇÃO AO VIVO COM TÚNEL TUN0 ---"
echo ""

# --- Verificações Iniciais ---
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script precisa ser executado com sudo."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "Erro: Python 3 não está instalado."
    exit 1
fi

# Verifica se o executável do túnel existe
if [ ! -f "traffic_tunnel/traffic_tunnel" ]; then
    echo "Compilando o túnel..."
    cd traffic_tunnel
    make clean
    make
    cd ..
fi

# Verifica a existência do 'gnome-terminal' para poder abrir uma nova janela.
if ! command -v gnome-terminal &> /dev/null; then
    echo "Erro: 'gnome-terminal' não encontrado."
    echo "Este script de demonstração precisa do gnome-terminal para abrir"
    echo "uma nova janela para o monitor."
    exit 1
fi

echo ""
echo "Este script irá:"
echo "1. Iniciar o servidor do túnel"
echo "2. Conectar o cliente ao servidor"
echo "3. Abrir o monitor na interface tun0"
echo "4. Gerar tráfego para demonstração"
echo ""
read -p "Pressione Enter para iniciar a demonstração..."
echo ""

# --- Função de Limpeza ---
cleanup() {
    echo ""
    echo "Encerrando todos os processos..."
    sudo pkill -f "python3 monitor.py"
    sudo pkill -f "traffic_tunnel"
    echo "Demonstração finalizada."
    exit
}

# Garante que a limpeza seja chamada se o script for interrompido.
trap cleanup SIGINT

# --- Passo 1: Iniciar o Servidor ---
echo "Passo 1: Iniciando o servidor do túnel..."
gnome-terminal --title="Servidor Túnel" -- bash -c "cd traffic_tunnel && sudo ./traffic_tunnel tun0 -s 172.31.66.1; exec bash"

# Aguarda um pouco para o servidor inicializar
sleep 2

# --- Passo 2: Configurar a interface tun0 no servidor ---
echo "Passo 2: Configurando a interface tun0 no servidor..."
cd traffic_tunnel
sudo ./server.sh
cd ..

# Aguarda um pouco para a configuração
sleep 2

# --- Passo 3: Conectar o Cliente ---
echo "Passo 3: Conectando o cliente ao servidor..."
gnome-terminal --title="Cliente Túnel" -- bash -c "cd traffic_tunnel && sudo ./traffic_tunnel tun0 -c 172.31.66.101 -t client1.sh; exec bash"

# Aguarda um pouco para o cliente conectar
sleep 3

# --- Passo 4: Verificar se tun0 está ativa ---
echo "Passo 4: Verificando se a interface tun0 está ativa..."
if ip link show tun0 > /dev/null 2>&1; then
    echo "✓ Interface tun0 encontrada e ativa!"
    INTERFACE="tun0"
else
    echo "⚠ Interface tun0 não encontrada. Tentando novamente..."
    sleep 2
    if ip link show tun0 > /dev/null 2>&1; then
        echo "✓ Interface tun0 encontrada na segunda tentativa!"
        INTERFACE="tun0"
    else
        echo "❌ Interface tun0 não foi criada. Usando interface de fallback..."
        INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
        echo "Interface de fallback: $INTERFACE"
    fi
fi

# --- Passo 5: Executar o Monitor ---
echo "Passo 5: Abrindo o monitor na interface $INTERFACE..."
gnome-terminal --title="Monitor de Tráfego" -- sudo python3 monitor.py "$INTERFACE"

# Aguarda o monitor inicializar
echo "Aguardando 3 segundos para o monitor inicializar..."
sleep 3
echo ""

# --- Passo 6: Gerar Tráfego ---
echo "No terminal original, vamos gerar tráfego através do túnel."
echo "Observe os contadores subindo no terminal do monitor."
echo ""
echo "Pressione Enter para começar a gerar tráfego..."
read

# Gera tráfego ICMP (ping) através do túnel
echo "1. Gerando tráfego ICMP (ping) através do túnel..."
ping -c 5 172.31.66.1

# Gera tráfego TCP (HTTP) através do túnel
echo ""
echo "2. Gerando tráfego TCP (HTTP) através do túnel..."
curl --interface tun0 http://example.com

# Gera tráfego UDP (DNS) através do túnel
echo ""
echo "3. Gerando tráfego UDP (DNS) através do túnel..."
dig @8.8.8.8 google.com

echo ""
echo "Demonstração de tráfego concluída."
echo ""
read -p "Pressione Enter para encerrar todos os processos e finalizar a demonstração..."

# Chama a função de limpeza para fechar todos os processos.
cleanup 