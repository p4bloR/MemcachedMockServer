require_relative 'Client'
require_relative 'Server'
require_relative 'Methods'

begin
	loop do
		puts "Enter a port with a Server running"
		puts 'Enter "exit" to close'
		user_input = gets
		user_input ||= ''
		user_input.chomp!

		if user_input == "exit"
		  "bye"
		  exit
		elsif checkInt(user_input)
			socket_port = user_input
			my_client = Client.new('localhost', socket_port)
			my_client.run
		else 
			puts 'Please enter a number or "exit"' 
		end	
	end
rescue Errno::ECONNREFUSED => e 
	#if the connection is refused the server probably isn't running
	puts e.message
	puts "Connection refused, is the server running?"
	retry
end
