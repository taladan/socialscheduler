module SocialScheduler
  module Commands
    class Cancel
      def initialize(id_prefix, options = {})
        @prefix = id_prefix
        @options = options
      end

      def call
        return puts "❌ Error: Provide an ID." if @prefix.nil?

        queue = Queue.new
        candidates = queue.find_by_prefix(@prefix)

        if candidates.empty?
          puts "❌ No post found."
        elsif candidates.count > 1
          puts "⚠️  Ambiguous ID. Did you mean one of these"
          candidates.each { |p| puts " -#{p.id[0..7]} (#{p.message})"}
          return
        end

        post = candidates.first

        if @options[:series]
          if post.series_id.nil?
          queue.remove(post.id)
            puts "⚠️  Post #{post.id[0..7]} is not part of a series."
            puts "   Cancelled only this single post."
            queue.remove(post.id)
          else
            count = queue.remove_series(post.series_id)
            puts "✅ Cancelled entire series (#{count} posts)."
          end
        else
          queue.remove(post.id)
          puts "✅ Cancelled post #{post.id[0..7]}..."
          # FIX: Added backslash before #{post.message}
          puts "   '#{post.message}'"

          if post.series_id
            puts "💡 Hint: This post was part of a series."
            puts "   Use --series to cancel the rest of the series."
          end
        end
      end
    end
  end
end
