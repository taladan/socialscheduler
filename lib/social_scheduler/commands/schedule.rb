require 'ice_cube' 

module SocialScheduler
  module Commands
    class Schedule
      def initialize(options)
        @options = options
      end

      def call
        # 1. THE GUARD CLAUSE: Validate Image Existence FIRST
        if @options[:image]
          expanded_path = File.expand_path(@options[:image])
          unless File.exist?(expanded_path)
            puts "❌ Error: Image file not found at '#{expanded_path}'"
            puts "   Please check your spelling or ensure you are in the correct directory."
            return # Abort the whole scheduling process immediately!
          end
          # Save the absolute path so we don't have to keep expanding it later
          @options[:image] = expanded_path 
        end

        time_input = @options[:time]
        
        # 2. Check for recurrence keywords
        if RecurrenceParser.recurring?(time_input)
          schedule_recurring(time_input)
        else
          schedule_single(time_input)
        end
      end

      private

      def schedule_single(time_input)
        scheduled_time = Chronic.parse(time_input) || Time.parse(time_input) rescue Time.now
        create_and_save(scheduled_time)
        puts "✅ [#{@options[:platform] || 'Facebook'}] Scheduled for #{scheduled_time.strftime('%A, %b %d at %l:%M%P')}"
      end

      def schedule_recurring(time_input)
        puts "🔄 Detected recurring schedule..."
        times = RecurrenceParser.new(time_input, @options).parse
        
        if times.empty?
          puts "❌ Error: Could not generate dates from '#{time_input}'"
          return
        end

        # Generate a shared ID for this batch
        series_id = SecureRandom.hex(4)

        times.each do |t|
          create_and_save(t, series_id)
        end

        puts "✅ Scheduled #{times.count} posts!"
        puts "   Series ID: #{series_id}"
        puts "   First: #{times.first.strftime('%m/%d/%y %H:%M')}"
        puts "   Last:  #{times.last.strftime('%m/%d/%y %H:%M')}"
      end

      def create_and_save(time_obj, series_id = nil)
        # We can just pass the image directly now, because we already validated it above!
        image_path = @options[:image]

        post = Post.new(
          'category' => @options[:category],
          'series_id' => series_id,
          'message' => @options[:message],
          'time' => time_obj.to_s,
          'image_path' => image_path,
          'alt_text' => @options[:alt],
          'platform' => (@options[:platform] || 'facebook').downcase 
        )

        if post.valid?
          Queue.new.add(post)
        else
          puts "❌ Error: Post invalid. (Requires either a message or an image)"
        end
      end
    end
  end
end