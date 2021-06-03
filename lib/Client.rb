require 'socket'

class Client
	def initialize(socket_address, socket_port)
		@socket = TCPSocket.open(socket_address, socket_port)
		#run

	end

	def run
		puts "Connected to server"
		@send = write_loop #sends input to the server
		@listen = read_loop #listens responses from the server
		@send.join # sends request to server
		@listen.join # receives response from server
	end

	#checks the messages sent to the server
	def client_close_check(message)
		if message == "close client"
			@socket.puts message
			Thread.kill(@listen_thread)
			@socket.close
			exit
		end
	end
	#checks the messages coming from the server
	def server_close_check(response)
		if response == "close all"
			puts "The server closed"
			@socket.close
			exit
		end
	end

	#this writes to the server
	def write
		message = $stdin.gets
		message ||= '' #this idiom avoids nil errors
		message.chomp!

		client_close_check(message)
		@socket.puts message

		return message
	end
	#this method reads from the server
	def read
		response = @socket.gets
		response ||= ''
		response.chomp!

		server_close_check(response)
		puts response
		return response	
	end
	# a loop to constantly be ready to write to the server
	def write_loop 
		begin
			@send_thread = Thread.new do
				loop do
					write
				end
			end
			
		rescue IOError => e
			puts e.message
			client_close_check("close client")
		end
	end
	# a loop to constanly read from the server
	def read_loop 
		begin
			@listen_thread = Thread.new do
				loop do
					read
					end
				end
			
		rescue Exception => e
			puts e.message
			@socket.close
			
		end
	end
end