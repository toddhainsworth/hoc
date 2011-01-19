CC=gcc
CFLAGS=-Wall -Wextra -ansi -pedantic

hoc: hoc.o
	$(CC) hoc.o -o hoc

clean:
	rm hoc.o hoc
