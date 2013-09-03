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
	def confirm_membership(sortedset, orig_membership_list)
		membership_list = orig_membership_list.clone
		sortedset.each do | score, member |
			raise "SortedSet contained member that wasn't expected #{member}" if membership_list[member].nil?
			raise "SortedSet member mismatched against score (ss: #{score} expected: #{membership_list[member]})" if score != membership_list[member]
			membership_list.delete(member)
		end
		raise "SortedSet did not contain all expected members #{membership_list}" if membership_list.size != 0
	end

	def generate_create_sortedset_procs
		[
			# Basic implementation
			Proc.new { ZSortedSet.new },

			# Fair distribution for node levels
			Proc.new {
				zss = ZSortedSet.new
				zss.instance_eval {
					@skiplist.instance_eval {
						# Sanity - are we redefining the right thing?  (invoking the method to see if it exists)
						generate_new_node_level

						def generate_new_node_level
							level = @r_gen.rand(@max_level + 1)
							raise "Calculated height for new node exceeded @max_level limits #{level} => #{@max_level}" if level > @max_level
							level
						end
					}
				}
				zss
			},

			# Simple case - all nodes are level 0
			Proc.new {
				zss = ZSortedSet.new
				zss.instance_eval {
					@skiplist.instance_eval {
						# Sanity - are we redefining the right thing?  (invoking the method to see if it exists)
						generate_new_node_level

						def generate_new_node_level
							0
						end
					}
				}
				zss
			},

			# Simple case (other extreme) - all nodes are level @max_level
			Proc.new {
				zss = ZSortedSet.new
				zss.instance_eval {
					@skiplist.instance_eval {
						# Sanity - are we redefining the right thing?  (invoking the method to see if it exists)
						generate_new_node_level

						def generate_new_node_level
							@max_level
						end
					}
				}
				zss
			},
		]
	end

	def build_list_permutations(list)
		[
			list,
			list.reverse,
			list_as_binary_tree(list),
		]
	end

	def list_as_binary_tree(list)
		return [] if list.empty?
		binary_list = []
		queue = [[0, list.size - 1]]
		until queue.empty? do
			range = queue.shift
			low = range[0]
			high = range[1]
			middle = (low + ((high - low) / 2)).floor
			binary_list.push(list[middle])
			queue.push([low, middle - 1]) if low != middle
			queue.push([middle + 1, high]) if middle != high
		end
		binary_list
	end

	def generate_populate_sortedset_procs(orig_list)
		build_list_permutations(orig_list).map do | list |
			Proc.new { | sortedset, member_verification |
				list.each do | pair |
					sortedset.add(pair[0], pair[1])
					member_verification[pair[1]] = pair[0]
					sortedset.dbg_verify
					confirm_membership(sortedset, member_verification)
				end
			}
		end
	end

	def generate_trim_sortedset_procs(orig_list)
		build_list_permutations(orig_list).map do | list |
			Proc.new { | sortedset, member_verification |
				list.each do | pair |
					sortedset.remove(pair[1])
					member_verification.delete(pair[1])
					sortedset.dbg_verify
					confirm_membership(sortedset, member_verification)
				end
			}
		end
	end

	def run_add_and_delete_testing(primary_list, removal_list, add_list)
		# Validate inputs (more or less)
		primary_list.map { | elt | raise "Inputs must be array pairs" if (not elt.instance_of? Array) or (elt.size != 2) }
		removal_list.map { | elt | raise "Inputs must be array pairs" if (not elt.instance_of? Array) or (elt.size != 2) }
		add_list.map { | elt | raise "Inputs must be array pairs" if (not elt.instance_of? Array) or (elt.size != 2) }

		generate_create_sortedset_procs.each do | creator |
			generate_populate_sortedset_procs(primary_list).each do | populator |
				generate_trim_sortedset_procs(removal_list).each do | trimmer |
					generate_populate_sortedset_procs(add_list).each do | repopulator |
						member_verification = {}

						sortedset = creator.()
						sortedset.dbg_verify()

						populator.(sortedset, member_verification)
						sortedset.dbg_verify()

						trimmer.(sortedset, member_verification)
						sortedset.dbg_verify()

						repopulator.(sortedset, member_verification)
						sortedset.dbg_verify()
					end
				end
			end
		end
	end

	def test_empty_list_remove
		run_add_and_delete_testing([], [[50, "doesnt exist"]], [[1000, "something else"]])
	end

	def test_basic_add_and_delete
		run_add_and_delete_testing([[100, "one"]], [[100, "one"]], [[100, "one"]])
	end

	def test_simple_add_and_delete
		simple_inputs = [
				[100, "one"],
				[200, "two"],
				[300, "three"]
			]
		run_add_and_delete_testing(simple_inputs, simple_inputs, simple_inputs)
	end

	def test_standard_add_and_delete
		run_add_and_delete_testing(
			# Initial list
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
			],
			# Remove list
			[
				[ 50, "one"],
				[100, "three"],
				[150, "five"],
				[225, "seven"],
				[325, "nine"],
				[450, "ten"],
				[500, "twelve"],
				[900, "fourteen"],
				[975, "sixteen"],
			],
			# Add list
			[
				[25, "addstartone"],
				[50, "addstarttwo"],
				[75, "addstartthree"],
				[452, "addmiddle"],
				[960, "addendone"],
				[975, "addendtwo"],
				[999, "addendthree"]
			]

		)
	end

	def test_basic_rank
		assert_nil ZSortedSet.new.rank("foobar")
	end

	def test_simple_rank
		zss = ZSortedSet.new
		zss.add(100, "one")
		assert_same(zss.rank("one"), 0)
		assert_nil(zss.rank("two"))
	end

	def test_standard_rank
		zss = ZSortedSet.new
		list = [
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
		list.each {|pair| zss.add(*pair)}

		list.sort.each_with_index do |pair, index|
			assert_same(zss.rank(pair[1]), index)
		end
	end
end
