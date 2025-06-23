#!/bin/bash

# ==============================================================================
# Script de Demonstração com Terminais Múltiplos - VERSÃO CORRIGIDA
#
# Funcionalidade:
# Este script abre 4 terminais separados seguindo EXATAMENTE os comandos manuais:
# - Terminal 1: Servidor (./traffic_tunnel tun0 -s 172.31.66.1)
# - Terminal 2: Configuração (./server.sh)
# - Terminal 3: Cliente (./client1.sh)
# - Terminal 4: Monitor (python3 monitor.py tun0)
# - Terminal Original: Geração de tráfego de teste
#
# Propósito:
# Demonstração completa e correta do sistema conforme enunciado do trabalho.
#
# ==============================================================================

echo "--- DEMONSTRAÇÃO COM TERMINAIS MÚLTIPLOS (VERSÃO CORRIGIDA) ---"
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
    echo "Este script precisa do gnome-terminal para abrir múltiplos terminais."
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

echo "Este script irá abrir 4 terminais separados seguindo os comandos manuais:"
echo "1. Terminal do Servidor: ./traffic_tunnel tun0 -s 172.31.66.1"
echo "2. Terminal de Configuração: ./server.sh"
echo "3. Terminal do Cliente: ./client1.sh"
echo "4. Terminal do Monitor: python3 monitor.py tun0"
echo ""
echo "No terminal original, você poderá gerar tráfego de teste:"
echo "  ping 172.31.66.1"
echo "  curl --interface tun0 http://example.com"
echo "  dig @8.8.8.8 google.com"
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
gnome-terminal --title="SERVIDOR TÚNEL" --geometry=80x20+50+50 -- bash -c "
echo '=== SERVIDOR DO TÚNEL ==='
echo 'Comando: ./traffic_tunnel tun0 -s 172.31.66.1'
echo 'Status: Iniciando...'
echo ''
cd ../../traffic_tunnel
echo 'Executando: sudo ./traffic_tunnel tun0 -s 172.31.66.1'
echo ''
sudo ./traffic_tunnel tun0 -s 172.31.66.1
echo ''
echo 'Servidor encerrado.'
read -p 'Pressione Enter para fechar...'
"

# Aguarda um pouco para o servidor inicializar
sleep 3

# --- Passo 4: Abrir Terminal de Configuração ---
echo ""
echo "Passo 4: Abrindo terminal de CONFIGURAÇÃO..."
echo "No terminal de configuração, você verá:"
echo "- Configuração da interface tun0"
echo "- Configuração de roteamento"
echo "- Configuração de iptables"
echo ""
gnome-terminal --title="CONFIGURAÇÃO SERVIDOR" --geometry=80x20+50+400 -- bash -c "
echo '=== CONFIGURAÇÃO DO SERVIDOR ==='
echo 'Comando: ./server.sh'
echo 'Status: Configurando...'
echo ''
cd ../../traffic_tunnel
echo 'Executando: sudo ./server.sh'
echo ''
sudo ./server.sh
echo ''
echo 'Configuração concluída.'
echo 'Interface tun0 configurada com IP 172.31.66.1'
echo ''
read -p 'Pressione Enter para fechar...'
"

# Aguarda a configuração
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
gnome-terminal --title="CLIENTE TÚNEL" --geometry=80x20+50+750 -- bash -c "
echo '=== CLIENTE DO TÚNEL ==='
echo 'Comando: ./client1.sh'
echo 'Status: Conectando...'
echo ''
cd ../../traffic_tunnel
echo 'Executando: sudo ./client1.sh'
echo ''
sudo ./client1.sh
echo ''
echo 'Cliente configurado.'
echo 'Interface tun0 configurada com IP 172.31.66.101'
echo ''
read -p 'Pressione Enter para fechar...'
"

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
gnome-terminal --title="MONITOR DE TRÁFEGO" --geometry=80x25+900+50 -- bash -c "
echo '=== MONITOR DE TRÁFEGO ==='
echo 'Interface: tun0'
echo 'Comando: python3 monitor.py tun0'
echo 'Status: Iniciando captura...'
echo ''
echo 'Para gerar tráfego de teste, use no terminal original:'
echo '  ping 172.31.66.1'
echo '  curl --interface tun0 http://example.com'
echo '  dig @8.8.8.8 google.com'
echo ''
echo 'Para ver logs em tempo real:'
echo '  tail -f ../../assets/logs/camada3.csv'
echo '  tail -f ../../assets/logs/camada4.csv'
echo ''
echo 'Executando monitor...'
echo ''
cd ../../monitor
sudo python3 monitor.py tun0
echo ''
echo 'Monitor encerrado.'
read -p 'Pressione Enter para fechar...'
"

# --- Passo 9: Instruções Finais ---
echo ""
echo "=== DEMONSTRAÇÃO INICIADA ==="
echo ""
echo "✓ Servidor: Terminal aberto (título: SERVIDOR TÚNEL)"
echo "✓ Configuração: Terminal aberto (título: CONFIGURAÇÃO SERVIDOR)"
echo "✓ Cliente: Terminal aberto (título: CLIENTE TÚNEL)"
echo "✓ Monitor: Terminal aberto (título: MONITOR DE TRÁFEGO)"
echo ""
echo "Agora você pode:"
echo "1. Observar o servidor estabelecendo o túnel"
echo "2. Ver a configuração da interface tun0"
echo "3. Acompanhar o cliente conectando e executando client1.sh"
echo "4. Visualizar o monitor capturando pacotes em tempo real"
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
echo "🎯 Demonstração completa funcionando!"
echo ""

# Aguarda o usuário encerrar
read -p "Pressione Enter para encerrar todos os processos..."

# Chama a função de limpeza para fechar todos os processos.
cleanup 