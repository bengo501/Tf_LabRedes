# 📋 Guia Completo dos Scripts - Monitor de Tráfego de Rede

## 🎯 Visão Geral

Este projeto contém diversos scripts para facilitar o uso do monitor de tráfego de rede, especialmente focado na interface `tun0` conforme especificado no enunciado do trabalho.

## 📁 Estrutura dos Scripts

### 🚀 Scripts Principais

#### 1. `teste_rapido.sh` - **Script Principal de Teste**
```bash
sudo ./teste_rapido.sh
```

**Funcionalidade:** Menu interativo com todas as opções de teste do projeto.

**Opções disponíveis:**
- **Opção 1**: Teste completo com terminais múltiplos (demo oficial)
- **Opção 2**: Teste manual passo a passo (guiado)
- **Opção 3**: Teste apenas do monitor (tun0 já configurada)
- **Opção 4**: Teste de criação da interface tun0
- **Opção 5**: Demonstrar captura de Camada 2 (interface física)
- **Opção 6**: Sair

**Quando usar:** Para qualquer teste do projeto - é o script mais completo e flexível.

---

#### 2. `demo_terminal_multiplo.sh` - **Demonstração Visual Completa**
```bash
sudo ./demo_terminal_multiplo.sh
```

**Funcionalidade:** Abre 4 terminais separados para demonstração visual completa.

**Terminais criados:**
1. **SERVIDOR TÚNEL**: `./traffic_tunnel tun0 -s 172.31.66.1`
2. **CONFIGURAÇÃO SERVIDOR**: `./server.sh`
3. **CLIENTE TÚNEL**: `./client1.sh`
4. **MONITOR DE TRÁFEGO**: `python3 monitor.py tun0`

**Quando usar:** Para demonstrações, apresentações ou quando quiser ver todos os componentes simultaneamente.

---

#### 3. `demo_live_tun0.sh` - **Demonstração Específica tun0**
```bash
sudo ./demo_live_tun0.sh
```

**Funcionalidade:** Demonstração específica para a interface tun0, abrindo terminais separados.

**Terminais criados:**
- Terminal do servidor
- Terminal do cliente
- Terminal do monitor

**Quando usar:** Para demonstrações focadas especificamente na tun0.

---

### 🔧 Scripts de Configuração

#### 4. `setup_tun.sh` - **Configuração Automática do TUN**
```bash
sudo ./setup_tun.sh
```

**Funcionalidade:** Configura automaticamente o dispositivo TUN e carrega módulos necessários.

**O que faz:**
- Carrega módulo `tun`
- Cria dispositivo `/dev/net/tun`
- Configura permissões
- Verifica se tudo está funcionando

**Quando usar:** Primeira vez que usar o projeto ou quando houver problemas com o dispositivo TUN.

---

#### 5. `resolver_tun0.sh` - **Resolução Completa de Problemas**
```bash
sudo ./resolver_tun0.sh
```

**Funcionalidade:** Resolve todos os problemas da tun0 automaticamente.

**O que faz:**
1. Configura dispositivo TUN
2. Limpa processos antigos
3. Estabelece túnel cliente-servidor
4. Executa monitor na tun0
5. Gera tráfego de teste

**Quando usar:** Quando houver problemas com a tun0 ou quiser uma solução completa automática.

---

### 🧪 Scripts de Teste Específicos

#### 6. `teste_tun0.sh` - **Teste Específico da Interface tun0**
```bash
sudo ./teste_tun0.sh
```

**Funcionalidade:** Testa especificamente a criação e funcionamento da interface tun0.

**O que testa:**
1. Verifica se tun0 existe atualmente
2. Inicia o servidor do túnel
3. Conecta o cliente
4. Verifica se tun0 foi criada
5. Testa conectividade através do túnel

**Quando usar:** Para testar especificamente se a interface tun0 está funcionando corretamente.

---

#### 7. `teste_rapido.sh` (Opção 4) - **Teste de Criação da tun0**
```bash
sudo ./teste_rapido.sh
# Escolher Opção 4
```

**Funcionalidade:** Chama o `teste_tun0.sh` através do menu principal.

**Quando usar:** Para testar a tun0 através do menu interativo.

---

### 🌐 Scripts de Geração de Tráfego

#### 8. `gerar_trafego_teste.sh` - **Geração de Tráfego Diverso**
```bash
./gerar_trafego_teste.sh
```

**Funcionalidade:** Gera diferentes tipos de tráfego para testar o monitor.

**Tipos de tráfego gerados:**
- **ICMP**: Ping para diferentes destinos
- **TCP**: Conexões HTTP e HTTPS
- **UDP**: Consultas DNS
- **Tráfego local**: Comunicação entre cliente e servidor

**Quando usar:** Para gerar tráfego diverso e testar a capacidade do monitor.

---

### 🔧 Scripts do Túnel (traffic_tunnel/)

#### 9. `traffic_tunnel/server.sh` - **Configuração do Servidor**
```bash
cd traffic_tunnel
sudo ./server.sh
```

**Funcionalidade:** Configura a interface tun0 no servidor.

**O que faz:**
- Configura IP da interface tun0 (172.31.66.1/24)
- Habilita roteamento IP
- Configura iptables para NAT
- Ativa forwarding de pacotes

**Quando usar:** Chamado automaticamente pelos scripts principais após iniciar o servidor.

---

#### 10. `traffic_tunnel/client1.sh` - **Configuração do Cliente 1**
```bash
cd traffic_tunnel
sudo ./client1.sh
```

