#!/bin/bash

# ==============================================================================
# Script de Demonstração ao Vivo - TUN0
#
# Funcionalidade:
# Este script foi projetado para uma demonstração visual e em tempo real
# da interface tun0. Ele abre terminais separados para servidor, cliente
# e monitor, permitindo visualizar todo o processo.
#
# Propósito:
# Perfeito para apresentações focadas na tun0, pois permite que a audiência
# veja a causa (geração de tráfego) e o efeito (contadores do monitor subindo)
# simultaneamente em múltiplas janelas.
#
# ==============================================================================

echo "--- DEMONSTRAÇÃO AO VIVO - TUN0 ---"
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

# Verifica a existência do 'gnome-terminal' para poder abrir novas janelas.
if ! command -v gnome-terminal &> /dev/null; then
    echo "Erro: 'gnome-terminal' não encontrado."
    echo "Este script de demonstração precisa do gnome-terminal para abrir"
    echo "múltiplas janelas para o servidor, cliente e monitor."
    exit 1
fi

# Verifica se o executável do túnel existe
if [ ! -f "../../traffic_tunnel/traffic_tunnel" ]; then
    echo "Compilando o túnel..."
    cd ../../traffic_tunnel
    make clean
    make
    cd ../../scripts/demos
fi

echo "Este script irá abrir 3 terminais separados:"
echo "1. Terminal do Servidor: ./traffic_tunnel tun0 -s 172.31.66.1"
echo "2. Terminal do Cliente: ./traffic_tunnel tun0 -c 172.31.66.101 -t client1.sh"
echo "3. Terminal do Monitor: python3 monitor.py tun0"
echo ""
echo "No terminal original, você poderá gerar tráfego de teste."
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

# --- Passo 1: Configurar TUN se necessário ---
echo "Passo 1: Configurando dispositivo TUN..."
if [ ! -e "/dev/tun" ]; then
    echo "Dispositivo TUN não encontrado. Configurando..."
    ./../../scripts/setups/setup_tun.sh
else
    echo "✓ Dispositivo TUN já configurado"
fi

# --- Passo 2: Limpar processos antigos ---
echo ""
echo "Passo 2: Limpando processos antigos..."
sudo pkill -f "traffic_tunnel" 2>/dev/null
sudo pkill -f "python3 monitor.py" 2>/dev/null
sleep 2

# --- Passo 3: Abrir Terminal do Servidor ---
echo ""
echo "Passo 3: Abrindo terminal do SERVIDOR..."
echo "No terminal do servidor, você verá:"
echo "- Inicialização do túnel"
echo "- Criação da interface tun0"
echo "- Aguardando conexão do cliente"
echo ""
gnome-terminal --title="Servidor Túnel" -- bash -c "cd ../../traffic_tunnel && sudo ./traffic_tunnel tun0 -s 172.31.66.1; exec bash"

# Aguarda o servidor inicializar
sleep 3

# --- Passo 4: Configurar servidor ---
echo ""
echo "Passo 4: Configurando interface do servidor..."
cd ../../traffic_tunnel
sudo ./server.sh
cd ../../scripts/demos
sleep 2

# --- Passo 5: Verificar se tun0 foi criada ---
echo ""
echo "Passo 5: Verificando interface tun0..."
if ip link show tun0 > /dev/null 2>&1; then
    echo "✓ Interface tun0 criada com sucesso!"
    echo "Status:"
    ip addr show tun0 | head -3
else
    echo "❌ Interface tun0 não foi criada"
    echo "Aguardando mais tempo..."
    sleep 3
    if ip link show tun0 > /dev/null 2>&1; then
        echo "✓ Interface tun0 criada na segunda tentativa!"
    else
        echo "❌ Falha na criação da tun0"
        cleanup
    fi
fi

# --- Passo 6: Abrir Terminal do Cliente ---
echo ""
echo "Passo 6: Abrindo terminal do CLIENTE..."
echo "No terminal do cliente, você verá:"
echo "- Conexão com o servidor"
echo "- Execução do script client1.sh"
echo "- Configuração da interface tun0 no cliente"
echo ""
gnome-terminal --title="Cliente Túnel" -- bash -c "cd ../../traffic_tunnel && sudo ./traffic_tunnel tun0 -c 172.31.66.101 -t client1.sh; exec bash"

# Aguarda o cliente conectar
sleep 3

# --- Passo 7: Verificar conectividade ---
echo ""
echo "Passo 7: Testando conectividade..."
ping -c 2 172.31.66.1 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Conectividade através do túnel funcionando!"
else
    echo "⚠ Conectividade pode estar instável"
fi

# --- Passo 8: Abrir Terminal do Monitor ---
echo ""
echo "Passo 8: Abrindo terminal do MONITOR..."
echo "No terminal do monitor, você verá:"
echo "- Captura de pacotes em tempo real"
echo "- Contadores de Camadas 2, 3 e 4"
echo "- Logs sendo gerados automaticamente"
echo ""
gnome-terminal --title="Monitor de Tráfego" -- sudo python3 ../../monitor/monitor.py tun0

# --- Passo 9: Instruções Finais ---
echo ""
echo "=== DEMONSTRAÇÃO INICIADA ==="
echo ""
echo "✓ Servidor: Terminal aberto (título: Servidor Túnel)"
echo "✓ Cliente: Terminal aberto (título: Cliente Túnel)"
echo "✓ Monitor: Terminal aberto (título: Monitor de Tráfego)"
echo ""
echo "Agora você pode:"
echo "1. Observar o servidor estabelecendo o túnel"
echo "2. Acompanhar o cliente conectando e executando client1.sh"
echo "3. Visualizar o monitor capturando pacotes em tempo real"
echo ""
echo "=== GERAÇÃO DE TRÁFEGO DE TESTE ==="
echo "Use os seguintes comandos neste terminal para gerar tráfego:"
echo ""
echo "ping 172.31.66.1"
echo "curl --interface tun0 http://example.com"
echo "dig @8.8.8.8 google.com"
echo ""
echo "OU use o script de tráfego diverso:"
echo "./scripts/gerador_trafego/gerar_trafego_teste.sh"
echo ""
echo "Para parar tudo, pressione Ctrl+C neste terminal."
echo ""
echo "🎯 Demonstração da tun0 funcionando!"
echo ""

# Aguarda o usuário encerrar
read -p "Pressione Enter para encerrar todos os processos..."

# Chama a função de limpeza para fechar todos os processos.
cleanup 