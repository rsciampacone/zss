# This software is provided under the Eclipse Public Licence (EPL).
# http://www.eclipse.org/org/documents/epl-v10.php
# Author: Ryan Sciampacone
#

class ZSortedSet
	VERSION = "0.0.1"
end

class ZSkipList
	@@dbg = false

	class Node
		def initialize(score, member, max_level)
			@skip_stack = []
			@width = [0] * (max_level + 1)
			@score = score
			@member = member
		end
		
		attr_reader :score
		attr_accessor :member
		attr_reader :width
		
		def [](index)
			@skip_stack[index]
		end
		
		def []=(index, node)
			@skip_stack[index] = node
		end
	end

	def initialize
		@max_level = 10
		@size = 0
		@head = Node.new(nil, nil, @max_level)
		@r_gen = Random.new
	end

	attr_reader :size

	# Find the either equal or the closest "next" node in comparison to _score_ followed
	# (if supplied) by _member_.
	#
	# returns:
	# c_node   Last node found that is lower in comparison to the _score_
	# n_node   Next equal or higher comparison node in the list
	# stack    All prior nodes in the skip stack that are the next lowest compared to the score
	# width_stack  The cumulative width traveled at that stack level before dropping to a lower level
	# 
	def find_node(score, member=nil)
		c_node = @head	
		n_node = nil	
		stack = []
		width_stack = [0] * (@max_level + 1)
		@max_level.downto(0) do | level |
			n_node = c_node[level]
			
			until n_node.nil? do 
				# We have found our position when either the next score is greater than the search
				# score OR when given an equal next score that the search member is less than the next
				# member.
				if score < n_node.score then
					break
				elsif score == n_node.score then
					if member.nil? || member <= n_node.member then
						break
					end
				end
				$stdout.write " #{level}{#{c_node.score},#{n_node.score},#{c_node.width[level]}}" if @@dbg

				width_stack[level] += c_node.width[level]
				c_node = n_node
				n_node = c_node[level]
			end
			stack[level] = c_node
		end
		puts if @@dbg
		return n_node, c_node, stack, width_stack
	end
	private :find_node
	
	def add(score, member)
		n_node, c_node, stack, width_stack = find_node(score)
		
		# n_node should now contain either the identical score or the one to be
		# inserted ahead of
		if not n_node.nil? and score == n_node.score then
			n_node.member = member
		else
			node = Node.new(score, member, @max_level)
			bits = @r_gen.rand(2 ** @max_level)

			# We ignore the first bit here in the interest of building
			# a linear list at the bottom level
			cumulative_width = 0
			level = 0
			begin
				# Node level connections
				node[level] = stack[level][level]
				stack[level][level] = node
				
				# Node width adjustments
				node.width[level] = node[level].nil? ? 0 : stack[level].width[level] - cumulative_width
				stack[level].width[level] = cumulative_width + 1
				cumulative_width += width_stack[level]

				# Look to the next / bit level and decide if the node stack grows deeper
				bits >>= 1
				level += 1
			end until 0 == (bits & 1)
			# To account for the new node insert, all remaining levels above the new nodes calculated
			# max level need their width incremented
			level.upto(@max_level) do | inc_level |
				stack[inc_level].width[inc_level] += 1 unless stack[inc_level].width[inc_level] == 0
			end
			@size += 1
		end
	end

	def remove(score)
		n_node, c_node, stack = find_node(score)
		
		if not n_node.nil? and score == n_node.score then
			# n_node is to be removed.  reconnect the skip stack to the succeeding node
			# (if this node was involved at the skip level)
			#
			0.upto(@max_level) do | level |
				if n_node == stack[level][level] then
					# Node level connections
					stack[level][level] = n_node[level]

					# Node width adjustments
					if n_node[level].nil? then
						# We deleted the last node in the chain - previous width is now 0
						stack[level].width[level] = 0
					else
						# There is a node which succeeds this one in the level chaining
						stack[level].width[level] += n_node.width[level] - 1
					end
				elsif stack[level].width[level] != 0 then
					# Doesn't appear in the level chain BUT deleting this node does affect
					# the width distance
					stack[level].width[level] -= 1
				end
			end
			@size -= 1
		end
	end
 
 
 	def dbg_verify_list
 		node = @head
 		score = nil
 		until node.nil?
 			0.upto(@max_level) do | level |
 				if node[level].nil? then
 					if node.width[level] != 0 then
 						raise RuntimeError, "Node #{node} has nil next node at level #{level} but has non-zero width #{node.width[level]}"
 					end
 				else
 					dbg_verify_width(node, node[level], level, node.width[level])
 				end
 			end
 			if not score.nil?
 				if score > node.score then
 					raise RuntimeError, "Score #{score} is not <= node #{node} score #{node.score}"
 				end
 			end
 			score = node.score
 			node = node[0]
 		end
 	end
 
 	def dbg_verify_width(root_node, projected_node, level, width)
 		node = root_node
 		until width == 0
 			if node.nil?
	 			raise RuntimeError, "Node #{root_node} at level #{level} lead to nil before reaching projected node #{projected_node}"
	 		end
	 		if node == projected_node then
	 			raise RuntimeError, "Node #{root_node} at level #{level} found projected node #{projected_node} early with #{width} remaining"
	 		end
 			node = node[0]
 			width -= 1
 		end
 		if node != projected_node then
 			raise RuntimeError, "Node #{root_node} lead to #{node} for width #{width} at level #{level} which did not reach projected node #{projected_node}"
 		end
 	end
 
	def dbg_dump_list
		puts "---> START LIST DUMP"
		puts "Size: #{@size}"
		
		puts "== Elements in order using 0-level link"
		node = @head[0] # skip the head sentinel
		until node.nil?
			puts "N:#{node} {S:#{node.score}, M:#{node.member}}"
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

			$stdout.write "   "

			check_parent_should_be_nil = false
			0.upto(@max_level) do | level |
				width = node.width[level]
				if width.nil?
					$stdout.write " %5d" % [0]
					check_parent_should_be_nil = true
				else
					if check_parent_should_be_nil then
						$stdout.write " %5d" % [-1]
					else
						$stdout.write " %5d" % width
					end
				end
			end
			
			puts " #{node}"
			node = node[0]
		end

		puts "<--- END LIST DUMP"
		dbg_verify_list
	end
end

=begin
z = ZSkipList.new
z.add("andrew", 200)
z.dbg_dump_list
z.add("ryan", 100)
z.dbg_dump_list
z.add("sciampacone", 300)
z.dbg_dump_list
z.add("vanessa", 100)
z.dbg_dump_list
z.add("maya", 200)
z.dbg_dump_list
z.add("debra", 500)
z.dbg_dump_list
z.add("jean", 50)
z.dbg_dump_list
z.add("rae", 900)
z.dbg_dump_list
z.add("ann", 500)
z.dbg_dump_list
z.add("rachel", 150)
z.dbg_dump_list
z.add("tony", 325)
z.dbg_dump_list
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
=end