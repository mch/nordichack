
CXX=g++

DEPS = controller.h gpio.h
OBJ = controller.o gpio.o

.PHONY: all clean
all: fakecontroller controller

clean:
	rm -f *.o fakecontroller controller

%.o: %.cpp $(DEPS)
	$(CXX) -c -o $@ $< $(CPPFLAGS)

fakecontroller.o: controller.cpp controller.h
	$(CXX) -c -o $@ $< $(CPPFLAGS)

fakegpio.o: gpio.cpp gpio.h
	$(CXX) -c -o $@ $< $(CPPFLAGS)

controller: CPPFLAGS=-I.
controller: LIBS=-lm -lzmq -lwiringpi
controller: $(OBJ)
	g++ -o $@ $^ $(LINKFLAGS) $(LIBS)

fakecontroller: CPPFLAGS=-I. -DUSE_FAKE_GPIO
fakecontroller: LIBS=-lm -lzmq
fakecontroller: fakecontroller.o fakegpio.o
	g++ -o $@ $^ $(LINKFLAGS) $(LIBS)

