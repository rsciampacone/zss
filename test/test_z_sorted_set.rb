
$:.push File.expand_path("../lib", File.dirname(__FILE__))

require 'minitest'
require 'minitest/autorun'
require 'z_sorted_set'

class TestZSortedSet < Minitest::Test
	def test_dummy
		assert true
	end
end
