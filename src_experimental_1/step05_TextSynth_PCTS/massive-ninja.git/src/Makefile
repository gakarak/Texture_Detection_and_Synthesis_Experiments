CC=g++
GLINCL=-lglfw -lGL -lGLEW
SRC=main.cpp
OLDSRC=main_old.cpp
DEST=main

all: $(SRC)
	$(CC) $(SRC) $(GLINCL) -o $(DEST)

clang:
	clang++ $(GLINCL) $(SRC) -o $(DEST)

old:
	$(CC) $(GLINCL) $(OLDSRC) -o ./OLD/$(DEST)

debug: $(SRC)
	$(CC) -g $(GLINCL) $(SRC) -o $(DEST)

clean:
	rm $(DEST)
