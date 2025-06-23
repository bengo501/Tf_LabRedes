#!/bin/bash

# ==============================================================================
# Script de Teste Rápido e Guiado
#
# Funcionalidade:
# Este script funciona como um menu interativo para guiar o usuário através
# dos diferentes cenários de teste do projeto. É a principal ferramenta de
# teste manual, oferecendo opções claras e instruções para cada passo.
#
# Propósito:
# Ideal para demonstrações passo a passo e para o usuário final, pois permite
# escolher qual cenário testar (o oficial do trabalho, teste de Camada 2, etc.)
# e fornece o contexto necessário para cada opção.
#
# Autor: Bernardo Klein Heitz
# Data: 2025-06-23
# ==============================================================================

echo "--- TESTE RÁPIDO - MONITOR DE TRÁFEGO (FOCO: ENUNCIADO) ---"
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

echo "Verificações iniciais concluídas."
echo ""

# --- Menu de Opções ---
# Apresenta um menu de opções para o usuário escolher o que deseja fazer.
echo "Este script ajuda a testar o projeto conforme o enunciado."
echo "Por favor, escolha uma opção:"
echo "  1) Executar o cenário oficial do trabalho (monitorar tun0)"
echo "  2) Testar criação da interface tun0 (novo)"
echo "  3) Teste completo em máquina única (ver guia)"
echo "  4) Demonstrar a captura de Camada 2 (monitorar interface física)"
echo "  5) Sair"
echo ""
# Lê a escolha do usuário. Se nada for digitado, o padrão é '1'.
read -p "Sua escolha [1]: " ESCOLHA
ESCOLHA=${ESCOLHA:-1}

# Cria o diretório de logs se ele não existir.
mkdir -p logs

# --- Lógica do Script ---
# O script age de acordo com a escolha do usuário.
if [ "$ESCOLHA" -eq 1 ]; then
    # OPÇÃO 1: Cenário oficial do trabalho.
    # Esta é a principal forma de teste, focada no requisito da interface tun0.
    echo ""
    echo "--- Cenário Oficial do Trabalho: Monitorando tun0 ---"
    
    # Verifica se a interface tun0 já foi criada pelo servidor do túnel.
    if ! ip addr show tun0 &> /dev/null; then
        echo "Erro: Interface 'tun0' não encontrada."
        echo "   Por favor, certifique-se de que o servidor do túnel está"
        echo "   rodando em outro terminal antes de executar este script."
        echo "   Comando: cd traffic_tunnel && sudo ./traffic_tunnel <if> -s <ip>"
        echo ""
        echo "   Ou execute a opção 2 para testar a criação da tun0 automaticamente."
        exit 1
    fi
    
    INTERFACE="tun0"
    echo "Interface '$INTERFACE' encontrada e pronta para monitoramento."
    echo ""
    echo "AVISO TÉCNICO IMPORTANTE:"
    echo "O arquivo 'camada2.csv' será criado, mas ficará vazio."
    echo "Isso ocorre porque a interface 'tun0' é de Camada 3 e não possui"
    echo "cabeçalhos Ethernet (MAC addresses)."
    echo ""

elif [ "$ESCOLHA" -eq 2 ]; then
    # OPÇÃO 2: Testar criação da interface tun0.
    echo ""
    echo "--- Testando Criação da Interface TUN0 ---"
    echo "Este teste irá criar automaticamente o túnel cliente-servidor"
    echo "e verificar se a interface tun0 é criada corretamente."
    echo ""
    read -p "Pressione Enter para executar o teste da tun0..."
    ./teste_tun0.sh
    exit 0

elif [ "$ESCOLHA" -eq 3 ]; then
    # OPÇÃO 3: Fornece as instruções para o teste manual completo.
    # Útil para guiar o usuário na simulação de cliente/servidor.
    echo ""
    echo "--- Guia para Teste Completo em Máquina Única ---"
    echo "Este teste simula a arquitetura completa usando 4 terminais."
    echo ""
    # Mostra o conteúdo do guia detalhado.
    cat GUIA_MAQUINA_UNICA.md
    echo ""
    echo "Pressione Enter para sair..."
    read
    exit 0

elif [ "$ESCOLHA" -eq 4 ]; then
    # OPÇÃO 4: Cenário para demonstrar a funcionalidade de captura da Camada 2.
    # Prova que o código é capaz de lidar com logs de camada 2, embora não
    # seja o foco principal do trabalho.
    echo ""
    echo "--- Demonstração da Captura de Camada 2 ---"
    echo "Interfaces de rede físicas disponíveis:"
    # Lista apenas interfaces que não são de loopback, virtuais, etc.
    ip -o link show | awk -F': ' '$2 !~ /lo|vir|veth|br|docker|tun/ {print "  " $2}'
    echo ""
    read -p "Digite o nome da interface física para monitorar (ex: wlp0s20f3): " INTERFACE
    
    if ! ip addr show "$INTERFACE" &> /dev/null; then
        echo "Erro: Interface '$INTERFACE' não encontrada."
        exit 1
    fi
    echo "Interface '$INTERFACE' pronta para demonstrar a captura completa."
    echo ""

else
    # OPÇÃO 5: Sair do script.
    echo "Saindo."
    exit 0
fi

# --- Bloco de Execução ---
# Apenas as opções 1 e 4 (que de fato iniciam o monitor) entram neste bloco.
if [ "$ESCOLHA" -eq 1 ] || [ "$ESCOLHA" -eq 4 ]; then
    echo "Iniciando monitor de tráfego na interface: $INTERFACE"
    echo ""
    echo "Em outro terminal, gere tráfego:"
    if [ "$ESCOLHA" -eq 1 ]; then
        # Instrução específica para o cenário tun0.
        echo "   - Para tun0, gere tráfego no CLIENTE do túnel."
    else
        # Instrução genérica para interfaces físicas.
        echo "   - Para interface física, gere tráfego normalmente (ping 8.8.8.8, etc)."
    fi
    echo ""
    echo "Para ver logs em tempo real:"
    echo "   tail -f logs/camada3.csv"
    echo "   tail -f logs/camada4.csv"
    echo ""
    echo "Pressione Ctrl+C para parar o monitor."
    echo ""
    echo "Pressione Enter para iniciar..."
    read

    # Executa o monitor com a interface selecionada.
    sudo python3 monitor.py "$INTERFACE" 