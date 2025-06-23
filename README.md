## Monitor de tráfego de rede em tempo real:

## Descrição:

Este trabalho implementa um monitor de tráfego de rede em tempo real usando sockets raw em Python, focado especificamente na monitorização da interface `tun0` de uma arquitetura cliente-servidor com túnel.

## Objetivos:

*   Capturar pacotes de rede em tempo real na interface `tun0`
*   Analisar e classificar tráfego por camadas (2, 3 e 4 do modelo OSI)
*   Gerar logs estruturados em formato CSV
*   Demonstrar funcionamento em ambiente de túnel cliente-servidor

## Estrutura do trabalho final:

```plaintext
Tf_LabRedes-BernardoKleinHeitz/
├── monitor/                 # Código fonte do monitor
│   ├── monitor.py          # Script principal do monitor
│   └── parsers.py          # Parsers para diferentes protocolos
├── traffic_tunnel/         # Implementação do túnel
│   ├── traffic_tunnel      # Executável do túnel
│   ├── server.sh           # Script de configuração do servidor
│   └── client1.sh          # Script de configuração do cliente
├── scripts/                # Scripts de automação e demonstração
│   ├── demos/              # Scripts de demonstração
│   ├── testes/             # Scripts de teste
│   ├── setups/             # Scripts de configuração
│   └── gerador_trafego/    # Scripts para gerar tráfego de teste
├── assets/                 # Recursos do projeto
│   └── logs/               # Logs gerados pelo monitor
├── documentação/           # Documentação do projeto
└── README_SCRIPTS.md       # Guia completo dos scripts
```

## Como usar:

### Pré-requisitos:

*   Python 3.x
*   Privilégios de root (sudo)
*   Interface de rede configurada

### Execução rápida:

```plaintext
sudo ./scripts/testes/teste_rapido.sh
```

**Demonstração com terminais múltiplos:**  
sudo ./scripts/demos/demo\_terminal\_multiplo.sh

**Demonstração com apenas o monitor:** 

```plaintext
cd monitor
sudo python3 monitor.py tun0
```

### Geração de tráfego de teste:

```plaintext
# Ping para o servidor
ping 172.31.66.1

# Tráfego HTTP através do túnel
curl --interface tun0 http://example.com

# Tráfego DNS através do túnel
dig @8.8.8.8 google.com

# Script automatizado de tráfego diverso
./scripts/gerador_trafego/gerar_trafego_teste.sh
```

## Logs gerados:

O monitor gera três arquivos CSV:

*   `**assets/logs/camada2.csv**`: Informações da camada de enlace (Ethernet)
*   `**assets/logs/camada3.csv**`: Informações da camada de rede (IP)
*   `**assets/logs/camada4.csv**`: Informações da camada de transporte (TCP/UDP/ICMP)

**Nota**: Para a interface `tun0`, o arquivo `camada2.csv` ficará vazio, pois `tun0` é uma interface de camada 3.

## Scripts disponíveis:

### Scripts de demonstração:

*   `scripts/demos/demo_terminal_multiplo.sh` - Demonstração completa com 4 terminais
*   `scripts/demos/demo_live_tun0.sh` - Demonstração focada na tun0

### Scripts de teste:

*   `scripts/testes/teste_rapido.sh` - Menu interativo de testes
*   `scripts/testes/teste_tun0.sh` - Teste específico da interface tun0

### Scripts de configuração:

*   `scripts/setups/setup_tun.sh` - Configuração do dispositivo TUN
*   `scripts/setups/resolver_tun0.sh` - Resolução completa de problemas da tun0

### Scripts de geração de tráfego:

*   `scripts/gerador_trafego/gerar_trafego_teste.sh` - Gera tráfego diverso para teste

## Documentação detalhada:

*   `**README_SCRIPTS.md**`: Guia completo de todos os scripts
*   `**README_ESTRUTURA.md**`: Explicação da estrutura de pastas
*   `**documentação/**`: Documentação técnica detalhada

## Notas Importantes:

1.  **Privilégios**: Todos os scripts precisam ser executados com `sudo`
2.  **Interface tun0**: O monitor foi projetado especificamente para a interface `tun0`
3.  **Logs vazios**: Para `tun0`, o log da camada 2 será vazio (comportamento esperado)
4.  **Dependências**: Certifique-se de que o túnel está compilado antes de executar os scripts

## Solução de Problemas:

Se encontrar problemas com a interface `tun0`:

1.  Execute: `sudo ./scripts/setups/resolver_tun0.sh`
2.  Verifique se o túnel está compilado: `cd traffic_tunnel &amp;&amp; make`
3.  Confirme que a interface existe: `ip addr show tun0`

**Bernardo Klein Heitz** - Trabalho de Laboratório de Redes