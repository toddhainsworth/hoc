CC=gcc
YFLAGS=-d
CFLAGS=-g #-Wall -Wextra -ansi -pedantic
OBJ=hoc.o code.o math.o init.o symbol.o

hoc: $(OBJ)
	$(CC) -o hoc -lm $(OBJ)

hoc.o code.o init.o symbol.o: hoc.h

code.o init.o symbol.o: y.tab.h

clean:
	rm -f $(OBJ) y.tab.h hoc core
