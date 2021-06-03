require_relative"MemObject"

# a class to centralize response strings
class ResponseStrings

	@@error = "ERROR"
	@@stored = "STORED"
	@@not_stored = "NOT_STORED"
	@@exists = "EXISTS"
	@@not_found = "NOT_FOUND"
	@@end = "END"
	@@client_error = "CLIENT_ERROR"
	@@bad_data = "CLIENT_ERROR bad  data chunk"

	# can't use accessors with class variables, so methods are needed
	def self.error
		return @@error
	end

	def self.stored
		return @@stored
	end	

	def self.not_stored
		return @@not_stored
	end

	def self.exists
		return @@exists
	end

	def self.not_found
		return @@not_found
	end

	def self.end
		return @@end
	end

	def self.client_error
		return @@client_error
	end

	def self.bad_data
		return @@bad_data
	end	
end

def get_input(connection, mode = '0') #checks for nill or empty input
	user_input = connection.gets

	if !(user_input.nil? || user_input.empty?) && mode == '0'
		user_input.chomp!.split(' ')
	elsif !(user_input.nil? || user_input.empty?) && mode == '1'
		return user_input.chomp!
	else
		user_input =''
	end
end

def checkInt(input) #checks if a string is int number
	check = Integer(input) rescue false
	#if input is int it converts it, else it returns false
	return check 
end

def checkPositiveInt(input)#checks if a string is a positive int number
	#returns boolean state
	return (Integer(input) rescue false) && (Integer(input) >=0) 
end
# input for al storage commands except cas is 
# 0     1      2        3      4
#key, flag, exp_time, bytes, no reply
def set_command(input, connection, database, mode = '0')

	input = input[...4] # Memcached ignores any parameters after the 5th
	#5th parameter is [noreply]
	#parameters should be + ints
	input_int_check = input[1...3].all? {|s| checkPositiveInt(s)} 
	input_size_check = input.size >= 4 #there should be at least 4 parameters

	# checking the parameters, at least 3 positive ints are needed
	if input_int_check && input_size_check && !input.nil?

		key = input[0].to_sym # symbols make faster hash keys
		flag = input[1].to_i  # all other data should be ints
		exp_time = input[2].to_i
		byte_size = input[3].to_i

		value = get_input(connection, '1') # gets the value from the user
		
			# this case allows reusing the set command for append and prepend
		case mode
			when "0"
				if value.size == byte_size 
					#this mode is the default, used for regular set command
					mem_element = MemObject.new(key, flag, exp_time, byte_size) 
					mem_element.value = value
					 # saves the Memcached element to the Hash
					database[key] = mem_element #if key
					connection.puts ResponseStrings.stored #success message
				else
					connection.puts ResponseStrings.bad_data #bytecount error 
				end
			when '1'
				#this mode is used for append
				database[key].value = database[key].value + value
				database[key].byte_size = input[3]
				#since the MemObect isn't created it's necessary
				# to manually update the cas value
				database[key].cas_id = MemObject.update_cas

				connection.puts ResponseStrings.stored #success messsage

			when "2"
				#this mode is used for prepend
				database[key].value  = value + database[key].value	
				database[key].byte_size = input[3]
				#since the MemObect isn't created it's necessary
				# to manually update the cas value
				database[key].cas_id = MemObject.update_cas
				connection.puts ResponseStrings.stored #success messsage
		end

	elsif !input_int_check && input_size_check && !input.nil?
		#if parameters aren't positive ints
		connection.puts ResponseStrings.client_error
	else
		connection.puts ResponseStrings.error
	end
end

#get command
def get_command(input, connection, database) #returns 'VALUE' key, flag, bytes r\n\ value
	#it's possible to retrieve an array of elements with a single get command
	input.each do |key| #input should contain a 1D array of hash keys
		key = key.to_sym  #keys are symbols
		if (database.key?(key))
			#getting the data
			key = database[key].key
			flag = database[key].flag
			byte_size = database[key].byte_size
			value = database[key].value

			# response
			connection.puts "VALUE #{key} #{flag} #{byte_size}", value
		end
	end
	connection.puts ResponseStrings.end
	#else 
	#	connection.puts ResponseStrings.end #end message
	#end
end

def gets_command(input, connection, database) 
# returns "VALUE", key, flag, byte_size, cas and value
	
	#this is the same as get command but also prints the cas_id
	input.each do |key|
		#if !key.nil? && !key.empty?
			key = key.to_sym
			if (database.key?(key))
				#getting the data
				flag = database[key].flag
				byte_size = database[key].byte_size
				cas_id = database[key].cas_id
				value = database[key].value
				#reponse
				connection.puts "VALUE #{key} #{flag} #{byte_size} #{cas_id}", value
			end
		#end
	end
	connection.puts ResponseStrings.end
end

