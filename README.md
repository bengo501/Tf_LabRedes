# Monitor de Tráfego de Rede em Tempo Real

Este projeto implementa um monitor de tráfego de rede em tempo real usando raw sockets, conforme especificado no trabalho final de Laboratório de Redes de Computadores.

## Funcionalidades
- Captura pacotes em qualquer interface de rede (física ou virtual)
- Detecta automaticamente o tipo de interface (física com Ethernet ou virtual TUN)
- Exibe contadores em tempo real por protocolo
- Gera logs em CSV para as camadas 2, 3 e 4 (camada2.csv, camada3.csv, camada4.csv)
- Logs podem ser visualizados a qualquer momento com `cat logs/camadaX.csv`

## Como usar

### 1. Execução Básica
```bash
# Monitorar interface padrão (tun0)
sudo python3 monitor.py

# Monitorar interface específica
sudo python3 monitor.py eth0
sudo python3 monitor.py wlan0
sudo python3 monitor.py tun0
```

### 2. Configuração do Túnel (Opcional)
Se você quiser usar o túnel fornecido:

```bash
# Compilar o túnel
cd traffic_tunnel
make

# Executar servidor do túnel
sudo ./traffic_tunnel <interface_fisica> -s <ip_servidor>

# Em outro terminal, executar cliente
sudo ./traffic_tunnel <interface_fisica> -c <ip_cliente> -t
```

### 3. Visualizar Logs
```bash
# Ver logs em tempo real
tail -f logs/camada2.csv  # Apenas para interfaces físicas
tail -f logs/camada3.csv
tail -f logs/camada4.csv

# Ver logs completos
cat logs/camada2.csv
cat logs/camada3.csv
cat logs/camada4.csv
```

## Estrutura dos logs

### Camada 2 (Ethernet) - Apenas interfaces físicas
- **camada2.csv**: DataHora, MAC_Origem, MAC_Destino, EtherType, Tamanho

### Camada 3 (Rede)
- **camada3.csv**: DataHora, Protocolo, IP_Origem, IP_Destino, Protocolo_Num, Tamanho

### Camada 4 (Transporte)
- **camada4.csv**: DataHora, Protocolo, IP_Origem, Porta_Origem, IP_Destino, Porta_Destino, Tamanho

## Tipos de Interface Suportados

### Interfaces Físicas (eth0, wlan0, etc.)
- Captura cabeçalhos Ethernet (camada 2)
- Gera logs completos para camadas 2, 3 e 4
- Suporta protocolos: IPv4, ARP, TCP, UDP, ICMP

### Interfaces Virtuais (tun0, etc.)
- Captura diretamente pacotes IP (camada 3)
- Gera logs para camadas 3 e 4
- Suporta protocolos: IPv4, TCP, UDP, ICMP

## Observações
- O monitor deve ser executado como root (sudo) para acesso ao raw socket
- O código não depende de bibliotecas externas além da biblioteca padrão do Python
- Para interromper, pressione Ctrl+C
- O monitor detecta automaticamente o tipo de interface e ajusta o parsing

## Exemplos de Uso

### Monitorar tráfego da interface física
```bash
sudo python3 monitor.py eth0
```

### Monitorar tráfego do túnel
```bash
sudo python3 monitor.py tun0
```

### Gerar tráfego para teste
```bash
# Ping para gerar tráfego ICMP
ping 8.8.8.8

# HTTP para gerar tráfego TCP
curl http://example.com

# DNS para gerar tráfego UDP
nslookup google.com
```

## Autores
- [Nomes dos integrantes aqui] 