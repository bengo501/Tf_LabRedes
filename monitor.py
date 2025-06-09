import socket
import struct
import csv
import time
import os
from parsers import parse_ethernet, parse_ip, parse_transport

LOG_DIR = 'logs'
CAMADA2_CSV = os.path.join(LOG_DIR, 'camada2.csv')
CAMADA3_CSV = os.path.join(LOG_DIR, 'camada3.csv')
CAMADA4_CSV = os.path.join(LOG_DIR, 'camada4.csv')

PROTOCOLS = {1: 'ICMP', 6: 'TCP', 17: 'UDP'}

# Contadores globais
counters = {
    'Ethernet': 0,
    'IPv4': 0,
    'IPv6': 0,
    'ARP': 0,
    'TCP': 0,
    'UDP': 0,
    'ICMP': 0,
    'Outros': 0
}

def init_logs():
    os.makedirs(LOG_DIR, exist_ok=True)
    if not os.path.exists(CAMADA2_CSV):
        with open(CAMADA2_CSV, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['DataHora', 'MAC_Origem', 'MAC_Destino', 'EtherType', 'Tamanho'])
    if not os.path.exists(CAMADA3_CSV):
        with open(CAMADA3_CSV, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['DataHora', 'Protocolo', 'IP_Origem', 'IP_Destino', 'Protocolo_Num', 'Tamanho'])
    if not os.path.exists(CAMADA4_CSV):
        with open(CAMADA4_CSV, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['DataHora', 'Protocolo', 'IP_Origem', 'Porta_Origem', 'IP_Destino', 'Porta_Destino', 'Tamanho'])

def print_counters():
    os.system('clear')
    print('Contadores de Pacotes por Protocolo:')
    for proto, count in counters.items():
        print(f'{proto}: {count}')
    print('\nPressione Ctrl+C para sair.')

def main():
    init_logs()
    try:
        s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(0x0003))
        s.bind(('tun0', 0))
    except Exception as e:
        print(f'Erro ao abrir socket: {e}')
        return
    print('Monitorando interface tun0...')
    last_print = time.time()
    while True:
        pkt, addr = s.recvfrom(65535)
        now = time.strftime('%Y-%m-%d %H:%M:%S')
        eth = parse_ethernet(pkt)
        if eth is None:
            counters['Outros'] += 1
            continue
        counters['Ethernet'] += 1
        with open(CAMADA2_CSV, 'a', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([now, eth['src_mac'], eth['dst_mac'], eth['ethertype'], eth['size']])
        if eth['ethertype'] == '0x0800':  # IPv4
            ip = parse_ip(pkt[14:])
            if ip is None:
                counters['Outros'] += 1
                continue
            counters['IPv4'] += 1
            with open(CAMADA3_CSV, 'a', newline='') as f:
                writer = csv.writer(f)
                writer.writerow([now, ip['version'], ip['src_ip'], ip['dst_ip'], ip['protocol'], ip['size']])
            if ip['protocol'] in PROTOCOLS:
                trans = parse_transport(pkt[14+ip['ihl']*4:], ip['protocol'])
                if trans:
                    counters[PROTOCOLS[ip['protocol']]] += 1
                    with open(CAMADA4_CSV, 'a', newline='') as f:
                        writer = csv.writer(f)
                        writer.writerow([now, PROTOCOLS[ip['protocol']], ip['src_ip'], trans['src_port'], ip['dst_ip'], trans['dst_port'], trans['size']])
                else:
                    counters['Outros'] += 1
            else:
                counters['Outros'] += 1
        elif eth['ethertype'] == '0x0806':  # ARP
            counters['ARP'] += 1
        elif eth['ethertype'] == '0x86DD':  # IPv6
            counters['IPv6'] += 1
        else:
            counters['Outros'] += 1
        if time.time() - last_print > 1:
            print_counters()
            last_print = time.time()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\nEncerrando monitoramento.') 