# This software is provided under the Eclipse Public Licence (EPL).
# http://www.eclipse.org/org/documents/epl-v10.php
# Author: Ryan Sciampacone
#

$:.push File.expand_path("../lib", File.dirname(__FILE__))

require 'minitest'
require 'minitest/autorun'
require 'z_sorted_set'
require 'debug_z_sorted_set'

# Enable debug capabilities to the implementation being tested
class ZSortedSet
	include DebugZSortedSet

	class ZSkipList
		include DebugZSkipList
	end
end

class TestZSortedSet < Minitest::Test
	def generate_create_sortedset_procs
		[ Proc.new { ZSortedSet.new } ]
	end

	def generate_populate_sortedset_procs(list)
		[ Proc.new { | sortedset | 
			list.each do | pair |
				sortedset.add(pair[0], pair[1])
				sortedset.dbg_verify
			end }
		]
	end

	def generate_trim_sortedset_procs(list)
		[ Proc.new { | sortedset |
			list.each do | pair |
				sortedset.remove(pair[1])
				sortedset.dbg_verify
			end }
		]
	end

	def generate_repopulate_sortedset_procs(list)
		[ Proc.new { | sortedset |
			list.each do | pair |
				sortedset.add(pair[0], pair[1])
				sortedset.dbg_verify
			end }
		]
	end

	def run_add_and_delete_testing(base_add_list)
		generate_create_sortedset_procs.each do | creator |
			generate_populate_sortedset_procs(base_add_list).each do | populator |
				generate_trim_sortedset_procs(base_add_list).each do | trimmer |
					generate_repopulate_sortedset_procs(base_add_list).each do | repopulator |
						sortedset = creator.()
						sortedset.dbg_verify()

						populator.(sortedset)
						sortedset.dbg_verify()

						trimmer.(sortedset)
						sortedset.dbg_verify()

						repopulator.(sortedset)
						sortedset.dbg_verify()
					end
				end
			end
		end
	end

	def basic_list
		[
			[ 50, "one"],
			[100, "two"],
			[100, "three"],
			[125, "four"],
			[150, "five"],
			[200, "six"],
			[225, "seven"],
			[300, "eight"],
			[325, "nine"],
			[450, "ten"],
			[450, "eleven"],
			[500, "twelve"],
			[750, "thirteen"],
			[900, "fourteen"],
			[950, "fifteen"],
			[975, "sixteen"],
		]
	end

	def test_basic_add_and_delete
		run_add_and_delete_testing(basic_list)
	end

	#
	# HACKS TO USE OR REMOVE?
	#
	def xxx_remove_list
		list = []
		length = active_list.size
		list += active_list[(active_list.size / 2).floor]
		list += active_list[((active_list.size / 4) * 1).floor]
		list += active_list[((active_list.size / 4) * 3).floor]
	end

	def xxx_generate_remove_order_index_list
		list = active_list
		list_size = active_list.size
		remove_order_index_list = []
		remove_order_index_list.push (list_size / 2).floor
		remove_order_index_list.push (list_size / 4).floor
		remove_order_index_list.push ((list_size / 4) * 3).floor
		remove_order_index_list.push 0
		remove_order_index_list.push list_size - 1
		remove_order_index_list
	end

	# Older test code used as a partial template
	def placeholder
		z = Zsortedset.new
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
	end
end
