
CXX=g++
CPPFLAGS=-I.

DEPS = controller.h
OBJ = controller.o

LINKFLAGS=
LIBS=-lm -lzmq -lwiringPi

%.o: %.cpp $(DEPS)
	$(CXX) -c -o $@ $< $(CPPFLAGS)

controller: $(OBJ)
	g++ -o $@ $^ $(LINKFLAGS) $(LIBS)
