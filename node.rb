require_relative 'base'

class Node
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
	def to_s;	"(%d,%d)" % [@x,@y];	end

	def links_to?(node);	@links.any? { |link| link.nodes.include? node };	end

	def setpos(x,y);	@x, @y = x, y;		end

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

	def move_to(px, py, delay, &when_done)
		@this_frame = Gosu::milliseconds
		@last_frame = @this_frame
		@tween = Tween.new([@x, @y], [px, py], Tween::Quart::InOut, delay)
		@done_code = block_given? ? when_done : nil

		$log.debug { "#{self} move_to #{[px.to_i,py.to_i]} in #{delay} secs" }

		def self.delta
			#$log.debug { "delta(): #{@tween}: #{@this_frame} - #{@last_frame}" }
			@this_frame = Gosu::milliseconds
			dt = (@this_frame - @last_frame)/1000.0
			@last_frame = @this_frame
			return dt
		end

		def self.update(*args)
			@tween.update(delta)
			@x, @y = @tween.x, @tween.y
			super
			if @tween.done
				$log.debug { "#{@tween} is done!" }
				class << self	
					remove_method :update
					remove_method :delta
				end
				@done_code.call if @done_code
				remove_instance_variable(:@this_frame)
				remove_instance_variable(:@last_frame)
				remove_instance_variable(:@tween)
				remove_instance_variable(:@done_code)
			end
		end
	end

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
