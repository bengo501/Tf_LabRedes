#!/bin/bash

# ==============================================================================
# Script de Demonstração ao Vivo
#
# Funcionalidade:
# Este script foi projetado para uma demonstração visual e em tempo real.
# Ele abre uma nova janela de terminal para rodar o monitor e, no terminal
# original, gera diferentes tipos de tráfego (ICMP, TCP, UDP).
#
# Propósito:
# Perfeito para apresentações, pois permite que a audiência veja a causa
# (geração de tráfego) e o efeito (contadores do monitor subindo)
# simultaneamente em duas janelas lado a lado.
#
# Autor: Bernardo Klein Heitz
# Data: 2025-06-23
# ==============================================================================

echo "--- DEMONSTRAÇÃO AO VIVO ---"
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

# Detecta a interface de rede padrão para garantir que o tráfego possa ser gerado.
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -z "$INTERFACE" ]; then
    echo "Erro: Não foi possível detectar a interface de rede ativa."
    exit 1
fi
echo "O monitor será executado na interface ativa: $INTERFACE"

# Verifica a existência do 'gnome-terminal' para poder abrir uma nova janela.
if ! command -v gnome-terminal &> /dev/null; then
    echo "Erro: 'gnome-terminal' não encontrado."
    echo "Este script de demonstração precisa do gnome-terminal para abrir"
    echo "uma nova janela para o monitor."
    exit 1
fi

echo ""
read -p "Pressione Enter para iniciar a demonstração..."
echo ""

# --- Lógica da Demonstração ---

# Função para garantir que o monitor seja encerrado ao final.
cleanup() {
    echo ""
    echo "Encerrando o processo do monitor..."
    # Mata o processo do monitor usando pkill para buscar pelo comando python3.
    sudo pkill -f "python3 monitor.py"
    echo "Demonstração finalizada."
    exit
}

# Garante que a limpeza seja chamada se o script for interrompido.
trap cleanup SIGINT

# Executa o monitor em uma nova janela de terminal.
echo "Abrindo um NOVO TERMINAL para o monitor de tráfego..."
gnome-terminal -- sudo python3 monitor.py "$INTERFACE"

# Pausa o script por 3 segundos para dar tempo ao monitor de inicializar na outra janela.
echo "Aguardando 3 segundos para o monitor inicializar..."
sleep 3
echo ""

# Bloco principal onde o tráfego é gerado sequencialmente.
echo "No terminal original, vamos gerar tráfego."
echo "Observe os contadores subindo no outro terminal."
echo ""
echo "Pressione Enter para começar a gerar tráfego..."
read

# Gera tráfego ICMP (ping).
echo "1. Gerando tráfego ICMP (ping)..."
ping -c 5 google.com

# Gera tráfego TCP (HTTP).
echo ""
echo "2. Gerando tráfego TCP (HTTP)..."
curl http://example.com

# Gera tráfego UDP (DNS).
echo ""
echo "3. Gerando tráfego UDP (DNS)..."
# O comando 'dig' (ou 'nslookup') envia uma consulta DNS usando UDP.
dig @8.8.8.8 google.com

echo ""
echo "Demonstração de tráfego concluída."
echo ""
# Pausa no final para permitir que o usuário analise a saída do monitor.
read -p "Pressione Enter para encerrar o monitor e finalizar a demonstração..."

# Chama a função de limpeza para fechar o processo do monitor.
cleanup 