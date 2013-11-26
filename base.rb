require 'gosu'
require 'tween'
require 'logger'

module ZOrder
	Background, Links, Nodes, SelectedLinks, SelectedNodes, NodeText, UI = *0..100
end

module Color
	Link = Gosu::Color::GREEN
	Text = Gosu::Color::WHITE
	Node = Gosu::Color::BLUE
	NodeText = Gosu::Color::BLACK

	SelectedNodeText = Gosu::Color::YELLOW
	SelectedLink = Gosu::Color::RED
	SelectedNode = Gosu::Color::YELLOW

	ShadeNum = 7
	Shade = (0..(ShadeNum)).map{|c| t=Integer(c* (0xff / ShadeNum)); Gosu::Color::argb(0xff,t,t/1.2,t/2) }.reverse
end

module Conf
	XSize = 800
	YSize = 600
end

$log = Logger.new(STDOUT)
$log.level = Logger::FATAL
#$log.level = Logger:: DEBUG
$log.debug { "Logger started" }

class TimedEvents
	attr_reader	:event_list
	def initialize;
		@event_list = {}
	end
	def set(key, delay=1, &block)
		@event_list[key] = [Time.now, delay, block]
	end
	
	def update
		@event_list.each do |key, event|
			next unless Time.now - event[0] >= event[1]
			(@event_list.delete key)[2].call
		end
	end

	def force(key)
		return false unless event = @event_list[key]
		event[2].call
		@event_list.delete key
	end
end

class Array
	def each_uniq_pair(&block)
		self.each_index do |i| 
			e1=self[i]
			self.drop(i+1).each	{ |e2| block.call(e1,e2) }
		end
	end
end
