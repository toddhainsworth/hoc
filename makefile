CFLAGS=-Wall -Wextra
YFLAGS=-d
OBJ=hoc.o code.o math.o init.o symbol.o

hoc: $(OBJ)
	$(CC) $(OBJ) -lm -o hoc

hoc.o code.o init.o symbol.o: hoc.h

code.o init.o symbol.o: y.tab.h

clean:
	rm -f $(OBJ) y.tab.[ch] hoc core
