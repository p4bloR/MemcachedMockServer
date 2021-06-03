
require_relative "../lib/Server"
require_relative "../lib/Client"
require_relative "../lib/Methods"
require_relative"../lib/MemObject"
require 'rspec/expectations'

#reads the port from file
$port = ((File.open("Test_settings.txt", &:readline)).split)[2]
#if there is a problem readig the file the test uses the default value 8080
$sport ||= 8080

#This series of examples work primarily with two methods from the Client class:

# --> client.write sends user input to the server

# --> client.read gets responses from the server

#Through this two methods the entire functionality of the Server is tested

#this method simulates the user writing on the console
def user_input(input)
	allow($stdin).to receive(:gets).and_return(input)
end

# this simulates command \n value\n
def enterCommand(client, command, value = false)
	user_input(command)
	#this checks what's being sent is == to what the "user" wrote
	expect(client&.write).to be == command
	if value
		user_input(value)
		expect(client&.write).to be == value
	end
end

RSpec.describe "Testing" do


	#before running the examples we open a new server
	before(:all) do
	print "This tests use port 8080 by default. "
	print "Make sure it's not being used or change the selected port by "
  puts "changing the port value on the specs/Test_settings.txt file"
	
  @Server=Server.new("localhost", $port)
	@serverThread = Thread.new{@Server.run} 
	

  @Client = Client.new('localhost', $port)
	@Client2 = Client.new('localhost', $port)

	@allCommands = ['set', 'get', 'gets', 'add', 'replace', 'append', 'prepend', 'cas']
	@retrievalCommands = ['get', 'gets']
	@storageCommands = @allCommands - @retrievalCommands
	end

	context "simple bad user input: " do
		it "user inputs non-existent command" do 
			enterCommand(@Client, "random stuff")
			expect(@Client.read).to be == ResponseStrings.error
			$stdin = STDIN
		end 

		it "user input is empty" do 
			user_input("")
			expect(@Client.write).to eq ""
			expect(@Client.read).to be == ResponseStrings.error
			$stdin = STDIN
		end 
		it "user input is nil" do
			user_input(nil)
			expect(@Client.write).to eq ""
			expect(@Client.read).to be == ResponseStrings.error
			$stdin = STDIN
		end

		it "user inputs command with no parameters" do

			@allCommands.each do |command|
				enterCommand(@Client, command)
				expect(@Client.read).to be == ResponseStrings.error
			end
		end


		it "user inputs insufficient parameters for retrieval" do

			@storageCommands.each do |command|
				enterCommand(@Client, command + " a")
				expect(@Client.read).to be == ResponseStrings.error

				enterCommand(@Client, command + " a 0")
				expect(@Client.read).to be == ResponseStrings.error

				enterCommand(@Client, command + " a 0 1")
				expect(@Client.read).to be == ResponseStrings.error

				if command == "cas" #cas command requires one more parameter than the rest
					enterCommand(@Client, command + " a 0")
					expect(@Client.read).to be == ResponseStrings.error					
					
					enterCommand(@Client, command + " a 0 1")
					expect(@Client.read).to be == ResponseStrings.error					
					
					enterCommand(@Client, command + " a 0 1 1")
					expect(@Client.read).to be == ResponseStrings.error							
				end
			end
		end

		it "user inputs non numeric parameters" do

			@storageCommands.each do |command|

				if command == "cas"
					enterCommand(@Client, command + " a b c d e")
					expect(@Client.read).to be == ResponseStrings.client_error
				else
					enterCommand(@Client, command + " a b c d")
					expect(@Client.read).to be == ResponseStrings.client_error
				end
			end
		end

		it "user input does't match bytecount" do

			@storageCommands.each do |command|

				if command == "cas"
					enterCommand(@Client, command + " a 0 10 3 4","1234") #value is over 3 bytes
					expect(@Client.read).to be == ResponseStrings.bad_data
				else
					enterCommand(@Client, command + " a 0 10 3","1234") #value is over 3 bytes
					expect(@Client.read).to be == ResponseStrings.bad_data
				end 

			end

		end
	end

	context "setting and getting: " do 

		it "getting non-existent elements" do

			enterCommand(@Client, "get j k")
			expect(@Client.read).to be == ResponseStrings.end			
		end

		it "saving 2 values" do
			enterCommand(@Client, "set a 0 3 4","hola")
			expect(@Client.read).to be == ResponseStrings.stored

			#this won't be an issue since the server ignores all elements after the sixth
			enterCommand(@Client, "set b 0 1 5 la la la la la la","hello")
			expect(@Client.read).to be == ResponseStrings.stored			
		end

		it "retrieving 2 values" do
			enterCommand(@Client, "get a b")
			expect(@Client.read).to be == "VALUE a 0 4"
			expect(@Client.read).to be == "hola"
			expect(@Client.read).to be == "VALUE b 0 5"
			expect(@Client.read).to be == "hello"	
			expect(@Client.read).to be == ResponseStrings.end	
		end

		it "attempting to retrieve an expired value" do
			sleep(2)
			enterCommand(@Client, "get b")
			#b has expired
			expect(@Client.read).to be == ResponseStrings.end	
		end

		it "retrieving a single value" do
			enterCommand(@Client, "get a")
			#but a still exists
			expect(@Client.read).to be == "VALUE a 0 4"
			expect(@Client.read).to be == "hola"			
			expect(@Client.read).to be == ResponseStrings.end	
			sleep(1) # a should expire after this
		end
	end

	context "adding and replacing: " do 

		it "attemping to replace a non-existent element" do
			enterCommand(@Client, "replace c 0 1 2", "hi")
			expect(@Client.read).to be == ResponseStrings.not_stored
		end

		it "adding a non-existent element" do
			enterCommand(@Client, "add c 0 2 3","hey")
			expect(@Client.read).to be == ResponseStrings.stored
		end

		it "getting the added value" do
			enterCommand(@Client, "get c")
			expect(@Client.read).to be == "VALUE c 0 3"
			expect(@Client.read).to be == "hey"			
			expect(@Client.read).to be == ResponseStrings.end	
		end		

		it "attempting to add an already existent element" do
			enterCommand(@Client, "add c 0 2 3", "hey")
			expect(@Client.read).to be == ResponseStrings.not_stored
		end

		it "replacing a value" do
			enterCommand(@Client, "replace c 0 1 2", "hi")
			expect(@Client.read).to be == ResponseStrings.stored			 
		end

		it "getting the replaced value" do
			user_input("get c")
			@Client.write
			expect(@Client.read).to be == "VALUE c 0 2"
			expect(@Client.read).to be == "hi"			
			expect(@Client.read).to be == ResponseStrings.end	
		end		
	end

	context "appending and prepending: " do 
		it "attempting to append a non-existent element" do
			enterCommand(@Client, "append d 0 2 9", " goodbye!")
			expect(@Client.read).to be == ResponseStrings.not_stored	
		end		

		it "attempting to prepend a non-existent element" do
			enterCommand(@Client, "prepend d 0 2 6", "hello ")
			expect(@Client.read).to be == ResponseStrings.not_stored	
		end		
		it "adding a value to pre/a/pend" do
			
			enterCommand(@Client, "add d 0 2 3", "and")
			expect(@Client.read).to be == ResponseStrings.stored			
		end

		it "attempting to append a previously existent element" do

			enterCommand(@Client, "append d 0 2 9", " goodbye!")
			expect(@Client.read).to be == ResponseStrings.stored	
		end		
		it "attempting to prepend a non-existent element" do

			enterCommand(@Client, "prepend d 0 2 6","hello ")
			expect(@Client.read).to be == ResponseStrings.stored	
		end		

		it "getting the the value a previously existent element" do
			user_input("get d")
			@Client.write
			expect(@Client.read).to be == "VALUE d 0 18"
			expect(@Client.read).to be == "hello and goodbye!"			
			expect(@Client.read).to be == ResponseStrings.end	
		end
	end

	context "CASing and GETSing: " do
		it "attempting to cas an non-existing element" do
			enterCommand(@Client, "cas e 0 1 3 2", "hey")
			expect(@Client.read).to be == ResponseStrings.not_found		
		end

		it "retrieving non-existent element with gets" do 
			user_input("gets e")
			@Client.write
			expect(@Client.read).to be == ResponseStrings.end			
		end

		it "adding an element and casing it" do
			enterCommand(@Client, "add e 0 2 10", "before cas")
			expect(@Client.read).to be == ResponseStrings.stored
			#getting the cas value
			user_input("gets e")
			@Client.write
			casNumber = @Client.read
			casNumber = casNumber[-1]
			expect(@Client.read).to be == "before cas"			
			expect(@Client.read).to be == ResponseStrings.end

			enterCommand(@Client, "cas e 0 2 9 " + casNumber,"after cas")
			expect(@Client.read).to be == ResponseStrings.stored
		end

		it "attempting cas on an element modified by other client" do
			enterCommand(@Client,"add f 0 2 4","hi, ")
			expect(@Client.read).to be == ResponseStrings.stored	
			
			user_input("gets f")
			@Client.write
			casNumber = (@Client.read).split.last
			expect(@Client.read).to be == "hi, "
			expect(@Client.read).to be == ResponseStrings.end	


			#other user appends modifies the element
			#this also shows the multiclient capabilities
			enterCommand(@Client2, "append f 0 2 15", "how you doing?")		
			expect(@Client2.read).to be == ResponseStrings.stored

			enterCommand(@Client2, "gets f")
			@Client2.read
			expect(@Client2.read).to be == "hi, how you doing?"
			expect(@Client2.read).to be == ResponseStrings.end
			
			enterCommand(@Client, "cas f 0 2 12 " + casNumber, "how are you?")
			expect(@Client.read).to be == ResponseStrings.exists
		end
	end
end