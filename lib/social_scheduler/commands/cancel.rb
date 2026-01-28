module SocialScheduler
  module Commands
    class Cancel
      def initialize(id_prefix)
        @prefix = id_prefix
      end

      def call
        return puts "❌ Error: Provide an ID." if @prefix.nil?

        queue = Queue.new
        candidates = queue.find_by_prefix(@prefix)

        if candidates.empty?
          puts "❌ No post found."
        elsif candidates.count > 1
          puts "⚠️  Ambiguous ID."
        else
          post = candidates.first
          queue.remove(post.id)
          puts "✅ Cancelled post #{post.id[0..7]}..."
          # FIX: Added backslash before #{post.message}
          puts "   '#{post.message}'"
        end
      end
    end
  end
end
