#include "controller.h"
#include "gpio.h"

#include <iostream>
#include <unistd.h>

#include <wiringPi.h>
#include <zmq.hpp>

/**
 * For a given message, performs some action or retrieves some data.
 * 
 * Returns a response message.
 */
std::string handle_message(std::string msg)
{
  std::cout << "received message, " << msg.length() << " bytes: '"
	    << msg << "'" << std::endl;

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
	  zmq::message_t request;
	  if (socket.recv(&request, ZMQ_NOBLOCK))
	    {
	      std::string msg(static_cast<char*>(request.data()), request.size());

	      std::string rsp = handle_message(msg);
	      sleep(1);
	  
	      zmq::message_t reply(rsp.length() + 1);
	      memcpy(reply.data(), rsp.c_str(), rsp.length());
	      socket.send(reply);
	    }
	  else
	    {
	      if (errno == EAGAIN)
		{
		  sleep(1); // do other stuff....
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
