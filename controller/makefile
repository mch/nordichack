
CXX=g++
CPPFLAGS=-I.

DEPS = controller.h gpio.h
OBJ = controller.o gpio.o

LINKFLAGS=
LIBS=-lm -lzmq -lwiringPi

%.o: %.cpp $(DEPS)
	$(CXX) -c -o $@ $< $(CPPFLAGS)

controller: $(OBJ)
	g++ -o $@ $^ $(LINKFLAGS) $(LIBS)
