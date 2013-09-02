# This software is provided under the Eclipse Public Licence (EPL).
# http://www.eclipse.org/org/documents/epl-v10.php
# Author: Ryan Sciampacone
#

class ZSortedSet
	VERSION = "0.0.1"

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
			initialize_generate_new_node_level
		end

		attr_reader :size

		def each
			if block_given? then
				node = @head[0]
				until node.nil? do
					yield node.score, node.member
					node = node[0]
				end
				self
			else
				Enumerator.new { | yielder |
					node = @head[0]
					until node.nil? do
						yielder.yield node.score, node.member
						node = node[0]
					end
				}
			end
		end

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

		def initialize_generate_new_node_level()
			@r_gen = Random.new
		end
		private :initialize_generate_new_node_level

		def generate_new_node_level()
			level = 0
			bits = @r_gen.rand(2 ** @max_level)
			until 0 == (bits & 1)
				bits >>= 1
				level += 1
			end
			raise "Calculated height for new node exceeded @max_level limits #{level} => #{@max_level}" if level > @max_level
			level
		end
		private :generate_new_node_level

		def add(score, member)
			n_node, c_node, stack, width_stack = find_node(score, member)

			# Sanity check
			raise "Adding a member that already exists [#{score} #{member}]" if not n_node.nil? and n_node.member == member
			
			node = Node.new(score, member, @max_level)
			new_node_level = generate_new_node_level()

			# We ignore the first bit here in the interest of building
			# a linear list at the bottom level
			cumulative_width = 0
			0.upto(new_node_level) do | level |
				# Node level connections
				node[level] = stack[level][level]
				stack[level][level] = node
				
				# Node width adjustments
				node.width[level] = node[level].nil? ? 0 : stack[level].width[level] - cumulative_width
				stack[level].width[level] = cumulative_width + 1
				cumulative_width += width_stack[level]
			end

			# To account for the new node insert, all remaining levels above the new nodes calculated
			# max level need their width incremented
			(new_node_level + 1).upto(@max_level) do | inc_level |
				stack[inc_level].width[inc_level] += 1 unless stack[inc_level].width[inc_level] == 0
			end
			@size += 1
		end

		def remove(score, member)
			n_node, c_node, stack = find_node(score, member)
			
			# Sanity check
			raise "Removing a member that doesn't exists [#{score} #{member}]" if not n_node.nil? and (n_node.score != score or n_node.member != member)

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

	def initialize
		@skiplist = ZSkipList.new
		@keystore = Hash.new
	end

	def each(&block)
		@skiplist.each &block
	end

	def add(score, member)
		if not (old_score = @keystore[member]).nil?
			@skiplist.remove(oldscore, member)
		end
		@keystore[member] = score
		@skiplist.add(score, member)
	end

	def remove(member)
		if not (old_score = @keystore[member]).nil?
			@skiplist.remove(old_score, member)
			@keystore.delete(member)
			old_score
		end
	end
end
