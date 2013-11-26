require_relative 'base'

class Link
	attr_reader :nodes

	def initialize ( node1, node2 )
		(@nodes=[node1, node2]).each {|n| n.links<<self}
		@snapshot = []
		@selected_count=0
	end
	def destroy;	@nodes.each {|n| n.links.delete(self)}	end
	def inspect;	"L{#{@nodes[0]}-#{@nodes[1]}}";	end

	def select;		@selected_count += 1; end
	def deselect;	@selected_count -= 1; end
	def selected?;	@selected_count>0 ? @selected_count : false;	end

	def draw_data
		color = @selected_count>0 ? Color::SelectedLink : Color::Link
		zorder = @selected_count>0 ? ZOrder::SelectedLinks : ZOrder::Links
		[@nodes[0].x, @nodes[0].y, color, @nodes[1].x, @nodes[1].y, color, zorder, mode=:default]
	end

	def draw(window)
		x1, y1, c1, x2, y2, c2, z, mode = *draw_data
		window.draw_line(x1, y1, c1, x2, y2, c2, z, mode)
		window.draw_line(x1+1, y1, c1, x2+1, y2, c2, z, mode)
		window.draw_line(x1, y1+1, c1, x2, y2+1, c2, z, mode)
		window.draw_line(x1-1, y1, c1, x2-1, y2, c2, z, mode)
		window.draw_line(x1, y1-1, c1, x2, y2-1, c2, z, mode)
	end
	def update;	end

	def x;	@nodes.collect {|n| n.x};	end
	def y;	@nodes.collect {|n| n.y};	end

	def intersects?(link)
		all_nodes = [@nodes, link.nodes].flatten
		return false if all_nodes.detect{|n| all_nodes.count(n)>1}

		dx10 = x[1] - x[0];				dy10 = y[1] - y[0];
		dx32 = link.x[1] - link.x[0];	dy32 = link.y[1] - link.y[0];
		dx02 = x[0] - link.x[0];		dy02 = y[0] - link.y[0];

		s = (-dy10 * (dx02) + dx10 * (dy02)) / (-dx32 * dy10 + dx10 * dy32)
		t = ( dx32 * (dy02) - dy32 * (dx02)) / (-dx32 * dy10 + dx10 * dy32)

		if (s >= 0 && s <= 1 && t >= 0 && t <= 1)
			#/ Collision detected
			#i_x = x[0] + (t * dx10)
			#i_y = y[0] + (t * dy10)
			return true
		else
			return false #/ No collision
		end

	end
end
