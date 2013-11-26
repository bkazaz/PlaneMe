require_relative 'base'
require_relative 'movable'

class Node
	include Movable

	attr_reader :x, :y
	attr_accessor :links

	@@radius = 10
	class << self
		def radius;		@@radius;	end
		def radius=;	@@radius=r;	end
	end

	def initialize (imgs, x=0, y=0)
		@x, @y = x, y
		@links = []
		@select_count = 0
		@images = imgs
		$log.debug { @images }
	end
	def inspect;	"(#{@x.to_i}, #{@y.to_i})";	end

	def links_to?(node);	@links.any? { |link| link.nodes.include? node };	end

	def position=(coords);	@x, @y = coords[0], coords[1];	end
	def position;	[@x,@y];	end

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
		x, y = @x-img.width/2, @y-img.height/2
		img.draw(x, y, zorder)
	end
	def update;	end

	def metric(x,y);	(x-@x)**2 + (y-@y)**2;		end
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
		window.font.draw("#{@n}", @x-4, @y-6, ZOrder::NodeText, 1, 1, color)
	end
end
