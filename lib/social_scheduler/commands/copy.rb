module SocialScheduler
  module Commands
    class Copy
      def initialize(id_prefix, options)
        @prefix = id_prefix
        @options = options
      end

      def call
        return puts "❌ Error: Please provide the ID of the post you want to copy." if @prefix.nil?
        return puts "❌ Error: You must provide a new time using the -t flag." unless @options[:time]

        queue = Queue.new
        candidates = queue.find_by_prefix(@prefix)

        return puts "❌ No post found starting with '#{@prefix}'." if candidates.empty?
        return puts "⚠️ Ambiguous ID. Please provide a few more characters." if candidates.count > 1

        original = candidates.first

        # prioritize new flags and fall back 
        schedule_options = {
          message:  @options[:message]  || original.message,
          image:    @options[:image]    || original.image_path,
          alt:      @options[:alt]      || original.alt_text,
          category: @options[:category] || original.category,
          platform: @options[:platform] || original.platform,
          time:     @options[:time],
          start:    @options[:start], 
          end:      @options[:end]    
        }

        puts "📋 Copying post #{original.id[0..7]}..."
        
        Schedule.new(schedule_options).call
      end
    end
  end
end