#!/usr/bin/env ruby

require 'drb'

SERVER_BOARD = 'board_data.rmd'
LOCAL_BOARD = SERVER_BOARD
DRB_PORT = 9000
DRB_PROTOCOL = 'druby'
DRB_IP = 'localhost'
DRB_URI = "#{DRB_PROTOCOL}://#{DRB_IP}:#{DRB_PORT}"

class BlankSlate
	safe_methods = [:__send__, :__id__, :object_id, :inspect, :respond_to?, :to_s,
		:private_methods, :protected_methods]
	(instance_methods - safe_methods).each do |method|
		undef_method method
	end
end

class ScoreBoardProxy < BlankSlate
	def initialize(board);	@board ||=board;	end
	def submit(level, score, name)
		raise ArgumentError, "Level must be an integer > 0" unless level.is_a?Integer and level>0
		raise ArgumentError, "Score must be a number > 0" unless score.is_a?Numeric and score>0
		raise ArgumentError, "Name must be a string" unless name.is_a?String

		level.untaint;	score.untaint
		name.gsub!(/\s+/,' ')
		name.gsub!(/[^a-zA-Z0-9\-_.|<>\ ]/,'*').untaint
		name = name[0,20]	# max name size is 20 valid characters

		@board.submit(level, score, name)
	end

	def get_scores;	@board.get_scores;	end
	def name;	@board.name;	end
	def save;	end
end

class ScoreBoard
	attr_reader :name
	def initialize(fname, name="Highscore board", n=100)
		@file = fname
		if File.exists? fname
			@name, @n, @list = File.open(fname) { |f| Marshal.load(f) }
		else
			@name, @n, @list = name, n, []
		end
		@mutex = Mutex.new
	end

	def save
		@mutex.synchronize { File.open(@file, 'w') { |f| Marshal.dump([@name, @n, @list], f) } }
	end

	def submit(level, score, name)
		entry = { :name=>name, :level=>level, :score=>score }
		@mutex.synchronize do
			@list << entry
			@list.sort_by! { |e| e[:score] }
			@list.shift if @list.size > @n
		end

		return nil
	end

	def get_scores;	@mutex.synchronize { @list.dup };	end

	def self.get
		obj = nil
		begin
			obj = DRbObject.new_with_uri(DRB_URI)
			raise DRb::DRbError unless obj.respond_to?(:submit)
		rescue DRb::DRbError
			puts "Server highscore board not found. Using #{LOCAL_BOARD}"
			obj = ScoreBoard.new(LOCAL_BOARD)
		end
		return obj
	end
end

if __FILE__ == $PROGRAM_NAME
	puts "Starting score server"
	board =	ScoreBoard.new(SERVER_BOARD)

	$SAFE = 1
	DRb.start_service(DRB_URI, ScoreBoardProxy.new(board))

	begin
		DRb.thread.join
	rescue Interrupt => int
		board.get_scores.reverse_each { |e| puts "#{e[:name]} scored #{e[:score]} at level #{e[:level]}" }
	ensure
		DRb.stop_service
		board.save
	end

end
