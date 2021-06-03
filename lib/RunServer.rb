require_relative 'Client'
require_relative 'Server'
require_relative 'Methods'

puts "Enter a port that's not in use (8080 is usually a good choice)"
puts 'Enter "exit" to close'

begin
	loop do
		user_input = gets #gets user input
		user_input ||= ''
		user_input.chomp!

		if user_input == "exit"
		  "bye"
		  exit
		elsif checkInt(user_input)
			socket_port = user_input
			my_server = Server.new("localhost", socket_port)
			my_server.run
		else 
			puts 'Please enter a number or "exit"' 
		end	
	end
rescue Errno::EADDRINUSE => e 
	puts e.message
	puts "Seems like that port is already in use try another one"
	retry
end
