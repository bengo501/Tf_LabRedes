#!/bin/bash

# ==============================================================================
# Script de Teste Rápido e Guiado - VERSÃO ATUALIZADA
#
# Funcionalidade:
# Este script funciona como um menu interativo para guiar o usuário através
# dos diferentes cenários de teste do projeto, usando os mesmos comandos
# do demo_terminal_multiplo.sh para garantir consistência.
#
# Propósito:
# Ideal para demonstrações passo a passo e para o usuário final, pois permite
# escolher qual cenário testar e fornece o contexto necessário para cada opção.
#
# Autor: Bernardo Klein Heitz
# Data: 2025-06-23
# ==============================================================================

echo "--- TESTE RÁPIDO - MONITOR DE TRÁFEGO (VERSÃO ATUALIZADA) ---"
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

# Verifica a existência do 'gnome-terminal' para opções que precisam
if ! command -v gnome-terminal &> /dev/null; then
    echo "Aviso: 'gnome-terminal' não encontrado."
    echo "Algumas opções podem não funcionar corretamente."
    echo ""
fi

echo "Verificações iniciais concluídas."
echo ""

# --- Menu de Opções ---
echo "Este script ajuda a testar o projeto usando os comandos oficiais."
echo "Por favor, escolha uma opção:"
echo "  1) Teste completo com terminais múltiplos (demo oficial)"
echo "  2) Teste manual passo a passo (guiado)"
echo "  3) Teste apenas do monitor (tun0 já configurada)"
echo "  4) Teste de criação da interface tun0"
echo "  5) Demonstrar captura de Camada 2 (interface física)"
echo "  6) Sair"
echo ""
read -p "Sua escolha [1]: " ESCOLHA
ESCOLHA=${ESCOLHA:-1}

# Cria o diretório de logs se ele não existir.
mkdir -p ../../assets/logs

# --- Função de Limpeza ---
cleanup() {
    echo ""
    echo "Encerrando processos..."
    sudo pkill -f "python3 monitor.py" 2>/dev/null
    sudo pkill -f "traffic_tunnel" 2>/dev/null
    echo "Processos encerrados."
}

# Garante que a limpeza seja chamada se o script for interrompido.
trap cleanup SIGINT

# --- Lógica do Script ---
if [ "$ESCOLHA" -eq 1 ]; then
    # OPÇÃO 1: Teste completo com terminais múltiplos (mesmo do demo_terminal_multiplo.sh)
    echo ""
    echo "--- Teste Completo com Terminais Múltiplos ---"
    echo "Este teste abre 4 terminais seguindo os comandos oficiais:"
    echo "1. Servidor: ./traffic_tunnel tun0 -s 172.31.66.1"
    echo "2. Configuração: ./server.sh"
    echo "3. Cliente: ./client1.sh"
    echo "4. Monitor: python3 monitor.py tun0"
    echo ""
    read -p "Pressione Enter para iniciar o teste completo..."
    
    # Verifica se o executável do túnel existe
    if [ ! -f "../../traffic_tunnel/traffic_tunnel" ]; then
        echo "Compilando o túnel..."
        cd ../../traffic_tunnel
        make clean
        make
        cd ../../scripts/testes
    fi
    
    # Configurar TUN se necessário
    echo "Configurando dispositivo TUN..."
    if [ ! -e "/dev/tun" ]; then
        ./../../scripts/setups/setup_tun.sh
    fi
    
    # Limpar processos antigos
    echo "Limpando processos antigos..."
    sudo pkill -f "traffic_tunnel" 2>/dev/null
    sudo pkill -f "python3 monitor.py" 2>/dev/null
    sleep 2
    
    # Abrir Terminal do Servidor
    echo "Abrindo terminal do SERVIDOR..."
    gnome-terminal --title="SERVIDOR TÚNEL" --geometry=80x20+50+50 -- bash -c "
