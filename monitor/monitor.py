import socket
import struct
import csv
import time
import os
import sys
from parsers import parse_ethernet, parse_ip, parse_transport

# dir onde os arquivos de log serão salvos
LOG_DIR = '../assets/logs'
CAMADA2_CSV = os.path.join(LOG_DIR, 'camada2.csv')
CAMADA3_CSV = os.path.join(LOG_DIR, 'camada3.csv')
CAMADA4_CSV = os.path.join(LOG_DIR, 'camada4.csv')

# mapeamento dos números de protocolo IP para nomes
PROTOCOLS = {1: 'ICMP', 6: 'TCP', 17: 'UDP'}

# contadores globais para cada tipo de pacote
counters = {
    'IPv4': 0,       # total de pacotes IPv4
    'IPv6': 0,       # total de pacotes IPv6
    'ARP': 0,        # total de pacotes ARP
    'TCP': 0,        # total de segmentos TCP
    'UDP': 0,        # total de datagramas UDP
    'ICMP': 0,       # total de mensagens ICMP
    'Outros': 0      # pacotes não classificados ou malformados
}

def init_logs():
    """
    Cria o diretório e os arquivos de log, se ainda não existirem, e escreve o cabeçalho de cada CSV.
    Os arquivos são:
      - camada2.csv: informações da camada de enlace (Ethernet) - apenas para interfaces físicas
      - camada3.csv: informações da camada de rede (IP)
      - camada4.csv: informações da camada de transporte (TCP/UDP/ICMP)
    """
    os.makedirs(LOG_DIR, exist_ok=True)
    
    # header para camada 2 (Ethernet)
    if not os.path.exists(CAMADA2_CSV):
        with open(CAMADA2_CSV, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['DataHora', 'MAC_Origem', 'MAC_Destino', 'EtherType', 'Tamanho'])
    
    # header para camada 3 (IP)
    if not os.path.exists(CAMADA3_CSV):
        with open(CAMADA3_CSV, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['DataHora', 'Protocolo', 'IP_Origem', 'IP_Destino', 'Protocolo_Num', 'Tamanho'])
    
    # header para camada 4 (Transporte)
    if not os.path.exists(CAMADA4_CSV):
        with open(CAMADA4_CSV, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['DataHora', 'Protocolo', 'IP_Origem', 'Porta_Origem', 'IP_Destino', 'Porta_Destino', 'Tamanho'])

def print_counters():
    """
    limpa a tela e exibe os contadores de pacotes por protocolo.
    util para acompanhar o tráfego em tempo real.
    """
    os.system('clear')
    print('=== MONITOR DE TRÁFEGO DE REDE EM TEMPO REAL ===')
    print('Contadores de Pacotes por Protocolo:')
    print('-' * 40)
    for proto, count in counters.items():
        print(f'{proto:8}: {count:6}')
    print('-' * 40)
    print('\nLogs salvos em:')
    print(f'  Camada 2: {CAMADA2_CSV}')
    print(f'  Camada 3: {CAMADA3_CSV}')
    print(f'  Camada 4: {CAMADA4_CSV}')
    print('\nPressione Ctrl+C para sair.')

def detect_interface_type(interface_name):
    """
    detecta se a interface é física (com Ethernet) ou
    virtual (TUN).
    e retorna 'physical' ou 'tun'.
    """
    try:
        # verficia se a interface existe
        with open('/proc/net/dev', 'r') as f:
            interfaces = f.read()
        if interface_name in interfaces:
            # se for tun0, é virtual
            if interface_name.startswith('tun'):
                return 'tun'
            # se for eth, wlan, eno, ens, enp, etc., é física
            elif any(interface_name.startswith(prefix) for prefix in ['eth', 'wlan', 'eno', 'ens', 'enp', 'wl']):
                return 'physical'
            else:
                return 'unknown'
        else:
            return 'not_found'
    except:
        return 'unknown'

