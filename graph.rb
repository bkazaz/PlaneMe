require_relative 'base'
require_relative 'link'
require_relative 'node'

class PlanarGraph
	attr_reader :nodes, :links

	def initialize(level, imgs)
		x, y = Conf::XSize/2, Conf::YSize/2
		@nodes = [Node.new(imgs,x,y), Node.new(imgs,x,y)]
		@links = [ Link.new(@nodes[0], @nodes[1]) ]
		@level = level
		@images = imgs
		used = []

		# Create a planar graph
		(1+level).times do
			@nodes << node1 = Node.new(imgs,x,y)
			@nodes << node2 = Node.new(imgs,x,y)
			used << @links.delete_at( Random.rand(@links.size) )

			seeds=[node1, node2, used[-1].nodes[0], used[-1].nodes[1]]
			#seeds.each_index{|i| seeds.drop(i+1).each{|n| @links << Link.new(seeds[i], n)}}
			seeds.each_uniq_pair { |n1, n2| @links << Link.new(n1,n2) }
			@links.pop.destroy

			nomore = @nodes.reject { |node| node.links.size < 4}	# find nodes with more than 4 links
			nomore.each do |node| 
				node.links.each { |link| used << @links.delete(link) }
			end
			used.delete_if { |link| link==nil }
		end
		@links += used

		shuffle()
	end

	def score(dt)	# times are in seconds
		max_score = @level * 200.0
		half_life = (@nodes.size ** 1.5) * 1.0
		return [1, (max_score * 2.0 ** (-dt / half_life)).to_i].max
	end

	# Randomize the node's position and lay them on the screen
	def shuffle
		@nodes.shuffle!
		r, dt = [Conf::XSize, Conf::YSize].min/2 - 20, 2*Math::PI/@nodes.size
		@nodes.inject(0) { |t, node| node.move_to(Conf::XSize/2 + r*Math.cos(t), Conf::YSize/2 + r*Math.sin(t),1); t+dt }
	end

	# It groups nodes into a unit iff they are planar AND detachable and returns nil
	# 	Otherwise, it returns a list with at least two links producing the problem
	def group(node_list)
		# Do not allow NodeGroups to be grouped any further
		node_list.each { |node| return [node] if node.is_a? NodeGroup }

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

		# seperate the internal from the external links of the group
		intra_links, extern_links = [], []
		node_list.each { |node| node.links.each do |link|
			link.nodes.all?{ |n| node_list.include? n } ? intra_links << link : extern_links << link
		end; }
		
		# check that the internal links do not intersect with anything
		intra_links.each { |l1| @links.each { |l2| return [l1,l2] if l1.intersects? l2 } }

		# at this point, the group is indeed planar
		extern_nodes = []	# list of nodes connected to this group
		extern_links.each { |link| link.nodes.each do |node| 
			next if node_list.include? node 
			extern_nodes << node
		end; }

		# The following code creates the new NodeGroup

		# create the x,y coordinates of the new node
		px = node_list.inject(0) { |sum, n| sum+=n.x } / node_list.size
		py = node_list.inject(0) { |sum, n| sum+=n.y } / node_list.size
		#num = node_list.inject(0) { |sum, n| sum += n.is_a?(NodeGroup) ? n.n : 1 } 
		new_node = NodeGroup.new(@images, px, py, node_list.size)

		ready_nodes=0
		node_list_dup = node_list.dup

		node_list_dup.each do |node|
			node.move_to(px, py, 0.8) do 
				ready_nodes+=1
				if node_list_dup.size == ready_nodes
					$log.debug { "Integrating the new node" }
					extern_nodes.each { |node| node.links.delete_if { |link|  extern_links.include? link } }
					@links.delete_if { |link| intra_links.include? link or extern_links.include? link }
					@nodes.delete_if { |node| node_list_dup.include? node }

					@nodes << new_node
					extern_nodes.each { |node| @links << Link.new(new_node, node) }
				end
			end
		end

		return nil
	end

	# return the first pair of intersecting links that is found
	def get_intersection
		# not the fastest algorithm but still fast enough
		@links.each_uniq_pair { |l1,l2| return [l1,l2] if l1.intersects? l2 }
		return nil
	end
end
