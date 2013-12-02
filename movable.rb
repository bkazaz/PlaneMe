require 'tween'

# MixIn functionality for objects with (x,y) coordinates
# that enables smooth movement

module Movable
	# requires the object to provide:
	# 	position -> returns [x,y]
	# 	position= ([x,y])
	# Assumes obj.update() is called 

	def move_to(px, py, delay=1, &when_done)
		@this_frame = Time.now
		@last_frame = @this_frame
		@tween = Tween.new(self.position, [px, py], Tween::Quart::InOut, delay)
		@done_code = block_given? ? when_done : nil

		$log.debug { "#{self} move_to #{[px.to_i,py.to_i]} in #{delay} secs" }

		def self.delta
			@this_frame = Time.now
			dt = (@this_frame - @last_frame)
			@last_frame = @this_frame
			return dt
		end

		def self.update(*args)
			@tween.update(delta)
			self.position = [@tween.x, @tween.y]
			super
			if @tween.done
				#$log.debug { "#{@tween} is done!" }
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