def cas_command(input, connection, database) 
#input is
# key, flag, exp_time, bytes, cas_id, [noreply]
	
	input = input[...5] #ignores everything after sixth element
	key = input[0].to_sym
	input_int_check = input[1...5].all? {|s| checkPositiveInt(s)} 
	input_size_check = input.size >= 5

	#checking if the cas exists and parameter count
	if (database.key?(key)) && input_int_check && input_size_check
		cas_id = input[4]
		#checking if cas matches changed
		if (cas_id == database[key].cas_id.to_s) 

			flag = input[1]
			exp_time = input[2]
			byte_size = input[3].to_i
			noreply = input[5] # not used for anything at the moment

			#input array now contins key, flag, exp_time, bytes, cas_id and [noreply]
			# but set command doesn;t accepts cas_id as a parameter
			input.delete_at(4) # so cas_id is deleted here from input

			set_command(input, connection, database)# and the set command is called
		else
			#cas didn't match, someone else edited the element
			connection.puts ResponseStrings.exists 
		end

	elsif !(database.key?(key)) && input_int_check && input_size_check

		byte_size = input[3].to_i
		disposable_string = get_input(connection, '1')

		if disposable_string.length == byte_size
			connection.puts ResponseStrings.not_found

		else
			#bytecount error
			connection.puts ResponseStrings.bad_data
		end
	
	elsif !input_int_check && input_size_check && !input.nil?
		#parameters aren't positive ints
		connection.puts ResponseStrings.client_error

	else
		connection.puts ResponseStrings.error #the key doesn't exists
	end
end

def add_command(input, connection, database) 
	input = input[...4]
	key = input[0].to_sym
	input_int_check = input[1...3].all? {|s| checkPositiveInt(s)} 
	input_size_check = input.size >= 4

	if !database.key?(key) && input_int_check && input_size_check# check if key exists
		#if key doesn't exists, execute set command
		set_command(input, connection, database)

	elsif database.key?(key) && input_int_check && input_size_check

		byte_size = input[3].to_i
		disposable_string = get_input(connection, '1')

		if disposable_string.length == byte_size
			connection.puts ResponseStrings.not_stored

		else
			connection.puts ResponseStrings.bad_data
		end

	elsif !input_int_check && input_size_check && !input.nil?
		connection.puts ResponseStrings.client_error
	else
		connection.puts ResponseStrings.error
	end
end

def replace_command(input, connection, database)
	# the replace command is inverse to the add command
	input = input[...4]
	key = input[0].to_sym
	input_int_check = input[1...3].all? {|s| checkPositiveInt(s)} 
	input_size_check = input.size >= 4

	if database.key?(key) && input_int_check && input_size_check #if key already exists
		set_command(input, connection, database) #execute set command


	elsif !database.key?(key) && input_int_check && input_size_check

		byte_size = input[3].to_i
		disposable_string = get_input(connection, '1')

		if disposable_string.length == byte_size
			connection.puts ResponseStrings.not_stored
		else
			connection.puts ResponseStrings.bad_data
		end

	elsif !input_int_check && input_size_check && !input.nil?
		connection.puts ResponseStrings.client_error

	else #any other error
		connection.puts ResponseStrings.error
	end
end

def append_command(input, connection, database)

	input = input[...4]
	key = input[0].to_sym
	input_int_check = input[1...3].all? {|s| checkPositiveInt(s)} 
	input_size_check = input.size >= 4


	# check if the key exists
	if database.key?(key) && input_int_check && input_size_check 
		#update the bytes to take into the acount original size + appendix
		input[3] = (input[3].to_i + database[key].byte_size.to_i).to_s
		#the "1" is to make the set command append the new strings
		set_command(input, connection, database, '1')

	elsif !database.key?(key) && input_int_check && input_size_check

		byte_size = input[3].to_i
		disposable_string = get_input(connection, '1')

		if disposable_string.length == byte_size
			connection.puts ResponseStrings.not_stored
		else
			connection.puts ResponseStrings.bad_data
		end

	elsif !input_int_check && input_size_check && !input.nil?
		connection.puts ResponseStrings.client_error

	else
		connection.puts ResponseStrings.error
	end
end

def prepend_command(input, connection, database)

	input = input[...4]
	key = input[0].to_sym
	input_int_check = input[1...3].all? {|s| checkPositiveInt(s)} 
	input_size_check = input.size >= 4

	# check if the key exists
	if database.key?(key) && input_int_check && input_size_check

		#update the bytes to take into the acount original size + appendix
		input[3] = (input[3].to_i + database[key].byte_size.to_i).to_s

		#the "1" is to make the set command append the new strings
		set_command(input, connection, database, '2')

	#key not found but parameter count is ok
	elsif !database.key?(key) && input_int_check && input_size_check 

		byte_size = input[3].to_i
		disposable_string = get_input(connection, '1')

		if disposable_string.length == byte_size 
			connection.puts ResponseStrings.not_stored

		else
			connection.puts ResponseStrings.bad_data #string doesn't matches the byte_size
		end

	elsif !input_int_check && input_size_check && !input.nil?
		connection.puts ResponseStrings.client_error

	else
		connection.puts ResponseStrings.error
	end
end
