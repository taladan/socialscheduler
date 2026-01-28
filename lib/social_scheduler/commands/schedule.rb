module SocialScheduler
  module Commands
    class Schedule
      def initialize(options)
        @options = options
      end

      def call
        time_input = @options[:time]
        scheduled_time = if time_input
                           Chronic.parse(time_input) || Time.parse(time_input)
                         else
                           Time.now
                         end
        
        image_path = @options[:image] ? File.expand_path(@options[:image]) : nil

        post = Post.new(
          'message' => @options[:message],
          'time' => scheduled_time.to_s,
          'image_path' => image_path,
          'platform' => (@options[:platform] || 'facebook').downcase 
        )

        if post.valid?
          Queue.new.add(post)
          puts "✅ [#{post.platform.capitalize}] Scheduled (ID: #{post.id[0..7]})"
          puts "   Date: #{scheduled_time.strftime('%A, %b %d at %l:%M%P')}"
        else
          puts "❌ Error: Must provide message or image."
        end
      end
    end
  end
end
