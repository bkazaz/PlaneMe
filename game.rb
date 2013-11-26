require_relative 'base'
require_relative 'graph'

class GameWindow < Gosu::Window

	attr_reader :font, :messages

	def initialize
		super Conf::XSize, Conf::YSize, false
		self.caption = "Planarity"

		@font = Gosu::Font.new(self, Gosu::default_font_name, 20)
		@events = TimedEvents.new
		@messages = ["Welcome to planarity!"]

		@node_image = ['red_circle.png', 'red_circle_sel.png'].map { |f| Gosu::Image.new(self, f, false) }

		@score = 0
		start_level(@level = 1)
	end

	def action_check
		inter = @graph.get_intersection
		if inter
			inter.each { |e| e.select }
			@events.set(:intersect, 2) { inter.each{|e|e.deselect} }
		else
			cur_score = @graph.score(Time.now - @level_started) 
			@score += cur_score
			@messages.unshift  "Level #{@level} scored #{cur_score} pts"
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
		@graph = PlanarGraph.new(@level, @node_image)
		@level_started = Time.now

		@status = {
			:moving_node 		=> nil,
			:selected_nodes		=> [],
		}

		@key_actions = {
			'c' => [Proc.new { action_check }, "Check planarity"],
			#'e' => [Proc.new { action_empty_selection }, "Empty selection"],
			'g' => [Proc.new { action_group_nodes }, "Group selection"], 
			#'n' => [Proc.new { start_level(@level+=1) }, "Next level"], 
			#'p' => [Proc.new { start_level(@level-=1) if @level>1 }, "Previous level"], 
			#'s' => [Proc.new { @graph.shuffle }, "Shuffle"],
			'q' => [Proc.new { exit }, "Quit"]
		}
	end

	def update
		@events.update
		@graph.nodes.each { |node| node.update }
		#@graph.links.each { |link| link.update }
	end

	def draw
		dt = Time.now-@level_started
		@font.draw("Level: #{@level} - Score: #{@score}", 10, 10, ZOrder::UI, 1.2, 1.2, Color::Text)
		@font.draw("Gain: #{@graph.score(dt)}", 10, 35, ZOrder::UI, 1.0,1.0, Color::Text)

		next_pos = @key_actions.inject(10) { |pos,(key,val)|
			@font.draw("'#{key}' #{val[1]}", Conf::XSize-180, pos, ZOrder::UI, 1.0, 1.0, Color::Text); pos+20
		}

		@status[:moving_node].setpos(mouse_x, mouse_y) if @status[:moving_node]
		@graph.links.each { |link| link.draw(self) }
		@graph.nodes.each { |node| node.draw(self) }

		@messages.each_index do |i|
			break if i == Color::Shade.size
			py = Conf::YSize-30 - 18*i
			@font.draw("#{@messages[i]}", 10, py, ZOrder::Background, 0.9, 0.9, Color::Shade[i])
		end
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

window = GameWindow.new
window.show
