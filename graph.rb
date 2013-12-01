require_relative 'base'
require_relative 'link'
require_relative 'node'

class PlanarGraph
	def r(*x);	x.min+ (x[0]-x[1]).abs * rand;	end

	def initialize(level, imgs)
		@level = level.to_i 
		@images = imgs

		@nodes, @links = [], []
		@msg = "Generating...";	graphics_off

		@timer = Timer.new
		@graph_thread = make_graph
		@graph_thread.abort_on_exception = true
	end

	def pause;	@timer.pause;	@msg="Paused!"; graphics_off	end
	def resume;	@timer.start;	graphics_on;				end

	def graphics_off
		def self.ready?;	false; end
		def self.nodes; []; end
		def self.links; []; end
		def self.update;	end
		def self.draw(window)
			window.font.draw_rel(@msg, Conf::XSize/2, Conf::YSize/2, ZOrder::UI, 0.5,0.5, 2, 2, Color::Text)
		end
	end

	def graphics_on
		def self.draw(window); 	each_sprite { |sprite| sprite.draw(window)	};	end
		def self.update; 		each_sprite { |sprite| sprite.update		};	end
		class << self; attr_reader :nodes, :links; end
		def self.ready?;	true;	end
	end

	def each_sprite;	[@nodes, @links].each { |list| list.each { |item| yield item } }; end

	def make_graph
		Thread.new do 
			create_graph
			graphics_on
			@timer.start
			$log.debug { "Graph is ready!" }
		end
	end

	def kill;	@graph_thread.kill;	end

	def create_graph
		x0, y0 = 100, 100
		x1, y1 = Conf::XSize-x0, Conf::YSize-20
		counter=0
		while (@nodes.size-counter) < (@level+1)*(@level)+4 do
			[ 
				[[x0,r(y0,y1)],[x1,r(y0,y1)]],
				[[r(x0,x1),y0],[r(x0,x1),y1]]
			].each do |n1xy, n2xy|
				$log.debug { "New loop: #{n1xy} #{n2xy}" }
				counter += 2
				
				nodes = []
				nodes << Node.new(@images, *n1xy)
				nodes << Node.new(@images, *n2xy)
				
				# find all intersections
				newlink = Link.new(nodes[0], nodes[1])
				inter = @links.map { |l| [newlink.intersection(l), l] }
				inter.delete_if { |i,l| not i.is_in? }
				inter.map! { |xy,l| [ Node.new(@images,xy[0],xy[1]),l] }
				newlink.destroy	# this link is no longer necessary

				inter.each { |newnode,link|
					nodes << newnode
					# Create the new links and erase the old
					link.nodes.each { |n2| @links << Link.new(newnode, n2) }
					@links.delete(link).destroy
				}

				# sort nodes by distance from one of the outer nodes
				nodes.sort! { |n1,n2| n1.ds(nodes[0]) <=> n2.ds(nodes[0]) }	
				# and connect them
				nodes.each_cons(2) { |n1,n2| @links << Link.new(n1,n2) }
				@nodes += nodes
			end
		end

		outer_nodes = @nodes.select { |n| n.links.size < 2 }
		outer_nodes.each { |n| n.links.each { |l| @links.delete(l).destroy } }
		@nodes -= outer_nodes

		@msg = "Sorting...";
		@links.sort_by! { |l| l.nodes.map{|n|n.links.size}.min }
		@msg = "Clearing..."
		(@nodes.size - (@level+1)*(@level)-4).times do
			group( @links[-1].nodes, 
				  :no_group? => true, :now? => true, 
				  :groups_allowed? => true, :require_connected? => false, :allow_intersection? => true 
				 )	# the second line of options are just for speed
		end
		@msg = "Ready"
		shuffle()
	end

	def score
		max_score = @level * 200.0
		half_time = [1,(@nodes.size ** 1.2) * 1.0].max				# time it takes for score/=2
		return (@nodes.size*10 + max_score * 2.0 ** (-@timer.dt / half_time)).to_i
	end

	# Randomize the node's position and lay them on the screen
	def shuffle
		@nodes.shuffle!
		r, dt = [Conf::XSize, Conf::YSize].min/2 - 20, 2*Math::PI/@nodes.size
		@nodes.inject(0) { |t, node| node.move_to(Conf::XSize/2 + r*Math.cos(t), Conf::YSize/2 + r*Math.sin(t), r(0.8,1.8)); t+dt }
	end

	# It groups nodes into a unit iff they are planar AND detachable and returns nil
	# 	Otherwise, it returns a list with at least two links producing the problem
	def group(node_list, opts={})
		opts =  {
			:groups_allowed? => false,
			:require_connected? => true,
			:allow_intersection? => false,
			:no_group? => false,
			:move_time => 0.8,	# seconds
			:now? => false
	   	}.merge(opts)

		# Do not allow NodeGroups to be grouped any further
		node_list.each { |node| return [node] if node.is_a? NodeGroup } unless opts[:groups_allowed?]

		if opts[:require_connected?]
			# Make sure that all nodes connect to each other
			connected = [ node_list[0] ]
			disconnected = node_list.drop(1)
			connected_num = connected.size
			begin
				connected_num = connected.size
				disconnected.each do |node|
					connected << disconnected.delete(node) if connected.any? { |n2| node.links_to? n2 }
				end
			# if nothing has been connected at the end of the loop, we're finished
			end until connected_num == connected.size
			return disconnected unless disconnected.size == 0
		end

		# seperate the internal from the external links of the group
		intra_links, extern_links = [], []
		node_list.each { |node| node.links.each do |link|
			link.nodes.all?{ |n| node_list.include? n } ? intra_links << link : extern_links << link
		end; }
		
		# check that the internal links do not intersect with anything
		intra_links.each { |l1| @links.each { |l2| return [l1,l2] if l1.intersects? l2 } } unless opts[:allow_intersection?]

		extern_nodes = []	# list of nodes connected to this group
		extern_links.each { |link| link.nodes.each do |node| 
			next if node_list.include? node 
			extern_nodes << node
		end; }

		# The following code creates the new NodeGroup

		# create the x,y coordinates of the new node
		px = node_list.inject(0) { |sum, n| sum+=n.x } / node_list.size
		py = node_list.inject(0) { |sum, n| sum+=n.y } / node_list.size
		if opts[:no_group?]
			new_node = Node.new(@images, px, py)
		else
			num = node_list.inject(0) { |sum, n| sum += n.is_a?(NodeGroup) ? n.n : 1 } 
			new_node = NodeGroup.new(@images, px, py, num)
		end

		node_list_dup = node_list.dup

		merge_code = proc do
			# Integrate the new node and remove previous ones
			extern_nodes.each { |node| node.links.delete_if { |link|  extern_links.include? link } }
			@links.delete_if { |link| intra_links.include? link or extern_links.include? link }
			@nodes.delete_if { |node| node_list_dup.include? node }

			@nodes << new_node
			extern_nodes.each { |node| @links << Link.new(new_node, node) }
		end

		if opts[:now?]
			merge_code.call
		else
			ready_nodes=0
			node_list_dup.each do |node|
				node.move_to(px, py, opts[:move_time]) { merge_code.call if node_list_dup.size == ready_nodes+=1 }
			end
		end

		return nil
	end

	# return the first pair of intersecting links that is found
	def get_intersection
		return [] unless ready?
		# not the fastest algorithm but still fast enough
		@links.each_uniq_pair { |l1,l2| return [l1,l2] if l1.intersects? l2 }
		return nil
	end
end
