module SocialScheduler
  module Commands
    class Inspect
      def initialize(id_prefix)
        @prefix = id_prefix
      end

      def call
        return puts "❌ Error: Please provide an ID." if @prefix.nil?

        queue = Queue.new
        candidates = queue.find_by_prefix(@prefix)

        if candidates.empty?
          puts "❌ No post found starting with '#{@prefix}'"
        elsif candidates.count > 1
          puts "⚠️  Ambiguous ID:"
          candidates.each { |p| puts "   - #{p.id[0..7]} (#{p.message})" }
        else
          print_details(candidates.first)
        end
      end

      private

      def print_details(post)
        puts "========================================"
        puts " 📮 Post Details"
        puts "========================================"
        puts "ID:       #{post.id}"
        puts "Category: #{post.category}" || '(None)'
        puts "Series:   #{post.series_id || '(None)'}"
        puts "Platform: #{post.platform.capitalize}"
        puts "Time:     #{post.time}"
        puts "Image:    #{post.image_path || '(None)'}"
        puts "Alt text: #{post.alt_text || '(None)'}"
        puts "Status:   #{post.status}"
        puts "----------------------------------------"
        puts "MESSAGE:"
        puts post.message
        puts "========================================"
      end
    end
  end
end