echo '=== SERVIDOR DO TÚNEL ==='
echo 'Comando: ./traffic_tunnel tun0 -s 172.31.66.1'
cd ../../traffic_tunnel
sudo ./traffic_tunnel tun0 -s 172.31.66.1
read -p 'Pressione Enter para fechar...'
"
    sleep 3
    
    # Abrir Terminal de Configuração
    echo "Abrindo terminal de CONFIGURAÇÃO..."
    gnome-terminal --title="CONFIGURAÇÃO SERVIDOR" --geometry=80x20+50+400 -- bash -c "
echo '=== CONFIGURAÇÃO DO SERVIDOR ==='
echo 'Comando: ./server.sh'
cd ../../traffic_tunnel
sudo ./server.sh
echo 'Configuração concluída.'
read -p 'Pressione Enter para fechar...'
"
    sleep 2
    
    # Verificar tun0
    echo "Verificando interface tun0..."
    if ip link show tun0 > /dev/null 2>&1; then
        echo "✓ Interface tun0 criada!"
    else
        echo "❌ Interface tun0 não criada"
        cleanup
        exit 1
    fi
    
    # Abrir Terminal do Cliente
    echo "Abrindo terminal do CLIENTE..."
    gnome-terminal --title="CLIENTE TÚNEL" --geometry=80x20+50+750 -- bash -c "
echo '=== CLIENTE DO TÚNEL ==='
echo 'Comando: ./client1.sh'
cd ../../traffic_tunnel
sudo ./client1.sh
echo 'Cliente configurado.'
read -p 'Pressione Enter para fechar...'
"
    sleep 3
    
    # Abrir Terminal do Monitor
    echo "Abrindo terminal do MONITOR..."
    gnome-terminal --title="MONITOR DE TRÁFEGO" --geometry=80x25+900+50 -- bash -c "
echo '=== MONITOR DE TRÁFEGO ==='
echo 'Interface: tun0'
echo 'Comando: python3 monitor.py tun0'
echo ''
echo 'Para gerar tráfego de teste:'
echo '  ping 172.31.66.1'
echo '  curl --interface tun0 http://example.com'
echo '  dig @8.8.8.8 google.com'
echo ''
cd ../../monitor
sudo python3 monitor.py tun0
read -p 'Pressione Enter para fechar...'
"
    
    echo ""
    echo "=== TESTE COMPLETO INICIADO ==="
    echo "✓ 4 terminais abertos com os comandos oficiais"
    echo ""
    echo "Para gerar tráfego de teste, use neste terminal:"
    echo "ping 172.31.66.1"
    echo "curl --interface tun0 http://example.com"
    echo "dig @8.8.8.8 google.com"
    echo ""
    echo "OU use: ./scripts/gerador_trafego/gerar_trafego_teste.sh"
    echo ""
    read -p "Pressione Enter para encerrar..."

elif [ "$ESCOLHA" -eq 2 ]; then
    # OPÇÃO 2: Teste manual passo a passo
    echo ""
    echo "--- Teste Manual Passo a Passo ---"
    echo "Este teste guia você através de cada comando manualmente."
    echo ""
    echo "Passo 1: Iniciar servidor"
    echo "Em outro terminal, execute:"
    echo "  cd traffic_tunnel"
    echo "  sudo ./traffic_tunnel tun0 -s 172.31.66.1"
    echo ""
    read -p "Pressione Enter quando o servidor estiver rodando..."
    
    echo ""
    echo "Passo 2: Configurar servidor"
    echo "Em outro terminal, execute:"
    echo "  cd traffic_tunnel"
    echo "  sudo ./server.sh"
    echo ""
    read -p "Pressione Enter quando a configuração estiver concluída..."
    
    echo ""
    echo "Passo 3: Iniciar cliente"
    echo "Em outro terminal, execute:"
    echo "  cd traffic_tunnel"
    echo "  sudo ./client1.sh"
    echo ""
    read -p "Pressione Enter quando o cliente estiver conectado..."
    
    echo ""
    echo "Passo 4: Iniciar monitor"
    echo "Agora vamos iniciar o monitor:"
    echo "Interface: tun0"
    echo "Comando: python3 monitor.py tun0"
    echo ""
    read -p "Pressione Enter para iniciar o monitor..."
    
    cd ../../monitor
    sudo python3 monitor.py tun0

