#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <linux/if.h>
#include <linux/if_tun.h>
#include <linux/if_packet.h>
#include <linux/ip.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/ether.h>
#include <pwd.h>
#include <pthread.h>
#include <unistd.h>
#include "tunnel.h"

#define MTU 1472
#define DEFAULT_ROUTE   "0.0.0.0"


int tun_alloc(char *dev, int flags)
{
	struct ifreq ifr;
	int tun_fd, err;
	char *clonedev = "/dev/net/tun";
	printf("[DEBUG] Allocating tunnel\n");

	tun_fd = open(clonedev, O_RDWR);

	if(tun_fd == -1) {
		perror("Unable to open clone device\n");
		exit(EXIT_FAILURE);
	}

	memset(&ifr, 0, sizeof(ifr));

	ifr.ifr_flags = flags;

	if (*dev) {
		strncpy(ifr.ifr_name, dev, IFNAMSIZ);
	}

	if ((err=ioctl(tun_fd, TUNSETIFF, (void *)&ifr)) < 0) {
		close(tun_fd);
		fprintf(stderr, "Error returned by ioctl(): %s\n", strerror(err));
		perror("Error in tun_alloc()\n");
		exit(EXIT_FAILURE);
	}

	printf("[DEBUG] Created tunnel %s\n", dev);

	return tun_fd;
}

int tun_read(int tun_fd, char *buffer, int length)
{
	int bytes_read;
	bytes_read = read(tun_fd, buffer, length);

	if (bytes_read == -1) {
		perror("Unable to read from tunnel\n");
		exit(EXIT_FAILURE);
	} else {
		return bytes_read;
	}
}

int tun_write(int tun_fd, char *buffer, int length)
{
	int bytes_written;
	bytes_written = write(tun_fd, buffer, length);

	if (bytes_written == -1) {
		perror("Unable to write to tunnel\n");
		exit(EXIT_FAILURE);
	} else {
		return bytes_written;
	}
}

void configure_network(int server, char *client_script)
{
	int pid, status;
	char path[100];
	char *const args[] = {path, NULL};

	if (server) {
		if (sizeof(SERVER_SCRIPT) > sizeof(path)){
			perror("Server script path is too long\n");
			exit(EXIT_FAILURE);
		}
		strncpy(path, SERVER_SCRIPT, strlen(SERVER_SCRIPT) + 1);
	} else {
		if (strlen(client_script) > sizeof(path)){
			perror("Client script path is too long\n");
			exit(EXIT_FAILURE);
		}
		strncpy(path, client_script, sizeof(path));
	}

	pid = fork();

	if (pid == -1) {
		perror("Unable to fork\n");
		exit(EXIT_FAILURE);
	}

	if (pid == 0) {
		exit(execv(path, args));
	} else {
		waitpid(pid, &status, 0);
		if (WEXITSTATUS(status) == 0) {
			printf("[DEBUG] Script ran successfully\n");
		} else {
			printf("[DEBUG] Error in running script\n");
		}
	}
}

void print_hexdump(char *str, int len)
{
	for (int i = 0; i < len; i++) {
		if (i % 16 == 0) printf("\n");
		printf("%02x ", (unsigned char)str[i]);
	}
	printf("\n");
}

unsigned long ipchksum(char *packet)
{
	unsigned long sum = 0;

	for (int i = 0; i < 20; i += 2)
		sum += ((unsigned long)packet[i] << 8) | (unsigned long)packet[i + 1];
	while (sum & 0xffff0000)
		sum = (sum & 0xffff) + (sum >> 16);
		
	return sum;
}


