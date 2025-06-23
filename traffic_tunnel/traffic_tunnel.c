#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <stdint.h>
#include "tunnel.h"

#define ARG_SERVER_MODE "-s"
#define ARG_CLIENT_MODE "-c"

void usage()
{
	fprintf(stdout, "usage:\n");
	fprintf(stdout, "server: # ./traffic_tunnel [interface] -s [server_ip]\n");
	fprintf(stdout, "client: # ./traffic_tunnel [interface] -c [client_ip] -t [clientscript.sh]\n");
}

int main(int argc, char *argv[])
{
	char ip_addr[128] = {0, };
	
	if ((argc < 4) || ((strlen(argv[3]) + 1) > sizeof(ip_addr))) {
		usage();
		exit(EXIT_FAILURE);
	}
	memcpy(ip_addr, argv[3], strlen(argv[3]) + 1);

	if (strncmp(argv[2], ARG_SERVER_MODE, strlen(argv[2])) == 0) {
		run_tunnel(ip_addr, 1, argc, argv);
	} else {
		if (strncmp(argv[2], ARG_CLIENT_MODE, strlen(argv[2])) == 0) {
			if (argc < 6) {
				usage();
				exit(EXIT_FAILURE);
			}
				
			run_tunnel(ip_addr, 0, argc, argv);
		} else {
			usage();
			exit(EXIT_FAILURE);
		}
	}

	return EXIT_SUCCESS;
}
