require 'socket' 
require_relative 'Methods' #getting the commands from another file
require_relative"MemObject"

class Server
   def initialize(socket_address, socket_port)
   	
      @server_socket = TCPServer.open(socket_address, socket_port)

      @connections_details = Hash.new
      @connected_clients = Hash.new

      @connections_details[:server] = @server_socket
      @connections_details[:clients] = @connected_clients

      @database = Database.new

      puts 'Server is running'
      #timer runs nonstop
      @timer_thread = Thread.new{expireTimer}
   end

   #the close command can close client connections individually or 
   #all at once including the server

   def run #run is a loop that aceppts every client and assings threads 
     i = 0 # i will be the key for each thread
     @threads = Hash.new
      loop{

      	begin #attempt non blocking accept

        	client_connection = @server_socket.accept_nonblock # accept every connection

    	rescue IO::WaitReadable, Errno::EINTR
    		IO.select([@server_socket])
    		retry
    	end 
         Thread.start(client_connection) do |connection| # open thread for each accepted connection
            @connections_details[:clients][i] = connection # add the client to the hash
            @threads[i] = Thread.current
            #connection.puts "connected client" 
            i += 1
            establish_communication(connection, @database.dB, @threads) # allow commands

         end
      }.join
   end


   def close(mode, connection)
	   	if mode[0] == 'client'
	       connection.puts "closing client connection"
	       Thread.kill(Thread.current) #kill client thread

	   	elsif mode[0] == 'server'
	   		puts "closing server..."
	   		#this sends a closing order to every client connected
	   		(@connections_details[:clients]).keys.each do |client|
	   			@connections_details[:clients][client].puts "close all"
	   		end
	   		#after closing all connections all client threads die
	   		#so it should be safe to close the server
	   		Thread.kill(@timer_thread) #kill the @timer_thread to leave no witnesses (joking)
	   		sleep(1) #waiting for all users to disconnect
	   		@server_socket.close #closing the server socket
	   		exit #bye Server
	   	end
   end


   # a timer for key expiration
   def expireTimer
		loop do
			sleep(1)

			#Every second it substracts 1 from all exp_time atrributes
			if !@database.dB&.empty?
			@database.dB&.each_key do |key|
				if @database.dB[key]
					@database.dB[key]&.exp_time -= 1
						if @database.dB[key]&.exp_time <= 0
							# if an elements exp_time<=0 its deleted
							@database.dB.delete(key) 
							#puts "deleted #{key}" #this can be useful to check expiring
						end
					end
				end
			end
		end
	end


	def establish_communication(connection, database, threads) 
	#the database parameter allows the commands to update the Database hash
	  #the loop is necessary to be constantly checking for input from the user 
	  loop do
	  	 user_input = get_input(connection) 

	  	 #user_input = connection.gets.chomp.split(' ') #separating the words
	  	 command = user_input[0] # the first word is always the command
	  	 # the rest are the command parameters
	  	 command_parameters = user_input[1...user_input.size]

	  	 #no need to bother executing these commands without their parameters
	  	 if !command_parameters.nil? && !command_parameters.empty?
	  	 	#puts "user #{connection} is executing #{command} command"

		  	# case reads the command and executes methods accordingly
		    case command 
		      when "set"
		      	set_command(command_parameters, connection, database)

		      when "get"
		      	get_command(command_parameters, connection, database)

		      when "gets"
		      	gets_command(command_parameters, connection, database)

		      when "cas"
		      	cas_command(command_parameters, connection, database)

		      when "add"
		      	add_command(command_parameters, connection, database)

		      when "replace"
		      	replace_command(command_parameters, connection, database)

		      when "append"
		      	append_command(command_parameters, connection, database)

		      when "prepend"
		      	prepend_command(command_parameters, connection, database)

		      when "close"
		      	close(command_parameters, connection)
    			else
    		    connection.puts ResponseStrings.error
    			end
	  	 else
	  	 	connection.puts ResponseStrings.error
	  	 end
	  end
	end
end

# a class for the volatile database
class Database
  #an accesor is necessary
	attr_accessor :dB
	def initialize
		@dB = Hash.new
	end
end