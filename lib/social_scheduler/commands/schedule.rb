require 'ice_cube' # Make sure to require this

module SocialScheduler
  module Commands
    class Schedule
      def initialize(options)
        @options = options
      end

      def call
        time_input = @options[:time]
        
        # Check for recurrence keywords
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
        puts "   First: #{times.first.strftime('%D %R')}"
        puts "   Last:  #{times.last.strftime('%D %R')}"
      end

      def create_and_save(time_obj, series_id = nil)
        image_path = @options[:image] ? File.expand_path(@options[:image]) : nil

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
          puts "❌ Error: Post invalid."
        end
      end
    end
  end
end