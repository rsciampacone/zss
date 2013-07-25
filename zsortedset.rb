class ZSortedSet
	class Node
		def initialize(key, value)
			@level = []
			@key = key
			@value = value
		end
		
		attr_reader :key
		attr_accessor :value
		
		def [](index)
			level[index]
		end
		
		def []=(index, node)
			level[index] = node
		end
	end

	def initialize
		@head = Node.new(nil, nil)
		@max_level = 10
		@rand = Random.new
	end

	def add(key, value)
		stack = []
		c_node = @head		
		@max_level.downto(0) do | level |
			n_node = c_node[level]
			
			until n_node.nil? do 
				if key >= n_node.key then
					break
				end
				p_node = c_node
				c_node = n_node
				n_node = p_node[level]
			end
			stack[level] = c_node
		end
		
		# n_node should now contain either the identical key or the one to be
		# inserted ahead of
		if not n_node.is_nil? and key == node.key then
			n_node.value = value
		else
			node = Node.new(key, value)
			bits = @rand.rand(2 ** @max_level)
			level = 0
			until 0 == (bits & 1) do
				node[level] = stack[level][level]
				stack[level][level] = node
				bits >>= 1
				level += 1
			end
		end
	end
end
		