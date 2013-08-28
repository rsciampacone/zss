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
		[ Proc.new { ZSortedSet.new } ]
	end

	def generate_populate_sortedset_procs(list)
		[ Proc.new { | sortedset, member_verification |
			list.each do | pair |
				sortedset.add(pair[0], pair[1])
				member_verification[pair[1]] = pair[0]
				sortedset.dbg_verify
				confirm_membership(sortedset, member_verification)
			end }
		]
	end

	def generate_trim_sortedset_procs(list)
		[ Proc.new { | sortedset, member_verification |
			list.each do | pair |
				sortedset.remove(pair[1])
				member_verification.delete(pair[1])
				sortedset.dbg_verify
				confirm_membership(sortedset, member_verification)
			end }
		]
	end

	def run_add_and_delete_testing
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

	def primary_list
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

	def removal_list
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
		]
	end

	def add_list
		[
			[25, "addstartone"],
			[50, "addstarttwo"],
			[75, "addstartthree"],
			[452, "addmiddle"],
			[960, "addendone"],
			[975, "addendtwo"],
			[999, "addendthree"]
		]
	end

	def test_basic_add_and_delete
		run_add_and_delete_testing
	end
end