void run_tunnel(char *dest, int server, int argc, char *argv[])
{
	char this_mac[6];
	char bcast_mac[6] =	{0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
	char dst_mac[6] =	{0x00, 0x00, 0x00, 0x22, 0x22, 0x22};
	char src_mac[6] =	{0x00, 0x00, 0x00, 0x33, 0x33, 0x33};

	char buf[ETH_LEN];
	struct eth_ip_s *hdr = (struct eth_ip_s *)&buf;
	char *payload = (char *)&buf + sizeof(struct eth_ip_s);

	struct ifreq if_idx, if_mac, ifopts;
	char ifName[IFNAMSIZ];
	struct sockaddr_ll socket_address;
	int sock_fd, tun_fd, size;

	fd_set fs;

	tun_fd = tun_alloc("tun0", IFF_TUN | IFF_NO_PI);

	printf("[DEBUG] Starting tunnel - Dest: %s, Server: %d\n", dest, server);
	printf("[DEBUG] Opening socket\n");

	/* Get interface name */
	if (argc > 3) {
		strcpy(ifName, argv[1]);
	} else {
		perror("Error configuring interface\n");
		exit(1);
	}

	/* Open RAW socket */
	if ((sock_fd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL))) == -1)
		perror("socket");

	/* Set interface to promiscuous mode */
	strncpy(ifopts.ifr_name, ifName, IFNAMSIZ-1);
	ioctl(sock_fd, SIOCGIFFLAGS, &ifopts);
	ifopts.ifr_flags |= IFF_PROMISC;
	ioctl(sock_fd, SIOCSIFFLAGS, &ifopts);

	/* Get the index of the interface */
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(sock_fd, SIOCGIFINDEX, &if_idx) < 0)
		perror("SIOCGIFINDEX");
	socket_address.sll_ifindex = if_idx.ifr_ifindex;
	socket_address.sll_halen = ETH_ALEN;

	/* Get the MAC address of the interface */
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(sock_fd, SIOCGIFHWADDR, &if_mac) < 0)
		perror("SIOCGIFHWADDR");
	memcpy(this_mac, if_mac.ifr_hwaddr.sa_data, 6);

	if (server)
		configure_network(server, 0);
	else
		configure_network(server, argv[5]);

	while (1) {
		FD_ZERO(&fs);
		FD_SET(tun_fd, &fs);
		FD_SET(sock_fd, &fs);

		select(tun_fd > sock_fd ? tun_fd + 1 : sock_fd + 1, &fs, NULL, NULL, NULL);

		if (FD_ISSET(tun_fd, &fs)) {
			printf("[DEBUG] Read tun device\n");
			memset(&buf, 0, sizeof(buf));
			
			/* Fill the payload with tunnel data */
			size = tun_read(tun_fd, payload, MTU);
			if (size == -1) {
				perror("Error while reading from tun device\n");
				exit(EXIT_FAILURE);
			}
			print_hexdump(payload, size);

			/* Fill the Ethernet frame header */
			memcpy(hdr->ethernet.dst_addr, bcast_mac, 6);
			memcpy(hdr->ethernet.src_addr, src_mac, 6);
			hdr->ethernet.eth_type = htons(ETH_P_IP);

			/* Fill IP header data. Fill all fields and a zeroed CRC field, then update the CRC! */
			hdr->ip.ver = 0x45;
			hdr->ip.tos = 0x00;
			hdr->ip.len = htons(size + sizeof(struct ip_hdr));
			hdr->ip.id = htons(0x00);
			hdr->ip.off = htons(0x00);
			hdr->ip.ttl = 50;
			hdr->ip.proto = 0xff;
			hdr->ip.sum = htons(0x0000);

			if (server) {
				hdr->ip.src[0] = 192;
				hdr->ip.src[1] = 168;
				hdr->ip.src[2] = 255;
				hdr->ip.src[3] = 1;
				hdr->ip.dst[0] = 192;
				hdr->ip.dst[1] = 168;
				hdr->ip.dst[2] = 255;
				hdr->ip.dst[3] = 10;
			} else {
				hdr->ip.src[0] = 192;
				hdr->ip.src[1] = 168;
				hdr->ip.src[2] = 255;
				hdr->ip.src[3] = 10;
				hdr->ip.dst[0] = 192;
				hdr->ip.dst[1] = 168;
				hdr->ip.dst[2] = 255;
				hdr->ip.dst[3] = 1;
			}

			hdr->ip.sum = htons((~ipchksum((char *)&hdr->ip) & 0xffff));

			/* Send the raw socket packet */
			memcpy(socket_address.sll_addr, dst_mac, 6);
			if (sendto(sock_fd, buf, size + sizeof(struct eth_ip_s), 0, (struct sockaddr *)&socket_address, sizeof(struct sockaddr_ll)) < 0)
				printf("Send failed\n");

			printf("[DEBUG] Sent packet\n");
		}

		if (FD_ISSET(sock_fd, &fs)) {
			/* Get ethernet data */
			size = recvfrom(sock_fd, buf, ETH_LEN, 0, NULL, NULL);
			if (hdr->ethernet.eth_type == ntohs(ETH_P_IP)){
				if (server) {
					if (	hdr->ip.dst[0] == 192 && hdr->ip.dst[1] == 168 &&
						hdr->ip.dst[2] == 255 && hdr->ip.dst[3] == 1){
						print_hexdump(buf, size);
						/* our filter matches, send data to the tunnel */
						tun_write(tun_fd, payload, size);
						printf("[DEBUG] Write tun device\n");
					}
				} else {
					if (	hdr->ip.dst[0] == 192 && hdr->ip.dst[1] == 168 &&
						hdr->ip.dst[2] == 255 && hdr->ip.dst[3] == 10){
						print_hexdump(buf, size);
						/* our filter matches, send data to the tunnel */
						tun_write(tun_fd, payload, size);
						printf("[DEBUG] Write tun device\n");
					}
				}
			}
		}
	}
}