elif [ "$ESCOLHA" -eq 3 ]; then
    # OPÇÃO 3: Teste apenas do monitor (tun0 já configurada)
    echo ""
    echo "--- Teste Apenas do Monitor (tun0 já configurada) ---"
    
    if ! ip addr show tun0 &> /dev/null; then
        echo "Erro: Interface 'tun0' não encontrada."
        echo "   Por favor, certifique-se de que o servidor do túnel está"
        echo "   rodando em outro terminal antes de executar este teste."
        echo "   Comando: cd traffic_tunnel && sudo ./traffic_tunnel tun0 -s 172.31.66.1"
        exit 1
    fi
    
    echo "✓ Interface 'tun0' encontrada e pronta para monitoramento."
    echo ""
    echo "AVISO TÉCNICO IMPORTANTE:"
    echo "O arquivo 'camada2.csv' será criado, mas ficará vazio."
    echo "Isso ocorre porque a interface 'tun0' é de Camada 3 e não possui"
    echo "cabeçalhos Ethernet (MAC addresses)."
    echo ""
    echo "Iniciando monitor de tráfego na interface: tun0"
    echo ""
    echo "Para gerar tráfego de teste:"
    echo "  ping 172.31.66.1"
    echo "  curl --interface tun0 http://example.com"
    echo "  dig @8.8.8.8 google.com"
    echo ""
    echo "Para ver logs em tempo real:"
    echo "  tail -f ../../assets/logs/camada3.csv"
    echo "  tail -f ../../assets/logs/camada4.csv"
    echo ""
    echo "Pressione Ctrl+C para parar o monitor."
    echo ""
    read -p "Pressione Enter para iniciar..."
    
    cd ../../monitor
    sudo python3 monitor.py tun0

elif [ "$ESCOLHA" -eq 4 ]; then
    # OPÇÃO 4: Teste de criação da interface tun0
    echo ""
    echo "--- Teste de Criação da Interface TUN0 ---"
    echo "Este teste irá criar automaticamente o túnel cliente-servidor"
    echo "e verificar se a interface tun0 é criada corretamente."
    echo ""
    read -p "Pressione Enter para executar o teste da tun0..."
    ./teste_tun0.sh

elif [ "$ESCOLHA" -eq 5 ]; then
    # OPÇÃO 5: Demonstrar captura de Camada 2 (interface física)
    echo ""
    echo "--- Demonstração da Captura de Camada 2 ---"
    echo "Interfaces de rede físicas disponíveis:"
    ip -o link show | awk -F': ' '$2 !~ /lo|vir|veth|br|docker|tun/ {print "  " $2}'
    echo ""
    read -p "Digite o nome da interface física para monitorar (ex: wlp0s20f3): " INTERFACE
    
    if ! ip addr show "$INTERFACE" &> /dev/null; then
        echo "Erro: Interface '$INTERFACE' não encontrada."
        exit 1
    fi
    echo "Interface '$INTERFACE' pronta para demonstrar a captura completa."
    echo ""
    echo "Iniciando monitor de tráfego na interface: $INTERFACE"
    echo ""
    echo "Para gerar tráfego de teste:"
    echo "  ping 8.8.8.8"
    echo "  curl http://example.com"
    echo "  dig @8.8.8.8 google.com"
    echo ""
    echo "Para ver logs em tempo real:"
    echo "  tail -f ../../assets/logs/camada2.csv"
    echo "  tail -f ../../assets/logs/camada3.csv"
    echo "  tail -f ../../assets/logs/camada4.csv"
    echo ""
    echo "Pressione Ctrl+C para parar o monitor."
    echo ""
    read -p "Pressione Enter para iniciar..."
    
    cd ../../monitor
    sudo python3 monitor.py "$INTERFACE"

else
    # OPÇÃO 6: Sair do script
    echo "Saindo."
    exit 0
fi

# Chama a função de limpeza para fechar todos os processos.
cleanup 