def main():
    """
    func principal:     - inicializa os arquivos de log - detecta o tipo de interface
                        - abre o socket raw na interface especificada - captura pacotes em loop infinito
                        - faz parsing e logging das camadas 2, 3 e 4 - atualiza contadores e exibe estatísticas em tempo real
    """
    # verifica argumentos da linha de comando
    interface = 'tun0'  # interface padrão
    if len(sys.argv) > 1:
        interface = sys.argv[1]
    
    print(f'Iniciando monitor na interface: {interface}')
    
    # detecta tipo de interface
    interface_type = detect_interface_type(interface)
    print(f'Tipo de interface detectado: {interface_type}')
    
    if interface_type == 'not_found':
        print(f'Erro: Interface {interface} não encontrada!')
        print('Interfaces disponíveis:')
        try:
            with open('/proc/net/dev', 'r') as f:
                lines = f.readlines()[2:]  # pula as duas primeiras linhas
                for line in lines:
                    if ':' in line:
                        iface = line.split(':')[0].strip()
                        print(f'  - {iface}')
        except:
            pass
        return
    
    init_logs()  # garante que os arquivos de log existem
    
    try:
        # cria um socket raw ligado à interface para capturar todos os pacotes
        s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(0x0003))
        s.bind((interface, 0))
    except Exception as e:
        print(f'Erro ao abrir socket: {e}')
        print('Certifique-se de executar como root e que a interface existe.')
        return
    
    print(f'Monitorando interface {interface}...')
    last_print = time.time()
    
    while True:
        # recebe um pacote da interface (máximo 65535 bytes)
        pkt, addr = s.recvfrom(65535)
        now = time.strftime('%Y-%m-%d %H:%M:%S')  # Timestamp para o log
        
        # processa baseado no tipo de interface
        if interface_type == 'physical':
            # interface física: começa com cabeçalho Ethernet
            eth = parse_ethernet(pkt)
            if eth:
                # loga informações da camada 2 (Ethernet)
                with open(CAMADA2_CSV, 'a', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow([now, eth['src_mac'], eth['dst_mac'], eth['ethertype'], eth['size']])
                
                # Verifica se é IP (EtherType 0x0800)
                if eth['ethertype'] == '0x0800':
                    # Remove cabeçalho Ethernet (14 bytes) e processa IP
                    ip_pkt = pkt[14:]
                    ip = parse_ip(ip_pkt)
                    if ip:
                        counters['IPv4'] += 1
                        # Loga informações da camada 3 (IP)
                        with open(CAMADA3_CSV, 'a', newline='') as f:
                            writer = csv.writer(f)
                            writer.writerow([now, ip['version'], ip['src_ip'], ip['dst_ip'], ip['protocol'], ip['size']])
                        
                        # Se for TCP, UDP ou ICMP, faz parsing da camada 4
                        if ip['protocol'] in PROTOCOLS:
                            trans = parse_transport(ip_pkt[ip['ihl']*4:], ip['protocol'])
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
                    else:
                        counters['Outros'] += 1
                elif eth['ethertype'] == '0x0806':  # ARP
                    counters['ARP'] += 1
                else:
                    counters['Outros'] += 1
            else:
                counters['Outros'] += 1
                
        elif interface_type == 'tun':
            # Interface TUN: começa diretamente com cabeçalho IP
            ip = parse_ip(pkt)
            if ip is None:
                counters['Outros'] += 1
                continue
                    
            counters['IPv4'] += 1
            # loga informações da camada 3 (IP)
            with open(CAMADA3_CSV, 'a', newline='') as f:
                writer = csv.writer(f)
                writer.writerow([now, ip['version'], ip['src_ip'], ip['dst_ip'], ip['protocol'], ip['size']])
                
            # caso for TCP, UDP ou ICMP, faz parsing da camada 4
            if ip['protocol'] in PROTOCOLS:
                trans = parse_transport(pkt[ip['ihl']*4:], ip['protocol'])
                if trans:
                    counters[PROTOCOLS[ip['protocol']]] += 1
                    # irá lor informações da camada 4 (transporte)
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
        
        # att a exibição a cada segundo
        if time.time() - last_print >= 1.0:
            print_counters()
            last_print = time.time()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n=== RESUMO FINAL ===")
        print("Contadores finais:")
        for proto, count in counters.items():
            print(f"{proto}: {count}")
        print(f"\nLogs salvos em:")
        print(f"  Camada 2: {CAMADA2_CSV}")
        print(f"  Camada 3: {CAMADA3_CSV}")
        print(f"  Camada 4: {CAMADA4_CSV}")
        print("\nPara visualizar os logs:")
        print(f"  cat {CAMADA2_CSV}  # Apenas para interfaces físicas")
        print(f"  cat {CAMADA3_CSV}")
        print(f"  cat {CAMADA4_CSV}")
        print("\nMonitor encerrado.")
    except Exception as e:
        print(f"\nErro inesperado: {e}")
        print("Monitor encerrado com erro.")
