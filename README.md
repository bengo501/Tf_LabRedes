# Monitor de Tráfego de Rede em Tempo Real

Este projeto implementa um monitor de tráfego de rede em tempo real usando raw sockets, conforme especificado no trabalho final de Laboratório de Redes de Computadores.

## Funcionalidades
- Captura pacotes na interface `tun0`.
- Exibe contadores em tempo real por protocolo.
- Gera logs em CSV para as camadas 2, 3 e 4 (camada2.csv, camada3.csv, camada4.csv).
- Logs podem ser visualizados a qualquer momento com `cat logs/camadaX.csv`.

## Como usar
1. Certifique-se de estar em um ambiente Linux com Python 3.
2. Execute o túnel conforme instruções do enunciado e verifique se a interface `tun0` está ativa.
3. Execute o monitor com:
   ```bash
   sudo python3 monitor.py
   ```
4. Os arquivos de log serão criados na pasta `logs/`.

## Estrutura dos logs
- **camada2.csv**: DataHora, MAC_Origem, MAC_Destino, EtherType, Tamanho
- **camada3.csv**: DataHora, Protocolo, IP_Origem, IP_Destino, Protocolo_Num, Tamanho
- **camada4.csv**: DataHora, Protocolo, IP_Origem, Porta_Origem, IP_Destino, Porta_Destino, Tamanho

## Observações
- O monitor deve ser executado como root (sudo) para acesso ao raw socket.
- O código não depende de bibliotecas externas além da biblioteca padrão do Python.
- Para interromper, pressione Ctrl+C.

## Autores
- [Nomes dos integrantes aqui] 