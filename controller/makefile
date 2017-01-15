
CXX=g++
CPPFLAGS=-I.

DEPS = controller.h gpio.h
OBJ = controller.o gpio.o

LINKFLAGS=
LIBS=-lm -lzmq -lwiringPi

%.o: %.cpp $(DEPS)
	$(CXX) -c -o $@ $< $(CPPFLAGS)

fakecontroller.o: controller.cpp
	$(CXX) -c -o $@ $< $(CPPFLAGS) -DUSE_FAKE_GPIO

controller: $(OBJ)
	g++ -o $@ $^ $(LINKFLAGS) $(LIBS)

fakecontroller: fakecontroller.o gpio.o
	g++ -o $@ $^ $(LINKFLAGS) $(LIBS)
