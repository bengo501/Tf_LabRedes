#!/bin/bash

# ==============================================================================
# Script de Teste Completo e Automatizado
#
# Funcionalidade:
# Este script executa um teste de ponta a ponta e totalmente automatizado
# da arquitetura de túnel em uma única máquina. Ele simula o servidor,
# o cliente e o monitor, tudo em background, e apresenta um relatório final.
#
# Propósito:
# Ideal para uma verificação rápida e completa (smoke test) para garantir
# que todos os componentes do sistema estão funcionando corretamente sem
# a necessidade de interação manual ou múltiplos terminais.
#
# Autor: Bernardo Klein Heitz
# Data: 2025-06-23
# ==============================================================================

echo "--- TESTE COMPLETO - MÁQUINA ÚNICA ---"
echo ""

# --- Verificações Iniciais ---
# Garante que o script seja executado com privilégios de root.
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script precisa ser executado com sudo."
    exit 1
fi

# Garante que o Python 3, necessário para o monitor, esteja instalado.
if ! command -v python3 &> /dev/null; then
    echo "Erro: Python 3 não está instalado."
    exit 1
fi

echo "Verificações iniciais concluídas."
echo ""

# --- Configuração de Rede ---
# Detecta automaticamente a interface de rede principal e seu endereço IP.
echo "Detectando interface de rede..."
INTERFACE_FISICA=$(ip route | grep default | awk '{print $5}' | head -1)
IP_SERVIDOR=$(ip addr show $INTERFACE_FISICA | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

# Valida se a detecção de rede foi bem-sucedida.
if [ -z "$INTERFACE_FISICA" ] || [ -z "$IP_SERVIDOR" ]; then
    echo "Erro: Não foi possível detectar interface de rede ou IP automaticamente."
    echo "   Interface detectada: $INTERFACE_FISICA"
    echo "   IP detectado: $IP_SERVIDOR"
    exit 1
fi

echo "Interface física: $INTERFACE_FISICA"
echo "IP do servidor: $IP_SERVIDOR"
echo ""

# Cria o diretório de logs se ele não existir.
mkdir -p logs

echo "--- INICIANDO TESTE COMPLETO ---"
echo ""
echo "Este script irá:"
echo "1. Compilar o túnel"
echo "2. Iniciar o servidor túnel em background"
echo "3. Aguardar a criação da interface tun0"
echo "4. Iniciar o monitor de tráfego em background"
echo "5. Iniciar o cliente túnel em background"
echo "6. Gerar tráfego de teste"
echo "7. Apresentar um resumo dos resultados"
echo ""
echo "ATENÇÃO: Este processo pode demorar alguns segundos."
echo "Pressione Ctrl+C a qualquer momento para parar todos os processos."
echo ""
read -p "Pressione Enter para continuar..."

# --- Funções e Comandos Principais ---
# Função de limpeza para encerrar todos os processos em background de forma organizada.
cleanup() {
    echo ""
    echo "Limpando processos..."
    # Usa pkill para encontrar e matar os processos pelo nome.
    sudo pkill -f traffic_tunnel 2>/dev/null
    sudo pkill -f monitor.py 2>/dev/null
    echo "Processos encerrados."
    exit 0
}

# Garante que a função de limpeza seja chamada se o script for interrompido (Ctrl+C).
trap cleanup SIGINT

# Passo 1: Compilar túnel
echo "Compilando túnel..."
cd traffic_tunnel
# Oculta a saída do 'make' para uma interface mais limpa.
if ! make > /dev/null 2>&1; then
    echo "Erro ao compilar o túnel."
    exit 1
fi
echo "Túnel compilado com sucesso."

# Passo 2: Iniciar servidor túnel em background
echo "Iniciando servidor túnel..."
# O '&' no final executa o comando em background, permitindo que o script continue.
sudo ./traffic_tunnel $INTERFACE_FISICA -s $IP_SERVIDOR > /dev/null 2>&1 &
TUNNEL_PID=$!
echo "Servidor túnel iniciado (PID: $TUNNEL_PID)."

# Passo 3: Aguardar criação da interface tun0
echo "Aguardando criação da interface tun0..."
# O script aguarda em um loop por até 10 segundos pela criação da interface tun0.
for i in {1..10}; do
    if ip addr show tun0 > /dev/null 2>&1; then
        echo "Interface tun0 criada."
        break
    fi
    # Se a interface não aparecer após 10 segundos, o script falha.
    if [ $i -eq 10 ]; then
        echo "Erro: Interface tun0 não foi criada."
        cleanup
    fi
    sleep 1
done

# Passo 4: Iniciar monitor em background
echo "Iniciando monitor de tráfego..."
cd ..
# Inicia o monitor na interface tun0, também em background.
sudo python3 monitor.py tun0 > /dev/null 2>&1 &
MONITOR_PID=$!
echo "Monitor iniciado (PID: $MONITOR_PID)."

# Pausa para garantir que o monitor esteja pronto para receber pacotes.
sleep 2

# Passo 5: Iniciar cliente túnel em background
echo "Iniciando cliente túnel..."
cd traffic_tunnel
# Gera um IP de cliente simples para o teste.
IP_CLIENTE=$(echo $IP_SERVIDOR | awk -F. '{print $1"."$2"."$3"."($4+1)}')
# Inicia o cliente do túnel para gerar tráfego através do servidor.
sudo ./traffic_tunnel $INTERFACE_FISICA -c $IP_CLIENTE -t > /dev/null 2>&1 &
CLIENT_PID=$!
echo "Cliente túnel iniciado (PID: $CLIENT_PID)."

# Pausa para garantir que o túnel cliente-servidor esteja estabelecido.
sleep 3

# Passo 6: Gerar tráfego de teste
echo "Gerando tráfego de teste..."
cd ..
echo "   - Ping para 8.8.8.8..."
ping -c 3 8.8.8.8 > /dev/null 2>&1
echo "   - Ping concluído."
echo "   - HTTP para example.com..."
curl -s http://example.com > /dev/null 2>&1
echo "   - HTTP concluído."

# Passo 7: Mostrar resultados
echo ""
echo "--- RESULTADOS DO TESTE ---"
echo "==========================="

# Apresenta um resumo dos resultados do teste.
echo "Contadores de pacotes:"
if [ -f logs/camada3.csv ]; then
    # Conta as linhas do log para dar uma estimativa do tráfego.
    TOTAL_PACOTES=$(wc -l < logs/camada3.csv)
    TOTAL_PACOTES=$((TOTAL_PACOTES - 1))  # Subtrai a linha do cabeçalho.
    echo "   Total de pacotes IPv4 capturados: $TOTAL_PACOTES"
else
    echo "   Nenhum pacote capturado."
fi

# Apresenta a contagem de linhas de cada arquivo de log.
echo ""
echo "Logs gerados:"
echo "   - Camada 3 (IP): $(wc -l < logs/camada3.csv 2>/dev/null || echo 0) linhas"
echo "   - Camada 4 (Transporte): $(wc -l < logs/camada4.csv 2>/dev/null || echo 0) linhas"
echo "   - Camada 2 (Ethernet): $(wc -l < logs/camada2.csv 2>/dev/null || echo 0) linhas (deve ser 1 para tun0)"

# Mostra as últimas linhas dos logs para uma verificação rápida.
echo ""
echo "Últimos registros capturados:"
echo "   Camada 3:"
tail -3 logs/camada3.csv 2>/dev/null || echo "     Nenhum registro"
echo "   Camada 4:"
tail -3 logs/camada4.csv 2>/dev/null || echo "     Nenhum registro"

echo ""
echo "--- TESTE CONCLUÍDO COM SUCESSO! ---"
echo ""
echo "Para ver logs em tempo real, execute:"
echo "   tail -f logs/camada3.csv"
echo "   tail -f logs/camada4.csv"
echo ""
# Pausa o script no final para que o usuário possa ler os resultados.
read -p "Pressione Enter para encerrar e limpar os processos..."

# Limpa todos os processos iniciados em background.
cleanup 