# Guia de Execução - Monitor de Tráfego de Rede (Trabalho Final)

> **📋 Descrição**: Manual de execução oficial focado na demonstração do projeto conforme o enunciado original. Explica como executar o monitor na interface obrigatória `tun0` do servidor proxy, aborda a contradição técnica da Camada 2 e fornece um checklist completo para apresentação. Ideal para demonstrar o trabalho ao professor seguindo exatamente a arquitetura especificada.

---

Este guia está 100% alinhado com o enunciado do trabalho final, focando na arquitetura de túnel e na interface obrigatória **`tun0`**.

## 📋 Análise do Enunciado e da Implementação

### Requisito Central: Monitorar `tun0`
O enunciado é explícito:
> "A interface a ser monitorada é a interface virtual **tun0** no servidor proxy"

O programa foi desenvolvido para atender a este requisito, executando na máquina que atua como servidor proxy e capturando o tráfego desencapsulado do túnel.

### A Contradição da Camada 2
O enunciado pede um log de **Camada 2 (`camada2.csv`)**, que exige endereços MAC. No entanto, a interface **`tun0`** é uma interface de Camada 3 (Rede), e **não possui cabeçalhos Ethernet**.

**Solução Implementada:**
- O monitor, ao detectar a interface `tun0`, **cria o arquivo `camada2.csv`** para cumprir o requisito de entrega.
- No entanto, este arquivo **permanecerá vazio**, pois não há dados de Camada 2 para registrar.
- A capacidade de capturar a Camada 2 foi implementada e pode ser demonstrada em uma interface física, provando que o código está completo.

---

## 🚀 Passo a Passo para Execução e Demonstração (Cenário do Trabalho)

Este é o fluxo que deve ser seguido para executar o projeto conforme a arquitetura especificada.

### Passo 1: Compilar o Programa do Túnel
Se ainda não foi compilado, execute:
```bash
# Navegar para o diretório do túnel
cd /home/bernardo/Downloads/Tf_LabRedes-BernardoKleinHeitz/traffic_tunnel

# Compilar
make
```

### Passo 2: Executar o Servidor do Túnel (Terminal 1)
O servidor do túnel deve ser executado na máquina que atuará como proxy.
```bash
# No diretório traffic_tunnel
# Substitua wlp0s20f3 e 192.168.0.15 pela sua interface física e IP
sudo ./traffic_tunnel wlp0s20f3 -s 192.168.0.15
```
**Deixe este terminal aberto.** Ele é o "servidor proxy".

### Passo 3: Verificar a Criação da `tun0`
Abra um novo terminal e verifique se a interface `tun0` foi criada e está ativa.
```bash
ip addr show tun0
```
Você deverá ver a interface `tun0` com o IP `172.31.66.1`.

### Passo 4: Executar o Monitor de Tráfego (Terminal 2)
Este é o passo principal do seu trabalho. O monitor será executado na interface obrigatória `tun0`.
```bash
# Navegar para o diretório principal do projeto
cd /home/bernardo/Downloads/Tf_LabRedes-BernardoKleinHeitz

# Executar o monitor
sudo python3 monitor.py tun0
```
O monitor exibirá la mensagem `Tipo de interface detectado: tun` e começará a aguardar pacotes.

### Passo 5: Executar o Cliente do Túnel (Terminal 3 - Idealmente outra máquina/VM)
Para gerar tráfego que passe pelo proxy, execute o cliente do túnel.
```bash
# No diretório traffic_tunnel
# Substitua os IPs e a interface conforme sua rede
sudo ./traffic_tunnel <if_cliente> -c <ip_cliente> -t
```
O cliente irá configurar uma nova interface `tun` e rotear seu tráfego por ela.

### Passo 6: Gerar Tráfego para Teste
No terminal do **cliente** (Terminal 3), gere tráfego para a internet.
```bash
# O tráfego será encapsulado, enviado ao servidor e aparecerá na tun0 do servidor
ping 8.8.8.8
curl http://example.com
```

## 📊 Verificando os Resultados (Conforme Enunciado)

### 1. Contadores em Tempo Real (Terminal 2)
Observe a tela do monitor. Os contadores de `IPv4`, `TCP`, `UDP`, `ICMP` devem aumentar.

### 2. Logs em Tempo Real (Abra um novo Terminal 4)
Verifique os arquivos de log sendo preenchidos.
```bash
# Ver log da Camada 3
tail -f logs/camada3.csv

# Ver log da Camada 4
tail -f logs/camada4.csv
```
**Observação Importante:**
```bash
# O log da Camada 2 estará vazio, como esperado para a interface tun0
cat logs/camada2.csv
# Saída esperada: Apenas o cabeçalho
# DataHora,MAC_Origem,MAC_Destino,EtherType,Tamanho
```

## 📸 Checklist para Apresentação
Para demonstrar o funcionamento completo e o domínio do conteúdo:
- [ ] **Terminal 1:** Mostrar o `traffic_tunnel` em modo servidor rodando.
- [ ] **Comando `ip addr show tun0`:** Provar que a interface do proxy está ativa.
- [ ] **Terminal 2:** Mostrar o `monitor.py tun0` em execução, com os contadores subindo.
- [ ] **Terminal 3:** Mostrar o cliente do túnel e a geração de tráfego (`ping`, `curl`).
- [ ] **Terminal 4:** Exibir os logs das camadas 3 e 4 com `tail -f`.
- [ ] **Justificativa Técnica:** Explicar por que o `camada2.csv` está vazio ao monitorar a `tun0`, demonstrando conhecimento sobre interfaces TUN.

## (Opcional) Demonstração da Capacidade de Captura da Camada 2
Se perguntado, você pode provar que a funcionalidade da Camada 2 foi implementada:
```bash
# Pare os outros processos e execute o monitor em sua interface física
sudo python3 monitor.py wlp0s20f3
```
Neste modo, o `camada2.csv` será preenchido, provando que o código está 100% completo.
 