**Funcionalidade:** Configura a interface tun0 no cliente.

**O que faz:**
- Configura IP da interface tun0 (172.31.66.101/24)
- Adiciona rota para o servidor
- Configura gateway através do túnel

**Quando usar:** Chamado automaticamente pelos scripts principais para configurar o cliente.

---

#### 11. `traffic_tunnel/client2.sh` - **Configuração do Cliente 2**
```bash
cd traffic_tunnel
sudo ./client2.sh
```

**Funcionalidade:** Configuração alternativa do cliente (IP 172.31.66.102).

**O que faz:**
- Similar ao client1.sh, mas com IP diferente
- Configura IP da interface tun0 (172.31.66.102/24)

**Quando usar:** Para testes com múltiplos clientes ou configuração alternativa.

---

#### 12. `traffic_tunnel/Makefile` - **Compilação do Túnel**
```bash
cd traffic_tunnel
make
```

**Funcionalidade:** Compila o código C do túnel.

**O que faz:**
- Compila `tunnel.c` e `traffic_tunnel.c`
- Gera o executável `traffic_tunnel`
- Limpa arquivos objeto com `make clean`

**Quando usar:** Primeira vez ou quando modificar o código do túnel.

---

## 🎮 Como Usar os Scripts

### 🚀 **Primeira Execução (Recomendado)**

```bash
# 1. Configurar o ambiente
sudo ./setup_tun.sh

# 2. Executar teste completo
sudo ./teste_rapido.sh
# Escolher Opção 1 (Teste completo com terminais múltiplos)
```

### 🎯 **Demonstração Visual**

```bash
# Para demonstração com 4 terminais
sudo ./demo_terminal_multiplo.sh

# Para demonstração específica tun0
sudo ./demo_live_tun0.sh
```

### 🔧 **Resolução de Problemas**

```bash
# Se houver problemas com tun0
sudo ./resolver_tun0.sh

# Para testar especificamente a tun0
sudo ./teste_tun0.sh
```

### 🌐 **Geração de Tráfego**

```bash
# Gerar tráfego diverso para teste
./gerar_trafego_teste.sh
```

## 📊 Fluxo de Uso Recomendado

### **Cenário 1: Primeira Vez**
```bash
sudo ./setup_tun.sh          # Configurar ambiente
sudo ./teste_rapido.sh       # Menu principal
# Escolher Opção 1
```

### **Cenário 2: Demonstração**
```bash
sudo ./demo_terminal_multiplo.sh  # 4 terminais visuais
```

### **Cenário 3: Problemas**
```bash
sudo ./resolver_tun0.sh      # Resolução automática
```

### **Cenário 4: Teste Específico**
```bash
sudo ./teste_tun0.sh         # Teste apenas da tun0
```

## 🔍 Comandos Manuais (Referência)

### **Servidor**
```bash
cd traffic_tunnel
sudo ./traffic_tunnel tun0 -s 172.31.66.1
```

### **Configuração do Servidor**
```bash
cd traffic_tunnel
sudo ./server.sh
```

### **Cliente**
```bash
cd traffic_tunnel
sudo ./client1.sh
```

### **Monitor**
```bash
sudo python3 monitor.py tun0
```

### **Geração de Tráfego**
```bash
ping 172.31.66.1
curl --interface tun0 http://example.com
dig @8.8.8.8 google.com
```

## 📝 Logs e Resultados

### **Arquivos de Log Gerados**
- `logs/camada2.csv` - Logs de Camada 2 (Ethernet)
- `logs/camada3.csv` - Logs de Camada 3 (IP)
- `logs/camada4.csv` - Logs de Camada 4 (Transporte)

### **Visualização em Tempo Real**
```bash
tail -f logs/camada3.csv
tail -f logs/camada4.csv
```

## ⚠️ Observações Importantes

### **Interface tun0**
- É uma interface **Layer 3** (IP)
- **Não possui headers Ethernet**
- O arquivo `camada2.csv` ficará **vazio** (comportamento esperado)
- Foco nos logs de **Camada 3 e 4**

### **Privilégios**
- Todos os scripts precisam ser executados com `sudo`
- Requer privilégios de root para captura de pacotes

### **Dependências**
- Python 3
- Módulo `tun` do kernel
- `gnome-terminal` (para scripts de demonstração)

## 🎯 Scripts Essenciais vs. Complementares

### **Essenciais (Usar sempre)**
- ✅ `teste_rapido.sh` - Menu principal
- ✅ `setup_tun.sh` - Configuração inicial
- ✅ `demo_terminal_multiplo.sh` - Demonstração completa

### **Complementares (Usar quando necessário)**
- 🔧 `resolver_tun0.sh` - Resolução de problemas
- 🧪 `teste_tun0.sh` - Teste específico
- 🌐 `gerar_trafego_teste.sh` - Geração de tráfego
- 🎭 `demo_live_tun0.sh` - Demonstração específica

### **Scripts do Túnel (Chamados automaticamente)**
- 🔧 `traffic_tunnel/server.sh` - Configuração do servidor
- 🔧 `traffic_tunnel/client1.sh` - Configuração do cliente
- 🔧 `traffic_tunnel/client2.sh` - Cliente alternativo
- 🔧 `traffic_tunnel/Makefile` - Compilação

## 🚀 Dica Final

**Para começar rapidamente:**
```bash
sudo ./teste_rapido.sh
```

Este é o script mais completo e flexível, oferecendo todas as opções de teste em um menu interativo! 🎯 