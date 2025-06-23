# 📁 Estrutura Organizada do Projeto - Monitor de Tráfego de Rede

## 🎯 Visão Geral da Organização

Este projeto foi organizado em uma estrutura de pastas lógica e profissional para facilitar a navegação, manutenção e uso dos diferentes componentes.

## 📂 Estrutura de Pastas

```
Tf_LabRedes-BernardoKleinHeitz/
├── 📁 scripts/                    # Scripts organizados por categoria
│   ├── 📁 demo/                   # Scripts de demonstração
│   │   ├── demo_terminal_multiplo.sh
│   │   └── demo_live_tun0.sh
│   ├── 📁 test/                   # Scripts de teste
│   │   ├── teste_rapido.sh
│   │   └── teste_tun0.sh
│   ├── 📁 setup/                  # Scripts de configuração
│   │   ├── setup_tun.sh
│   │   └── resolver_tun0.sh
│   └── 📁 utils/                  # Scripts utilitários
│       └── gerar_trafego_teste.sh
├── 📁 docs/                       # Documentação
│   ├── 📁 guides/                 # Guias e documentação
│   │   ├── GUIA_EXECUCAO.md
│   │   ├── GUIA_MAQUINA_UNICA.md
│   │   ├── GUIA_TUN0.md
│   │   └── README_SCRIPTS.md
│   └── 📁 reports/                # Relatórios e análises
│       ├── RELATORIO_MONITOR_REDE.md
│       ├── RESUMO_ANALISE.md
│       └── RELATORIO_MONITOR_REDE.docx
├── 📁 src/                        # Código fonte
│   ├── 📁 monitor/                # Código do monitor
│   │   ├── monitor.py
│   │   └── parsers.py
│   └── 📁 tunnel/                 # Código do túnel
│       └── traffic_tunnel/
│           ├── tunnel.c
│           ├── tunnel.h
│           ├── traffic_tunnel.c
│           ├── Makefile
│           ├── server.sh
│           ├── client1.sh
│           └── client2.sh
├── 📁 assets/                     # Assets do projeto
│   ├── 📁 logs/                   # Arquivos de log
│   │   ├── camada2.csv
│   │   ├── camada3.csv
│   │   └── camada4.csv
│   └── 📁 prints/                 # Screenshots
│       ├── Monitor_Print.png
│       ├── Tunnel_Print.png
│       └── ...
├── 📁 traffic_tunnel/             # Pasta original (mantida para compatibilidade)
├── 📁 logs/                       # Logs originais (mantidos para compatibilidade)
├── 📁 prints/                     # Prints originais (mantidos para compatibilidade)
├── 📁 __pycache__/                # Cache Python
├── 📄 README.md                   # README principal
├── 📄 README_ESTRUTURA.md         # Este arquivo
├── 📄 organizar_projeto.sh        # Script de organização
└── 📄 .git/                       # Controle de versão
```

## 🚀 Como Usar a Nova Estrutura

### **Scripts Principais**

#### **Teste Rápido (Menu Principal)**
```bash
sudo ./scripts/test/teste_rapido.sh
```

#### **Demonstração Completa**
```bash
sudo ./scripts/demo/demo_terminal_multiplo.sh
```

#### **Configuração Inicial**
```bash
sudo ./scripts/setup/setup_tun.sh
```

#### **Resolução de Problemas**
```bash
sudo ./scripts/setup/resolver_tun0.sh
```

#### **Geração de Tráfego**
```bash
./scripts/utils/gerar_trafego_teste.sh
```

### **Código Fonte**

#### **Monitor de Tráfego**
```bash
sudo python3 src/monitor/monitor.py tun0
```

#### **Compilação do Túnel**
```bash
cd src/tunnel/traffic_tunnel
make
```

### **Documentação**

#### **Guias**
- `docs/guides/GUIA_EXECUCAO.md` - Guia geral de execução
- `docs/guides/GUIA_MAQUINA_UNICA.md` - Guia para máquina única
- `docs/guides/GUIA_TUN0.md` - Guia específico da tun0
- `docs/guides/README_SCRIPTS.md` - Guia completo dos scripts

#### **Relatórios**
- `docs/reports/RELATORIO_MONITOR_REDE.md` - Relatório principal
- `docs/reports/RESUMO_ANALISE.md` - Resumo da análise
- `docs/reports/RELATORIO_MONITOR_REDE.docx` - Relatório em Word

### **Logs e Assets**

#### **Visualizar Logs**
```bash
tail -f assets/logs/camada3.csv
tail -f assets/logs/camada4.csv
```

#### **Screenshots**
- `assets/prints/` - Todas as capturas de tela

## 🔄 Compatibilidade

### **Pastas Mantidas**
- `traffic_tunnel/` - Mantida para compatibilidade com scripts existentes
- `logs/` - Mantida para compatibilidade
- `prints/` - Mantida para compatibilidade

### **Scripts Atualizados**
Todos os scripts foram atualizados para usar os novos caminhos, mas mantêm compatibilidade com a estrutura original.

## 📋 Vantagens da Organização

### **1. Estrutura Lógica**
- ✅ Scripts organizados por função
- ✅ Documentação separada por tipo
- ✅ Código fonte organizado por componente
- ✅ Assets separados por tipo

### **2. Facilidade de Navegação**
- ✅ Fácil localização de arquivos
- ✅ Estrutura intuitiva
- ✅ Separação clara de responsabilidades

### **3. Manutenibilidade**
- ✅ Fácil manutenção de cada componente
- ✅ Isolamento de funcionalidades
- ✅ Estrutura escalável

### **4. Profissionalismo**
- ✅ Estrutura padrão de projetos
- ✅ Organização profissional
- ✅ Documentação bem estruturada

## 🎯 Fluxo de Uso Recomendado

### **Primeira Vez**
```bash
# 1. Configurar ambiente
sudo ./scripts/setup/setup_tun.sh

# 2. Executar teste principal
sudo ./scripts/test/teste_rapido.sh
```

### **Demonstração**
```bash
# Demonstração visual completa
sudo ./scripts/demo/demo_terminal_multiplo.sh
```

### **Desenvolvimento**
```bash
# Editar código do monitor
nano src/monitor/monitor.py

# Compilar túnel
cd src/tunnel/traffic_tunnel && make
```

### **Documentação**
```bash
# Consultar guias
cat docs/guides/README_SCRIPTS.md

# Ver relatórios
cat docs/reports/RELATORIO_MONITOR_REDE.md
```

## 🔧 Script de Organização

Para aplicar esta organização em um projeto existente:

```bash
chmod +x organizar_projeto.sh
./organizar_projeto.sh
```

## 📝 Notas Importantes

### **Caminhos Atualizados**
- Todos os scripts agora usam caminhos relativos à nova estrutura
- Compatibilidade mantida com estrutura original
- Documentação atualizada com novos caminhos

### **Execução de Scripts**
- Scripts podem ser executados de qualquer diretório
- Caminhos relativos garantem funcionamento correto
- Estrutura flexível para diferentes ambientes

### **Manutenção**
- Fácil adição de novos scripts nas categorias apropriadas
- Documentação centralizada e organizada
- Estrutura escalável para futuras expansões

## 🎯 Conclusão

Esta organização torna o projeto mais profissional, fácil de navegar e manter, seguindo padrões de desenvolvimento modernos! 🚀 