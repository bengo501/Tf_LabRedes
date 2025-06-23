#!/bin/bash

# Script para demonstração ao vivo com dois terminais.
# Um para o monitor, outro para gerar tráfego.

echo "--- DEMONSTRAÇÃO AO VIVO ---"
echo "Este script abrirá uma nova janela de terminal para o monitor."
echo ""

# Verificar se está executando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Erro: Este script precisa ser executado com sudo."
    exit 1
fi

# Detectar interface de rede ativa para garantir que haja tráfego
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -z "$INTERFACE" ]; then
    echo "❌ Erro: Não foi possível detectar a interface de rede ativa."
    echo "   Por favor, execute o monitor manualmente: sudo python3 monitor.py <interface>"
    exit 1
fi
echo "✅ O monitor será executado na interface ativa: $INTERFACE"
echo ""

# Verificar se o gnome-terminal está disponível
if ! command -v gnome-terminal &> /dev/null; then
    echo "❌ 'gnome-terminal' não encontrado. Não é possível abrir um novo terminal."
    echo "   Por favor, abra dois terminais manualmente e siga as instruções:"
    echo "   Terminal 1: sudo python3 monitor.py $INTERFACE"
    echo "   Terminal 2: ping 8.8.8.8"
    exit 1
fi

# Limpar logs antigos para uma demonstração limpa
rm -f logs/camada*.csv

echo "🚀 Abrindo um NOVO TERMINAL para o monitor de tráfego..."
echo "   Por favor, posicione as janelas lado a lado para melhor visualização."
echo "   Pode ser necessário digitar a senha sudo no novo terminal."
echo ""

# Abrir o monitor em um novo terminal. O & o coloca em background.
gnome-terminal -- sudo python3 monitor.py "$INTERFACE"

# Dar tempo para a nova janela abrir e o monitor iniciar
echo "⏳ Aguardando 3 segundos para o monitor inicializar..."
sleep 3
echo ""

# --- Início da Geração de Tráfego ---
echo "--- GERANDO TRÁFEGO (NESTE TERMINAL) ---"
echo "Observe a janela do monitor enquanto o tráfego é gerado."
echo "================================================="
echo ""

# Gerar tráfego ICMP (ping)
echo "🌐 1. Gerando tráfego ICMP (ping)..."
ping -c 4 8.8.8.8
echo ""

# Gerar tráfego TCP (HTTP)
echo "🌐 2. Gerando tráfego TCP (HTTP)..."
curl -s http://example.com > /dev/null
echo "   (Conexão com http://example.com estabelecida)"
echo ""

# Gerar tráfego UDP (DNS)
echo "🌐 3. Gerando tráfego UDP (DNS)..."
nslookup google.com > /dev/null
echo "   (Consulta DNS para google.com realizada)"
echo ""

echo "================================================="
echo "🎉 Demonstração de tráfego concluída."
echo ""
echo "A janela do monitor continuará rodando para análise."
read -p "Pressione Enter aqui para finalizar este script e fechar a janela do monitor..."

# Encerrar o monitor que está rodando em outro processo
sudo pkill -f "python3 monitor.py"

echo "✅ Demonstração finalizada." 