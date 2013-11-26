require_relative 'base'

x=[1,2,3,4]

class FooBar
	def initialize
		@var = "Hello there"
		p @var
	end

	def foo
		def bar;	p	"bar";	end
		p "foo"
	end
end

x=FooBar.new

x.foo
x.bar
