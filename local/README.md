Running locally is necessary to execute commands to leave the environment ready and soon after entering the Ruby container.

To build the environment you need to execute the following command:

docker-compose build && docker-compose up -d

Now to enter the container you must execute the command:

docker exec -it RubyApp sh