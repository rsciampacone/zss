# This software is provided under the Eclipse Public Licence (EPL).
# http://www.eclipse.org/org/documents/epl-v10.php
# Author: Ryan Sciampacone
#

module DebugZSortedSet
	def dbg_verify
		@skiplist.dbg_verify

		members_found = {}
		@skiplist.each do | score, member |
			raise "Skiplist contains duplicate member #{member}" if not members_found[member].nil?
			raise "Skiplist score didn't match Hash score for #{member}: SL:#{score} KS:#{@keystore[member]}" if score != @keystore[member]
			raise "Keystore doesn't contain member from skiplist #{member}" if @keystore[member].nil?

			members_found[member] = score
		end

		raise "Mismatch member count between skiplist (#{members_found.size}) vs. keystore (#{@keystore.size}" if members_found.size != @keystore.size
	end
end

module DebugZSkipList
 	def dbg_verify
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
 		true
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
		dbg_verify
	end
end