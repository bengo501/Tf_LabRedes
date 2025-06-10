import socket
import struct
import csv
import time
import os
from parsers import parse_ip, parse_transport

# Diretório onde os arquivos de log serão salvos
LOG_DIR = 'logs'
CAMADA3_CSV = os.path.join(LOG_DIR, 'camada3.csv')
CAMADA4_CSV = os.path.join(LOG_DIR, 'camada4.csv')

# Mapeamento dos números de protocolo IP para nomes
PROTOCOLS = {1: 'ICMP', 6: 'TCP', 17: 'UDP'}

# Contadores globais para cada tipo de pacote
counters = {
    'IPv4': 0,       # Total de pacotes IPv4
    'IPv6': 0,       # Total de pacotes IPv6
    'ARP': 0,        # Total de pacotes ARP
    'TCP': 0,        # Total de segmentos TCP
    'UDP': 0,        # Total de datagramas UDP
    'ICMP': 0,       # Total de mensagens ICMP
    'Outros': 0      # Pacotes não classificados ou malformados
}

def init_logs():
    """
    Cria o diretório e os arquivos de log, se ainda não existirem, e escreve o cabeçalho de cada CSV.
    Os arquivos são:
      - camada3.csv: informações da camada de rede (IP)
      - camada4.csv: informações da camada de transporte (TCP/UDP/ICMP)
    """
    os.makedirs(LOG_DIR, exist_ok=True)
    if not os.path.exists(CAMADA3_CSV):
        with open(CAMADA3_CSV, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['DataHora', 'Protocolo', 'IP_Origem', 'IP_Destino', 'Protocolo_Num', 'Tamanho'])
    if not os.path.exists(CAMADA4_CSV):
        with open(CAMADA4_CSV, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['DataHora', 'Protocolo', 'IP_Origem', 'Porta_Origem', 'IP_Destino', 'Porta_Destino', 'Tamanho'])

def print_counters():
    """
    Limpa a tela e exibe os contadores de pacotes por protocolo.
    Útil para acompanhar o tráfego em tempo real.
    """
    os.system('clear')
    print('Contadores de Pacotes por Protocolo:')
    for proto, count in counters.items():
        print(f'{proto}: {count}')
    print('\nPressione Ctrl+C para sair.')

def main():
    """
    Função principal:
    - Inicializa os arquivos de log
    - Abre o socket raw na interface tun0
    - Captura pacotes em loop infinito
    - Faz parsing e logging das camadas 3 e 4
    - Atualiza contadores e exibe estatísticas em tempo real
    """
    init_logs()  # Garante que os arquivos de log existem
    try:
        # Cria um socket raw ligado à interface tun0 para capturar todos os pacotes
        s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(0x0003))
        s.bind(('tun0', 0))
    except Exception as e:
        print(f'Erro ao abrir socket: {e}')
        print('Certifique-se de executar como root e que a interface tun0 existe.')
        return
    print('Monitorando interface tun0...')
    last_print = time.time()
    while True:
        # Recebe um pacote da interface (máximo 65535 bytes)
        pkt, addr = s.recvfrom(65535)
        now = time.strftime('%Y-%m-%d %H:%M:%S')  # Timestamp para o log
        # Em tun0, o pacote já começa no cabeçalho IP!
        ip = parse_ip(pkt)
        if ip is None:
            counters['Outros'] += 1
            continue
        counters['IPv4'] += 1
        # Loga informações da camada 3 (IP)
        with open(CAMADA3_CSV, 'a', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([now, ip['version'], ip['src_ip'], ip['dst_ip'], ip['protocol'], ip['size']])
        # Se for TCP, UDP ou ICMP, faz parsing da camada 4
        if ip['protocol'] in PROTOCOLS:
            trans = parse_transport(pkt[ip['ihl']*4:], ip['protocol'])
            if trans:
                counters[PROTOCOLS[ip['protocol']]] += 1
                # Loga informações da camada 4 (transporte)
                with open(CAMADA4_CSV, 'a', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow([
                        now,
                        PROTOCOLS[ip['protocol']],
                        ip['src_ip'],
                        trans['src_port'],
                        ip['dst_ip'],
                        trans['dst_port'],
                        trans['size']
                    ])
            else:
                counters['Outros'] += 1
        else:
            counters['Outros'] += 1
        # Atualiza a interface de texto a cada segundo
        if time.time() - last_print > 1:
            print_counters()
            last_print = time.time()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        # Permite encerrar o monitor com Ctrl+C de forma limpa
        print('\nEncerrando monitoramento.')

"""
Notas adicionais:
- Os arquivos de log podem ser visualizados em tempo real com o comando:
    cat logs/camada3.csv
    cat logs/camada4.csv
- Limitações: O monitor só faz parsing detalhado de IPv4, TCP, UDP e ICMP. Pacotes IPv6 e ARP são apenas contados.
- Possíveis erros: Se a interface tun0 não existir ou o script não for executado como root, o socket não será criado.
- O código pode ser expandido para suportar parsing de IPv6, ARP e outros protocolos, se desejado.
""" 