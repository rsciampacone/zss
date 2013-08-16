$:.push File.expand_path("../lib", __FILE__)
require 'z_sorted_set'

Gem::Specification.new do |s|
	s.name        = 'z_sorted_set'
	s.version     = ZSortedSet::VERSION
	s.date        = '2013-08-14'
	s.summary     = "Redis style sorted set data structure"
	s.description = "Sorted set data structure that takes score/member pairs, and orders against score (unique members).  Redis style operations permitted"
	s.authors     = ["Ryan Sciampacone"]
	s.email       = 'rsciampacone@gmail.com'
	s.homepage    = 'http://github.com/rsciampacone/zss'
    
	s.files         = `git ls-files`.split("\n")
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
	s.require_paths = ["lib"]
	
	s.license		= 'EPL v1.0'
end
