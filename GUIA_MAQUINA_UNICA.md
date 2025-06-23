# Guia de Teste - Máquina Única (Múltiplos Terminais)

Este guia permite testar o projeto completo usando apenas uma máquina Linux com múltiplos terminais, simulando a arquitetura de túnel descrita no enunciado.

## 🎯 **Objetivo**
Simular a arquitetura completa onde:
- **Terminal 1**: Servidor proxy (recebe tráfego encapsulado)
- **Terminal 2**: Monitor de tráfego (captura na tun0)
- **Terminal 3**: Cliente (gera tráfego encapsulado)
- **Terminal 4**: Visualização de logs

## 📋 **Pré-requisitos**
- Sistema Linux com Python 3
- Privilégios de root (sudo)
- Interface de rede ativa (Wi-Fi ou Ethernet)
- 4 terminais abertos

## 🚀 **Passo a Passo Detalhado**

### **Passo 1: Preparação**
Abra **4 terminais** e navegue para o diretório do projeto em todos:
```bash
cd /home/bernardo/Downloads/Tf_LabRedes-BernardoKleinHeitz
```

### **Passo 2: Terminal 1 - Servidor Proxy**
```bash
# Navegar para o túnel
cd traffic_tunnel

# Compilar (se necessário)
make

# Executar servidor proxy
# Substitua 'wlp0s20f3' pela sua interface e '192.168.0.15' pelo seu IP
sudo ./traffic_tunnel wlp0s20f3 -s 192.168.0.15
```

**O que acontece:**
- Cria interface `tun0` com IP `172.31.66.1`
- Aguarda tráfego encapsulado dos clientes
- **DEIXE ESTE TERMINAL ABERTO**

### **Passo 3: Terminal 2 - Verificar Interface**
```bash
# Verificar se tun0 foi criada
ip addr show tun0

# Deve mostrar algo como:
# 31: tun0: <POINTOPOINT,MULTICAST,NOARP,UP> mtu 1472 qdisc fq_codel state UNKNOWN
#     inet 172.31.66.1/24 scope global tun0
```

### **Passo 4: Terminal 2 - Monitor de Tráfego**
```bash
# Navegar de volta ao diretório principal
cd /home/bernardo/Downloads/Tf_LabRedes-BernardoKleinHeitz

# Executar monitor na interface obrigatória
sudo python3 monitor.py tun0
```

**O que acontece:**
- Monitor detecta interface `tun` automaticamente
- Aguarda pacotes na interface `tun0`
- **DEIXE ESTE TERMINAL ABERTO**

### **Passo 5: Terminal 3 - Cliente Túnel**
```bash
# Navegar para o túnel
cd traffic_tunnel

# Executar cliente túnel
# Use um IP diferente do servidor na mesma rede
sudo ./traffic_tunnel wlp0s20f3 -c 192.168.0.16 -t
```

**O que acontece:**
- Cria interface `tun1` com IP `172.31.66.101`
- Roteia tráfego através do túnel
- **DEIXE ESTE TERMINAL ABERTO**

### **Passo 6: Terminal 4 - Gerar Tráfego**
```bash
# Gerar tráfego que passará pelo túnel
ping -c 5 8.8.8.8
curl http://example.com
nslookup google.com
```

**O que acontece:**
- Tráfego é encapsulado pelo cliente
- Enviado para o servidor via túnel
- Desencapsulado e aparece na `tun0`
- Monitor captura e registra nos logs

### **Passo 7: Terminal 4 - Visualizar Logs**
```bash
# Ver logs em tempo real
tail -f logs/camada3.csv
tail -f logs/camada4.csv

# Ver logs completos
cat logs/camada3.csv
cat logs/camada4.csv

# Verificar camada2.csv (deve estar vazio)
cat logs/camada2.csv
```

## 📊 **Resultados Esperados**

### **Terminal 2 (Monitor):**
```
=== MONITOR DE TRÁFEGO DE REDE EM TEMPO REAL ===
Contadores de Pacotes por Protocolo:
----------------------------------------
IPv4    :    25
IPv6    :      0
ARP     :      0
TCP     :    18
UDP     :     5
ICMP    :     2
Outros  :      0
```

### **Logs Esperados:**
- **camada3.csv**: Pacotes IPv4 com IPs `172.31.66.101` → `8.8.8.8`
- **camada4.csv**: Conexões TCP (porta 80/443), ICMP (ping), UDP (DNS)
- **camada2.csv**: Apenas cabeçalho (vazio, como esperado para tun0)

## 🔧 **Comandos Úteis para Debug**

### **Verificar Interfaces:**
```bash
ip addr show | grep -A 5 tun
```

### **Verificar Roteamento:**
```bash
ip route show
```

### **Verificar Processos:**
```bash
ps aux | grep traffic_tunnel
ps aux | grep monitor
```

### **Limpar e Reiniciar:**
```bash
# Parar todos os processos
sudo pkill traffic_tunnel
sudo pkill -f monitor.py

# Limpar logs (opcional)
rm -f logs/camada*.csv
```

## ⚠️ **Possíveis Problemas e Soluções**

### **Problema: "Interface tun0 não encontrada"**
**Solução:** Certifique-se de que o Terminal 1 (servidor) está rodando antes do Terminal 2 (monitor).

### **Problema: "Permission denied"**
**Solução:** Execute todos os comandos com `sudo`.

### **Problema: "Nenhum tráfego capturado"**
**Solução:** 
1. Verifique se o cliente (Terminal 3) está rodando
2. Gere tráfego no Terminal 4
3. Verifique se as interfaces tun estão ativas

### **Problema: "Erro de rede"**
**Solução:** Use uma interface física diferente ou verifique a conectividade de rede.

## 🎯 **Checklist de Sucesso**

- [ ] Terminal 1: Servidor túnel rodando sem erros
- [ ] Terminal 2: Interface tun0 criada e ativa
- [ ] Terminal 2: Monitor capturando pacotes
- [ ] Terminal 3: Cliente túnel rodando
- [ ] Terminal 4: Tráfego sendo gerado
- [ ] Terminal 4: Logs sendo preenchidos
- [ ] Contadores aumentando no monitor
- [ ] Logs mostrando IPs corretos (172.31.66.xxx)

## 📸 **Para Apresentação**

1. **Mostre o Terminal 1** com o servidor túnel rodando
2. **Mostre o Terminal 2** com o monitor e contadores subindo
3. **Mostre o Terminal 3** com o cliente túnel
4. **Mostre o Terminal 4** com logs sendo preenchidos
5. **Explique** que está simulando a arquitetura completa em uma máquina

**Sucesso!** 🎉 Você está testando exatamente o cenário descrito no enunciado.
