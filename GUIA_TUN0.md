# Guia para Resolver Problemas com a Interface TUN0

## Problema Identificado

O monitor está sendo executado na interface Wi-Fi (`wlp0s20f3`) em vez da interface `tun0` conforme especificado no enunciado do trabalho.

## Causa do Problema

A interface `tun0` só existe quando o túnel cliente-servidor está ativo. Se o túnel não foi estabelecido, o monitor automaticamente usa a interface de rede principal como fallback.

## Soluções

### Solução 1: Teste Automático da TUN0 (Recomendado)

Execute o script de teste específico para a `tun0`:

```bash
sudo ./teste_tun0.sh
```

Este script irá:
1. Verificar se a `tun0` existe
2. Compilar o túnel se necessário
3. Iniciar o servidor
4. Conectar o cliente
5. Verificar se a `tun0` foi criada
6. Testar conectividade

### Solução 2: Demonstração Completa com TUN0

Execute o script de demonstração que garante o uso da `tun0`:

```bash
sudo ./demo_live_tun0.sh
```

Este script irá:
1. Estabelecer o túnel completo
2. Abrir o monitor especificamente na `tun0`
3. Gerar tráfego através do túnel
4. Mostrar os resultados em tempo real

### Solução 3: Teste Rápido com Opção Específica

Execute o teste rápido e escolha a opção 2:

```bash
sudo ./teste_rapido.sh
```

Depois escolha:
- **Opção 2**: Testar criação da interface tun0

### Solução 4: Manual (Para Entendimento)

Se quiser entender o processo manualmente:

#### Terminal 1 - Servidor:
```bash
cd traffic_tunnel
sudo ./traffic_tunnel tun0 -s 172.31.66.1
```

#### Terminal 2 - Configurar Servidor:
```bash
cd traffic_tunnel
sudo ./server.sh
```

#### Terminal 3 - Cliente:
```bash
cd traffic_tunnel
sudo ./traffic_tunnel tun0 -c 172.31.66.101 -t client1.sh
```

#### Terminal 4 - Monitor:
```bash
sudo python3 monitor.py tun0
```

## Verificação

Para verificar se a `tun0` está ativa:

```bash
ip addr show tun0
```

Se a interface existe, você verá algo como:
```
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1472 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none 
    inet 172.31.66.1/24 scope global tun0
       valid_lft forever preferred_lft forever
```

## Diferenças Técnicas

### Interface Física (wlp0s20f3):
- ✅ Tem cabeçalhos de Camada 2 (MAC addresses)
- ✅ Log `camada2.csv` será preenchido
- ❌ Não é o cenário do enunciado

### Interface TUN0:
- ✅ É o cenário oficial do trabalho
- ✅ Captura tráfego do túnel VPN
- ⚠️ Log `camada2.csv` ficará vazio (técnicamente correto)
- ✅ Logs `camada3.csv` e `camada4.csv` funcionam normalmente

## Recomendação para Apresentação

1. **Primeiro**: Execute `sudo ./teste_tun0.sh` para garantir que o túnel funciona
2. **Depois**: Execute `sudo ./demo_live_tun0.sh` para a demonstração completa
3. **Alternativa**: Use `sudo ./teste_rapido.sh` e escolha a opção 1

Isso garantirá que você está demonstrando exatamente o que foi pedido no enunciado: monitoramento da interface `tun0` do túnel cliente-servidor. 