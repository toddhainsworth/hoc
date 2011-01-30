CC=gcc
CFLAGS=-Wall -Wextra -g
OBJ=hoc.o math.o init.o symbol.o
YFLAGS=-d

hoc: $(OBJ)
	$(CC) -o hoc -lm $(OBJ)

hoc.o: hoc.h

init.o symbol.o: hoc.h y.tab.h

clean:
	rm -f $(OBJ) y.tab.h hoc
