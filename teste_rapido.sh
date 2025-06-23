#!/bin/bash

# Script de Teste Rápido - Focado no Enunciado do Trabalho Final
# Autor: Bernardo Klein Heitz
# Data: 2025-06-23

echo "=== TESTE RÁPIDO - MONITOR DE TRÁFEGO (FOCO: ENUNCIADO) ==="
echo ""

# Verificar se está executando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Erro: Este script precisa ser executado com sudo."
    exit 1
fi

# Verificar se Python 3 está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Erro: Python 3 não está instalado"
    exit 1
fi

echo "✅ Python 3 encontrado"
echo ""

# --- MENU DE OPÇÕES ---
echo "Este script ajuda a testar o projeto conforme o enunciado."
echo "Por favor, escolha uma opção:"
echo "  1) Executar o cenário oficial do trabalho (monitorar tun0)"
echo "  2) Teste completo em máquina única (4 terminais)"
echo "  3) Demonstrar a captura de Camada 2 (monitorar interface física)"
echo "  4) Sair"
echo ""
read -p "Sua escolha [1]: " ESCOLHA
ESCOLHA=${ESCOLHA:-1} # Padrão para 1 se nada for digitado

# Criar diretório de logs se não existir
mkdir -p logs

# --- LÓGICA DO SCRIPT ---
if [ "$ESCOLHA" -eq 1 ]; then
    # Cenário Oficial: tun0
    echo ""
    echo "--- Cenário Oficial do Trabalho: Monitorando tun0 ---"
    
    # Verificar se a interface tun0 existe
    if ! ip addr show tun0 &> /dev/null; then
        echo "❌ Erro: Interface 'tun0' não encontrada."
        echo "   Por favor, certifique-se de que o servidor do túnel está"
        echo "   rodando em outro terminal antes de executar este script."
        echo "   Comando: cd traffic_tunnel && sudo ./traffic_tunnel <if> -s <ip>"
        exit 1
    fi
    
    INTERFACE="tun0"
    echo "✅ Interface '$INTERFACE' encontrada e pronta para monitoramento."
    echo ""
    echo "AVISO TÉCNICO IMPORTANTE:"
    echo "O arquivo 'camada2.csv' será criado, mas ficará vazio."
    echo "Isso ocorre porque a interface 'tun0' é de Camada 3 e não possui"
    echo "cabeçalhos Ethernet (MAC addresses)."
    echo ""

elif [ "$ESCOLHA" -eq 2 ]; then
    # Teste Completo em Máquina Única
    echo ""
    echo "--- Teste Completo em Máquina Única ---"
    echo "Este teste simula a arquitetura completa usando 4 terminais."
    echo ""
    echo "📋 INSTRUÇÕES:"
    echo "1. Abra 4 terminais"
    echo "2. Em cada terminal, navegue para:"
    echo "   cd /home/bernardo/Downloads/Tf_LabRedes-BernardoKleinHeitz"
    echo ""
    echo "3. Terminal 1 (Servidor):"
    echo "   cd traffic_tunnel"
    echo "   sudo ./traffic_tunnel wlp0s20f3 -s 192.168.0.15"
    echo ""
    echo "4. Terminal 2 (Monitor):"
    echo "   sudo python3 monitor.py tun0"
    echo ""
    echo "5. Terminal 3 (Cliente):"
    echo "   cd traffic_tunnel"
    echo "   sudo ./traffic_tunnel wlp0s20f3 -c 192.168.0.16 -t"
    echo ""
    echo "6. Terminal 4 (Tráfego + Logs):"
    echo "   ping 8.8.8.8"
    echo "   tail -f logs/camada3.csv"
    echo ""
    echo "Pressione Enter para ver o guia completo..."
    read
    echo ""
    echo "📖 GUIA COMPLETO:"
    cat GUIA_MAQUINA_UNICA.md
    echo ""
    echo "Pressione Enter para sair..."
    read
    exit 0

elif [ "$ESCOLHA" -eq 3 ]; then
    # Demonstração Camada 2
    echo ""
    echo "--- Demonstração da Captura de Camada 2 ---"
    echo "📡 Interfaces de rede físicas disponíveis:"
    ip -o link show | awk -F': ' '$2 !~ /lo|vir|veth|br|docker|tun/ {print "  " $2}'
    echo ""
    read -p "Digite o nome da interface física para monitorar (ex: wlp0s20f3): " INTERFACE
    
    if ! ip addr show "$INTERFACE" &> /dev/null; then
        echo "❌ Erro: Interface '$INTERFACE' não encontrada."
        exit 1
    fi
    echo "✅ Interface '$INTERFACE' pronta para demonstrar a captura completa."
    echo ""

else
    # Sair
    echo "Saindo."
    exit 0
fi

# --- EXECUÇÃO ---
if [ "$ESCOLHA" -eq 1 ] || [ "$ESCOLHA" -eq 3 ]; then
    echo "🚀 Iniciando monitor de tráfego na interface: $INTERFACE"
    echo ""
    echo "📊 Em outro terminal, gere tráfego:"
    if [ "$ESCOLHA" -eq 1 ]; then
        echo "   - Para tun0, gere tráfego no CLIENTE do túnel."
    else
        echo "   - Para interface física, gere tráfego normalmente (ping 8.8.8.8, etc)."
    fi
    echo ""
    echo "📈 Para ver logs em tempo real:"
    echo "   tail -f logs/camada3.csv"
    echo "   tail -f logs/camada4.csv"
    echo ""
    echo "⏹️  Pressione Ctrl+C para parar o monitor."
    echo ""
    echo "Pressione Enter para iniciar..."
    read

    # Executar o monitor
    sudo python3 monitor.py "$INTERFACE" 