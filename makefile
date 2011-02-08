CC=gcc
YFLAGS=-d
CFLAGS=-g -Wall -Wextra # -ansi -pedantic
OBJ=hoc.o code.o math.o init.o symbol.o

hoc: y.tab.h $(OBJ)
	$(CC) -o hoc -lm $(OBJ)

y.tab.h: hoc.o
	$(YACC) $(YFLAGS) hoc.y

hoc.o: hoc.h

code.o init.o symbol.o: y.tab.h hoc.h

clean:
	rm -f $(OBJ) y.tab.[ch] hoc core
