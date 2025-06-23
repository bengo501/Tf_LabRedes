import struct
import socket

def parse_ethernet(pkt):
    """
    faz o parsing do cabeçalho Ethernet (camada 2).
    e retorna um dicionário com MAC de origem, destino, 
    etherType e tamanho do quadro.
    """
    if len(pkt) < 14:
        return None
    dst_mac, src_mac, ethertype = struct.unpack('!6s6sH', pkt[:14])
    return {
        'dst_mac': ':'.join('%02x' % b for b in dst_mac),
        'src_mac': ':'.join('%02x' % b for b in src_mac),
        'ethertype': f'0x{ethertype:04x}',
        'size': len(pkt)
    }

def parse_ip(pkt):
    """
    faz o parsing do cabeçalho IP (camada 3).
    e retorna um dicionário com versão, IHL, IP de origem, 
    destino, protocolo e tamanho.
    """
    if len(pkt) < 20:
        return None
    version_ihl = pkt[0]
    version = 'IPv4' if version_ihl >> 4 == 4 else 'IPv6'
    ihl = version_ihl & 0x0F
    total_length = struct.unpack('!H', pkt[2:4])[0]
    protocol = pkt[9]
    src_ip = socket.inet_ntoa(pkt[12:16])
    dst_ip = socket.inet_ntoa(pkt[16:20])
    return {
        'version': version,
        'ihl': ihl,
        'src_ip': src_ip,
        'dst_ip': dst_ip,
        'protocol': protocol,
        'size': total_length
    }

def parse_transport(pkt, proto):
    """
    faz o parsing do cabeçalho de transporte (camada 4) para TCP, UDP e ICMP.
    e retorna um dicionário com portas e tamanho, se aplicável.
    """
    if proto == 6 and len(pkt) >= 20:  # TCP
        src_port, dst_port = struct.unpack('!HH', pkt[:4])
        return {'src_port': src_port, 'dst_port': dst_port, 'size': len(pkt)}
    elif proto == 17 and len(pkt) >= 8:  # UDP
        src_port, dst_port, length = struct.unpack('!HHH', pkt[:6])
        return {'src_port': src_port, 'dst_port': dst_port, 'size': length}
    elif proto == 1 and len(pkt) >= 4:  # ICMP
        # ICMP não possui portas, apenas tipo/código
        return {'src_port': '', 'dst_port': '', 'size': len(pkt)}
    else:
        return None 