require_relative 'base'
require_relative 'movable'

class Node
	include Movable

	attr_accessor :links
	attr_accessor :position

	def x;	position[0];	end
	def y;	position[1];	end

	@@radius = 10
	class << self
		def radius;		@@radius;	end
		def radius=;	@@radius=r;	end
	end

	def initialize (imgs, x0=0, y0=0)
		@position=[x0,y0]
		#raise "Bad argument" if @position.any? {|c| not c.is_a? Numeric }
		@links = []
		@select_count = 0
		@images = imgs
		$log.debug { self } 
	end
	def inspect;	"Node:(#{x.to_i}, #{y.to_i})";	end
	#def links;	return @links;	end

	def links_to?(node);	@links.any? { |link| link.nodes.include? node };	end

	def selected?; return @select_count>0;	end
	def select(propagate=true)
		@select_count += 1
		@links.each do |link|
			link.select
			link.nodes.each {|node| node.select(false) if node != self }
		end if propagate
		return @select_count
	end
	def deselect(propagate=true)	
		@select_count -= 1
		@links.each do |link|
			link.deselect
			link.nodes.each {|node| node.deselect(false) if node != self }
		end if propagate
		return @select_count
	end

	def draw(window)
		zorder = @select_count>0 ? ZOrder::SelectedNodes : ZOrder::Nodes
		img = @images[ @select_count>0 ? 1 : 0]
		x0, y0 = x-img.width/2, y-img.height/2
		img.draw(x0, y0, zorder)
	end
	def update;	end

	def ds(n2);	metric(*n2.position);	end
	def metric(x0,y0);	(x0-x)**2 + (y0-y)**2;		end
end

class NodeGroup < Node
	attr_reader :n
	def initialize(imgs, x, y, n=2)
		@n=n
		super imgs, x, y
	end

	def draw(window)
		super
		color = @select_count>0 ? Color::SelectedNodeText : Color::NodeText
		window.font.draw("#{@n}", x-4, y-6, ZOrder::NodeText, 1, 1, color)
	end
end
