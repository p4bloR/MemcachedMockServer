# The user can save and get MemObjects
class MemObject
	#necessary accessors for variables
	attr_accessor :key
	attr_accessor :value
	attr_accessor :flag
	attr_accessor :byte_size
	attr_accessor :casSeed
	attr_accessor :cas_id
	attr_accessor :exp_time

	@@casSeed = 0 #unique cas id

	def initialize(key, flag, exp_time, byte_size, value = '')
	#each MemObject has a key, flag, expiretime, byte_size and value
	@key = key
	@value = value
	@flag = flag
	@exp_time = exp_time
	@byte_size = byte_size
	@cas_id = MemObject.update_cas
	end
  #each Memcached Object has an unique cas seed
	def self.update_cas
		@@casSeed += 1
		return @@casSeed
	end
end
