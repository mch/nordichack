#include "controller.h"
#include "gpio.h"

#include <iostream>
#include <sstream>

#include <unistd.h>

#include <wiringPi.h>
#include <zmq.hpp>

/**
 * For a given message, performs some action or retrieves some data.
 * 
 * May wish to change this into a data transformation function that
 * converts untrusted input into trusted command objects, in implement
 * interpretation of those commands elsewhere.
 *
 * Roughly, command names consist of a string matching [A-Z]+,
 * followed by a space, and any number of command specific arguments.
 * 
 * Returns a response message.
 */
std::string handle_message(std::string msg, HardwareInterface& gpio)
{
  std::cout << "received message, " << msg.length() << " bytes: '"
	    << msg << "'" << std::endl;

  std::istringstream inputstream(msg);

  std::string command;
  inputstream >> command;

  // These commands are like this to minimize calcuation in this code
  // and to avoid the need to load calibration parameters from
  // somewhere. Although a "CALIBRATE" command might suffice...
  if (command.compare("SETDUTYCYCLE") == 0)
    {
      int dutyCycle = 0;
      inputstream >> dutyCycle; // how does this fail?
      gpio.writePwm(dutyCycle);
    }
  else if (command.compare("GETSPEEDFREQUENCY") == 0)
    {
      std::ostringstream outputstream;
      outputstream << gpio.readSpeedFrequency();
      return outputstream.str();
    }
  else
    {
      return "FAIL";
    }
  
  return "OK";
}

std::string errorString(int error)
{
  switch (error)
    {
    case EAGAIN:
      return "EAGAIN";
      break;
    case ENOTSUP:
      return "ENOTSUP";
      break;
    case EFSM:
      return "EFSM";
      break;
    case ETERM:
      return "ETERM";
      break;
    case ENOTSOCK:
      return "ENOTSOCK";
      break;
    case EINTR:
      return "EINTR";
      break;
    case EFAULT:
      return "EFAULT";
      break;
    default:
      return "unknown";
    }

  return "unknown";
}

int main(int argc, char** argv)
{
  try
    {
      FakeGpio gpio;
      gpio.init();

      zmq::context_t context(1);
      zmq::socket_t socket(context, ZMQ_REP);
      socket.bind("tcp://127.0.0.1:5555");

      while (true)
	{
	  // TODO: check that safety key is inserted before allowing operation.

	  // Want to respond as far as possible to user input, but
	  // don't want to exclusivly block waiting for it either,
	  // since we need to check things like the presence of the
	  // key and that motors are still turning... Call socket.recv
	  // on a separate thread and create an event queue?
	  
	  zmq::message_t request;
	  if (socket.recv(&request)) //, ZMQ_NOBLOCK))
	    {
	      std::string msg(static_cast<char*>(request.data()), request.size());

	      std::string rsp = handle_message(msg, gpio);
	  
	      zmq::message_t reply(rsp.length());
	      memcpy(reply.data(), rsp.c_str(), rsp.length());
	      socket.send(reply);
	    }
	  else
	    {
	      if (errno == EAGAIN)
		{
		  //sleep(1); // do other stuff....
		}
	      else
		{
		  std::cerr << "Unexpected error receiving zmq message: "
			    << errno << ", " << errorString(errno) << "\n";
		  break;
		}
	    }
	}
    }
  catch (std::exception &e)
    {
      std::cerr << "Unexpected failure: " << e.what() << std::endl;
      return 1;
    }

  return 0;
}
