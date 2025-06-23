CC=gcc
CFLAGS=-I. -O2 -Wall
DEPS = tunnel.h

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

ttunnel: traffic_tunnel.o tunnel.o
	$(CC) -o traffic_tunnel tunnel.o traffic_tunnel.o $(CFLAGS)

all: ttunnel

clean:
	rm -f *.o traffic_tunnel
