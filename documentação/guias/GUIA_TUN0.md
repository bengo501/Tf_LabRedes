# Guia para Resolver Problemas com a Interface TUN0

## Problema Identificado

O monitor está sendo executado na interface Wi-Fi (`wlp0s20f3`) em vez da interface `tun0` conforme especificado no enunciado do trabalho.

## Causa do Problema

A interface `tun0` só existe quando o túnel cliente-servidor está ativo. Se o túnel não foi estabelecido, o monitor automaticamente usa a interface de rede principal como fallback.

## Erro "Device or resource busy"

Este erro ocorre quando:
1. O dispositivo `/dev/tun` não existe
2. O módulo TUN não está carregado
3. Há processos antigos usando o dispositivo TUN

## Soluções

### Solução 1: Resolução Automática Completa (RECOMENDADO)

Execute o script que resolve tudo automaticamente:

```bash
sudo ./resolver_tun0.sh
```

Este script irá:
1. Configurar o dispositivo TUN
2. Limpar processos antigos
3. Estabelecer o túnel cliente-servidor
4. Executar o monitor na tun0
5. Gerar tráfego de teste
6. Mostrar resultados

### Solução 2: Configuração Manual do TUN

Se o erro "Device or resource busy" persistir:

```bash
sudo ./setup_tun.sh
```

Este script:
1. Carrega o módulo TUN
2. Cria o dispositivo `/dev/tun`
3. Configura permissões
4. Remove interfaces antigas
5. Testa a criação

### Solução 3: Teste Automático da TUN0

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

### Solução 4: Demonstração Completa com TUN0

Execute o script de demonstração que garante o uso da `tun0`:

```bash
sudo ./demo_live_tun0.sh
```

Este script irá:
1. Estabelecer o túnel completo
2. Abrir o monitor especificamente na `tun0`
3. Gerar tráfego através do túnel
4. Mostrar os resultados em tempo real

### Solução 5: Teste Rápido com Opção Específica

Execute o teste rápido e escolha a opção 2:

```bash
sudo ./teste_rapido.sh
```

Depois escolha:
- **Opção 2**: Testar criação da interface tun0

### Solução 6: Manual (Para Entendimento)

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
10: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1472 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none 
    inet 172.31.66.1/24 scope global tun0
       valid_lft forever preferred_lft forever
```

## Comandos Úteis

### Para parar todos os processos:
```bash
sudo pkill -f 'traffic_tunnel' && sudo pkill -f 'python3 monitor.py'
```

### Para ver logs em tempo real:
```bash
tail -f logs/camada3.csv
tail -f logs/camada4.csv
```

### Para gerar tráfego de teste:
```bash
ping 172.31.66.1
curl --interface tun0 http://example.com
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

1. **Primeiro**: Execute `sudo ./resolver_tun0.sh` para resolver tudo automaticamente
2. **Alternativa**: Execute `sudo ./teste_tun0.sh` para testar a tun0
3. **Demonstração**: Use `sudo ./demo_live_tun0.sh` para a demonstração completa

Isso garantirá que você está demonstrando exatamente o que foi pedido no enunciado: monitoramento da interface `tun0` do túnel cliente-servidor.

## Troubleshooting

### Se o erro "Device or resource busy" persistir:
1. Execute `sudo ./setup_tun.sh`
2. Reinicie o terminal
3. Execute `sudo ./resolver_tun0.sh`

### Se a tun0 não aparecer:
1. Verifique se o módulo TUN está carregado: `lsmod | grep tun`
2. Verifique se o dispositivo existe: `ls -la /dev/tun`
3. Execute `sudo ./setup_tun.sh`

### Se o túnel não conectar:
1. Verifique se não há firewall bloqueando
2. Verifique se as portas estão livres
3. Execute `sudo ./resolver_tun0.sh` que limpa tudo automaticamente 