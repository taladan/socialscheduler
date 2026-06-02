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

        target_post = candidates.first
        
        all_posts = queue.load
        posts_to_edit = []

        if @options[:series]
          if target_post.series_id.nil?
            puts "⚠️  Post #{target_post.id[0..7]} is not part of a series."
            puts "   Editing only this single post."
            posts_to_edit << all_posts.find { |p| p.id == target_post.id }
          else
            posts_to_edit = all_posts.select { |p| p.series_id == target_post.series_id }
            puts "🔄 Editing series (#{posts_to_edit.count} posts)..."
          end
        else
          posts_to_edit << all_posts.find { |p| p.id == target_post.id }
        end

        changes_summary = []
        
        posts_to_edit.each do |post|
          changes_summary = apply_changes(post) # Returns list of what changed
        end

        if posts_to_edit.all?(&:valid?)
          queue.save(all_posts)
          
          puts "✅ Saved changes to #{posts_to_edit.count} post(s):"
          changes_summary.uniq.each { |msg| puts "   - #{msg}" }
        else
          puts "❌ Error: One or more posts became invalid. Changes NOT saved."
        end
      end

      private

      def apply_changes(post)
        changes = []

        if @options[:category]
          post.category = @options[:category]
          changes << "Category updated to '#{@options[:category]}'"
        end

        if @options[:message]
          post.message = @options[:message]
          changes << "Message updated"
        end

        if @options[:image]
          path = File.expand_path(@options[:image])
          if File.exist?(path)
            post.image_path = path
            changes << "Image updated"
          else
            puts "❌ Warning: Image not found at #{path} (Skipped)" 
          end
        end

        if @options[:alt]
          post.alt_text = @options[:alt]
          changes << "Alt text updated"
        end

        if @options[:time]
          if new_time = (Chronic.parse(@options[:time]) rescue nil)
            post.time = new_time.to_s
            changes << "Time rescheduled to #{new_time}"
          end
        end

        if @options[:platform]
          post.platform = @options[:platform].downcase
          changes << "Platform changed to #{post.platform}"
        end

        changes
      end
    end
  end
end