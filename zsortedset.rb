class ZSkipList
	class Node
		def initialize(key, value)
			@skip_stack = []
			@key = key
			@value = value
		end
		
		attr_reader :key
		attr_accessor :value
		
		def [](index)
			@skip_stack[index]
		end
		
		def []=(index, node)
			@skip_stack[index] = node
		end
	end

	def initialize
		@head = Node.new(nil, nil)
		@size = 0
		@max_level = 10
		@r_gen = Random.new
	end

	attr_reader :size

	# Find the node which matches _key_
	# returns:
	# c_node   Last node found that is lower in comparison value to the _key_
	# n_node   Next equal or higher comparison node in the list
	# stack    All prior nodes in the skip stack that are the next lowest compared to the key
	# 
	def find_node(key)
		stack = []
		c_node = @head	
		n_node = nil	
		@max_level.downto(0) do | level |
			n_node = c_node[level]
			
			until n_node.nil? do 
				if key <= n_node.key then
					break
				end
				p_node = c_node
				c_node = n_node
				n_node = p_node[level]
			end
			stack[level] = c_node
		end
		
		return n_node, c_node, stack
	end
	private :find_node
	
	def add(key, value)
		n_node, c_node, stack = find_node(key)
		
		# n_node should now contain either the identical key or the one to be
		# inserted ahead of
		if not n_node.nil? and key == n_node.key then
			n_node.value = value
		else
			node = Node.new(key, value)
			bits = @r_gen.rand(2 ** @max_level)
			# We ignore the first bit here in the interest of building
			# a linear list at the bottom level
			level = 0
			begin
				node[level] = stack[level][level]
				stack[level][level] = node
				bits >>= 1
				level += 1
			end until 0 == (bits & 1)
			
			@size += 1
		end
	end

	def remove(key)
		n_node, c_node, stack = find_node(key)
		
		if not n_node.nil? and key == n_node.key then
			# n_node is to be removed.  reconnect the skip stack to the succeeding values
			# (if this node was involved at the skip level)
			#
			0.upto(@max_level) do | level |
				if n_node == stack[level][level] then
					stack[level][level] = n_node[level]
				end
			end
			@size -= 1
		end
	end
 
	def dbg_dump_list
		puts "---> START LIST DUMP"
		puts "Size: #{@size}"
		
		puts "== Elements in order using 0-level link"
		node = @head[0] # skip the head sentinel
		until node.nil?
			puts "N:#{node} {K:#{node.key}, V:#{node.value}}"
			node = node[0]
		end
		
		puts "== Skip list structure"
		next_node_stack = []
		0.upto(@max_level) do | level |
			next_node_stack[level] = @head[level]
			$stdout.write "-"
		end
		puts

		node = @head
		until node.nil? do
			check_parent_should_be_nil = false

			0.upto(@max_level) do | level |
				if next_node_stack[level].nil? then
					$stdout.write " "
					check_parent_should_be_nil = true					
				else
					if check_parent_should_be_nil then
						$stdout.write "E"
					else
						if node == next_node_stack[level] then
							$stdout.write "+"
							next_node_stack[level] = node[level]
						else
							$stdout.write (node == @head ? "+" : "|")
						end
					end
				end
			end
			puts " #{node}"
			node = node[0]
		end

		puts "<--- END LIST DUMP"
	end
end

z = ZSkipList.new
z.add("ryan", 100)
z.add("andrew", 200)
z.add("sciampacone", 300)
z.dbg_dump_list
z.add("vanessa", 100)
z.add("maya", 200)
z.add("debra", 500)
z.add("jean", 50)
z.add("rae", 900)
z.add("ann", 500)
z.add("rachel", 150)
z.add("tony", 325)
z.add("anthony", 450)
z.dbg_dump_list
z.remove("maya")
z.dbg_dump_list
z.remove("andrew")
z.dbg_dump_list
z.remove("vanessa")
z.dbg_dump_list
z.add("ryan", 100)
z.add("andrew", 200)
z.add("sciampacone", 300)
z.add("vanessa", 100)
z.add("maya", 200)
z.add("debra", 500)
z.add("jean", 50)
z.add("rae", 900)
z.add("ann", 500)
z.add("rachel", 150)
z.add("tony", 325)
z.add("anthony", 450)
z.dbg_dump_list
z.remove("ryan")
z.remove("andrew")
z.remove("sciampacone")
z.remove("vanessa")
z.remove("maya")
z.remove("debra")
z.remove("jean")
z.remove("rae")
z.remove("ann")
z.remove("rachel")
z.remove("tony")
z.remove("anthony")
z.dbg_dump_list
