module SocialScheduler
  module Commands
    class Edit
      def initialize(id_prefix, options)
        @prefix = id_prefix
        @options = options
      end

      def call
        return puts "❌ Error: Provide an ID." if @prefix.nil?
        return puts "⚠️  No changes specified." if @options.empty?

        queue = Queue.new
        candidates = queue.find_by_prefix(@prefix)

        return puts "❌ No post found." if candidates.empty?
        return puts "⚠️  Ambiguous ID." if candidates.count > 1

        post = candidates.first
        apply_changes(post)
        
        if post.valid?
          queue.update(post)
          puts "✅ Changes saved!"
        else
          puts "❌ Error: Invalid post. Changes NOT saved."
        end
      end

      private

      def apply_changes(post)
        if @options[:message]
          post.message = @options[:message]
          puts "   - Message updated"
        end

        if @options[:image]
          path = File.expand_path(@options[:image])
          if File.exist?(path)
            post.image_path = path
            puts "   - Image updated"
          else
            puts "❌ Error: Image not found at #{path}" 
          end
        end

        if @options[:time]
          if new_time = (Chronic.parse(@options[:time]) rescue nil)
            post.time = new_time.to_s
            puts "   - Time rescheduled: #{new_time}"
          end
        end

        if @options[:platform]
          post.platform = @options[:platform].downcase
          puts "   - Platform changed: #{post.platform}"
        end
      end
    end
  end
end
