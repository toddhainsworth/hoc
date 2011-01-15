CC=gcc
CFLAGS=-Wall -Wextra -ansi -pedantic
YACC=yacc -o y.tab.c
YYFLAGS=#-Wall

all: hoc1

hoc1: y.tab.c
	$(CC) $(CFLAGS) -o hoc1 y.tab.c

y.tab.c: hoc.y
	$(YACC) $(YYFLAGS) hoc.y

clean:
	rm -f hoc1

distclean: clean
	rm -f y.tab.c
