#!/bin/bash

# Script de Teste Completo - Máquina Única
# Autor: Bernardo Klein Heitz
# Data: 2025-06-23

echo "=== TESTE COMPLETO - MÁQUINA ÚNICA ==="
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

# Obter informações da interface de rede
echo "📡 Detectando interface de rede..."
INTERFACE_FISICA=$(ip route | grep default | awk '{print $5}' | head -1)
IP_SERVIDOR=$(ip addr show $INTERFACE_FISICA | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

if [ -z "$INTERFACE_FISICA" ] || [ -z "$IP_SERVIDOR" ]; then
    echo "❌ Erro: Não foi possível detectar interface de rede ou IP automaticamente."
    echo "   Interface detectada: $INTERFACE_FISICA"
    echo "   IP detectado: $IP_SERVIDOR"
    exit 1
fi

echo "✅ Interface física: $INTERFACE_FISICA"
echo "✅ IP do servidor: $IP_SERVIDOR"
echo ""

# Criar diretório de logs
mkdir -p logs

echo "🚀 INICIANDO TESTE COMPLETO..."
echo ""
echo "📋 Este script irá:"
echo "1. Compilar o túnel"
echo "2. Iniciar o servidor túnel"
echo "3. Aguardar criação da interface tun0"
echo "4. Iniciar o monitor de tráfego"
echo "5. Iniciar o cliente túnel"
echo "6. Gerar tráfego de teste"
echo "7. Mostrar logs em tempo real"
echo ""
echo "⚠️  ATENÇÃO: Este processo pode demorar alguns segundos."
echo "   Pressione Ctrl+C a qualquer momento para parar."
echo ""
read -p "Pressione Enter para continuar..."

# Função para limpar processos
cleanup() {
    echo ""
    echo "🧹 Limpando processos..."
    sudo pkill -f traffic_tunnel 2>/dev/null
    sudo pkill -f monitor.py 2>/dev/null
    echo "✅ Processos encerrados."
    exit 0
}

# Capturar Ctrl+C
trap cleanup SIGINT

# Passo 1: Compilar túnel
echo "🔨 Compilando túnel..."
cd traffic_tunnel
if ! make > /dev/null 2>&1; then
    echo "❌ Erro ao compilar o túnel"
    exit 1
fi
echo "✅ Túnel compilado com sucesso"

# Passo 2: Iniciar servidor túnel em background
echo "🚀 Iniciando servidor túnel..."
sudo ./traffic_tunnel $INTERFACE_FISICA -s $IP_SERVIDOR > /dev/null 2>&1 &
TUNNEL_PID=$!
echo "✅ Servidor túnel iniciado (PID: $TUNNEL_PID)"

# Passo 3: Aguardar criação da interface tun0
echo "⏳ Aguardando criação da interface tun0..."
for i in {1..10}; do
    if ip addr show tun0 > /dev/null 2>&1; then
        echo "✅ Interface tun0 criada"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ Erro: Interface tun0 não foi criada"
        cleanup
    fi
    sleep 1
done

# Passo 4: Iniciar monitor em background
echo "📊 Iniciando monitor de tráfego..."
cd ..
sudo python3 monitor.py tun0 > /dev/null 2>&1 &
MONITOR_PID=$!
echo "✅ Monitor iniciado (PID: $MONITOR_PID)"

# Passo 5: Aguardar um pouco para o monitor inicializar
sleep 2

# Passo 6: Iniciar cliente túnel em background
echo "👤 Iniciando cliente túnel..."
cd traffic_tunnel
IP_CLIENTE=$(echo $IP_SERVIDOR | awk -F. '{print $1"."$2"."$3"."($4+1)}')
sudo ./traffic_tunnel $INTERFACE_FISICA -c $IP_CLIENTE -t > /dev/null 2>&1 &
CLIENT_PID=$!
echo "✅ Cliente túnel iniciado (PID: $CLIENT_PID)"

# Passo 7: Aguardar um pouco para o cliente inicializar
sleep 3

# Passo 8: Gerar tráfego de teste
echo "🌐 Gerando tráfego de teste..."
cd ..
echo "   Ping para 8.8.8.8..."
ping -c 3 8.8.8.8 > /dev/null 2>&1
echo "   ✅ Ping concluído"
echo "   HTTP para example.com..."
curl -s http://example.com > /dev/null 2>&1
echo "   ✅ HTTP concluído"

# Passo 9: Mostrar resultados
echo ""
echo "📊 RESULTADOS DO TESTE:"
echo "========================"

# Mostrar contadores do monitor
echo "📈 Contadores de pacotes:"
if [ -f logs/camada3.csv ]; then
    TOTAL_PACOTES=$(wc -l < logs/camada3.csv)
    TOTAL_PACOTES=$((TOTAL_PACOTES - 1))  # Subtrair cabeçalho
    echo "   Total de pacotes capturados: $TOTAL_PACOTES"
else
    echo "   Nenhum pacote capturado"
fi

# Mostrar logs
echo ""
echo "📋 Logs gerados:"
echo "   Camada 3 (IP): $(wc -l < logs/camada3.csv 2>/dev/null || echo 0) linhas"
echo "   Camada 4 (Transporte): $(wc -l < logs/camada4.csv 2>/dev/null || echo 0) linhas"
echo "   Camada 2 (Ethernet): $(wc -l < logs/camada2.csv 2>/dev/null || echo 0) linhas"

# Mostrar últimos registros
echo ""
echo "📝 Últimos registros capturados:"
echo "   Camada 3:"
tail -3 logs/camada3.csv 2>/dev/null || echo "     Nenhum registro"
echo "   Camada 4:"
tail -3 logs/camada4.csv 2>/dev/null || echo "     Nenhum registro"

echo ""
echo "🎉 TESTE CONCLUÍDO COM SUCESSO!"
echo ""
echo "💡 Para ver logs em tempo real, execute:"
echo "   tail -f logs/camada3.csv"
echo "   tail -f logs/camada4.csv"
echo ""
echo "⏹️  Pressione Enter para encerrar..."
read

# Limpar processos
cleanup 