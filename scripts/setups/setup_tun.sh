#!/bin/bash

# ==============================================================================
# Script de Configuração do Dispositivo TUN
#
# Funcionalidade:
# Este script configura o dispositivo /dev/tun necessário para criar
# interfaces tun0, tun1, etc. Resolve problemas de "Device or resource busy"
# e permissões.
#
# ==============================================================================

echo "--- CONFIGURAÇÃO DO DISPOSITIVO TUN ---"
echo ""

# --- Verificações Iniciais ---
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script precisa ser executado com sudo."
    exit 1
fi

echo "Verificando e configurando o dispositivo TUN..."
echo ""

# --- Passo 1: Verificar se o módulo tun está carregado ---
echo "Passo 1: Verificando módulo TUN..."
if ! lsmod | grep -q "^tun"; then
    echo "Módulo TUN não está carregado. Carregando..."
    modprobe tun
    if [ $? -eq 0 ]; then
        echo "✓ Módulo TUN carregado com sucesso"
    else
        echo "❌ Erro ao carregar módulo TUN"
        exit 1
    fi
else
    echo "✓ Módulo TUN já está carregado"
fi

# --- Passo 2: Verificar se /dev/tun existe ---
echo ""
echo "Passo 2: Verificando dispositivo /dev/tun..."
if [ ! -e "/dev/tun" ]; then
    echo "Dispositivo /dev/tun não existe. Criando..."
    mknod /dev/tun c 10 200
    chmod 600 /dev/tun
    chown root:root /dev/tun
    echo "✓ Dispositivo /dev/tun criado"
else
    echo "✓ Dispositivo /dev/tun já existe"
fi

# --- Passo 3: Verificar permissões do /dev/tun ---
echo ""
echo "Passo 3: Verificando permissões do /dev/tun..."
ls -la /dev/tun

# --- Passo 4: Limpar interfaces tun existentes ---
echo ""
echo "Passo 4: Limpando interfaces TUN existentes..."
for i in {0..9}; do
    if ip link show tun$i > /dev/null 2>&1; then
        echo "Removendo interface tun$i..."
        ip link delete tun$i 2>/dev/null
    fi
done

# --- Passo 5: Verificar se há processos usando TUN ---
echo ""
echo "Passo 5: Verificando processos que usam TUN..."
ps aux | grep -E "(tun|traffic_tunnel)" | grep -v grep

# --- Passo 6: Testar criação de interface ---
echo ""
echo "Passo 6: Testando criação de interface tun0..."
ip tuntap add mode tun tun0
if [ $? -eq 0 ]; then
    echo "✓ Interface tun0 criada com sucesso"
    ip link delete tun0
    echo "✓ Interface tun0 removida (teste concluído)"
else
    echo "❌ Erro ao criar interface tun0"
    exit 1
fi

echo ""
echo "=== CONFIGURAÇÃO CONCLUÍDA ==="
echo "✓ Dispositivo TUN configurado corretamente"
echo "✓ Módulo TUN carregado"
echo "✓ Permissões verificadas"
echo "✓ Interfaces antigas removidas"
echo ""
echo "Agora você pode executar o túnel sem problemas!"
echo "Use: sudo ./teste_tun0.sh"
echo "" 