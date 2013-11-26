require_relative 'base'
require_relative 'movable'

class TextArray < Array
	include Movable

	attr_accessor :position
	attr_reader :opts

	def initialize (x=0, y=0, opts={})
		super()
		@position = [x,y]
		@status = true

		@opts = {:size=>1.0, :color=>Color::Text, :zorder=>ZOrder::UI, :direction=>:down}
		@opts = @opts.merge(opts)

		@opts[:size]  = [@opts[:size], @opts[:size]] unless @opts[:size].is_a? Array
		@opts[:color] = [ @opts[:color] ] unless @opts[:color].is_a? Array

		$log.debug { "#{@opts}, #{opts}"}
	end

	def enabled?; @status; end
	def disabled?; not @status; end
	def enable; @status=true;	end
	def disable; @status=false;	end

	def draw(window)	# no args necessary
		return false unless @status
		x0, y0, dy = *@position, 20*@opts[:size][1] * (@opts[:direction]==:down ? 1 : -1)
		colors = @opts[:color].size - 1
		self.each_index { |i| 
			y = y0 + i*dy
			c = colors==0 ? @opts[:color][0] : @opts[:color][i % colors]
			msg = self[i].respond_to?(:call) ? self[i].call : self[i] 		# messages can be blocks
			window.font.draw(msg, x0, y, @opts[:zorder], *@opts[:size], c)
		}	
	end

	def update;	end
end
