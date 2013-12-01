require_relative 'base'
require_relative 'graph'
require_relative 'text'

class PlaneMe < Gosu::Window

	attr_reader :font

	def initialize
		super Conf::XSize, Conf::YSize, false
		self.caption = "PlaneMe"

		@font = Gosu::Font.new(self, Gosu::default_font_name, 20)
		@node_image = ['node.png', 'node_sel.png'].map { |f| Gosu::Image.new(self, f, false) }
		@events = TimedEvents.new

		@key_actions = {
			'c' => [Proc.new { action_check }, "Check planarity"],
			'g' => [Proc.new { action_group_nodes }, "Group selection"], 
			'n' => [Proc.new { start_level(@level+=1) }, "Next level"], 
			'p' => [Proc.new { @graph.pause}, "Pause"], 
			'r' => [Proc.new { @graph.resume}, "Resume"], 
			'q' => [Proc.new { exit }, "Quit"]
		}
		
		@text_panel =  { }
		@text_panel[:messages] = TextArray.new(10, Conf::YSize-30, :direction=>:up, :size=>0.9, :color=>Color::Shade)
		@text_panel[:messages] << "Welcome to the game!"

		@text_panel[:key_actions] = TextArray.new(Conf::XSize-180, 10)
		@key_actions.each { |key, val| @text_panel[:key_actions] << "'#{key}' #{val[1]}" }

		@text_panel[:level] = TextArray.new(10, 10, :size=>1.2) << proc {"Level: #{@level} - Score: #{@score}"}
		@text_panel[:bonus] = TextArray.new(10, 35) << proc {"Bonus: #{@graph.score}"}

		@score = 0
		start_level(@level = 1)
	end

	def action_check
		inter = @graph.get_intersection
		if inter
			inter.each { |e| e.select }
			@events.set(:intersect, 2) { inter.each{|e|e.deselect} }
		else
			cur_score = @graph.score 
			@score += cur_score
			@text_panel[:messages].unshift  "Level #{@level} scored #{cur_score} pts"
			start_level(@level+=1)
		end
	end

	def action_empty_selection;	@status[:selected_nodes].delete_if {|n| n.deselect(false) };	end

	def action_group_nodes
		return false if @status[:selected_nodes].size < 3
		inter = @graph.group( @status[:selected_nodes] )
		if inter	# grouping failed, inter=intersecting links
			inter.each { |e| e.select }
			@events.set(:intersect, 2) { inter.each{|e|e.deselect} }
		else
			action_empty_selection
		end
	end

	def start_level(level)
		@level=level
		@graph.kill if @graph
		@graph = PlanarGraph.new(@level, @node_image)

		@status = {
			:moving_node 		=> nil,
			:selected_nodes		=> [],
		}
	end

	def update
		@events.update
		@graph.update
		@text_panel.each_value { |txt| txt.update }
	end

	def draw
		@status[:moving_node].position=[mouse_x, mouse_y] if @status[:moving_node]
		@graph.draw(self)
		@text_panel.each_value { |txt| txt.draw(self) }
	end

	def closest_node(x=mouse_x, y=mouse_y)
		distance = (Node.radius+6)**2
		begin
			select = @graph.nodes.reject { |node| node.metric(mouse_x, mouse_y)>distance }
			distance -= 2
		end while (select.size() > 1 and distance>0)
		return select[0]
	end

	def button_down(id)
		if (action = @key_actions[ button_id_to_char(id) ])
			action[0].call
		else
			node = closest_node
			case id
				when Gosu::MsLeft
					(@status[:moving_node]=node).select(true)
					# also, disable intersection highlighting if active
					@events.force :intersect
				when Gosu::MsRight
					if @status[:selected_nodes].include? node
						@status[:selected_nodes].delete(node).deselect(false)
					else
						@status[:selected_nodes] << node
						node.select(false)
					end
			end if node
		end
	end

	def button_up(id)
		case id
		when Gosu::MsLeft
			if @status[:moving_node] 
				@status[:moving_node].move_to(Conf::XSize/2,Conf::YSize/2,0.5) unless (0..Conf::XSize)===mouse_x and (0..Conf::YSize)===mouse_y
				@status[:moving_node].deselect(true) 
				@status[:moving_node] = nil
			end
		end
	end

	def needs_cursor?;	true;	end
end

window = PlaneMe.new
window.show
