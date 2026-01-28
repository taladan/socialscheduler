module SocialScheduler
  module Commands
    class Runner
      def call
        queue = Queue.new
        posts = queue.pending_posts
        return if posts.empty?

        posts.each do |post|
          begin
            publisher = get_publisher_for(post.platform)
            publisher.post(post)
            queue.remove(post.id)
          rescue StandardError => e
            puts "❌ Error publishing #{post.id[0..7]}: #{e.message}"
          end
        end
      end

      private

      def get_publisher_for(platform)
        case platform
        when 'facebook' then Platforms::Facebook.new
        when 'twitter', 'x' then raise "Twitter support coming soon!"
        else raise "Unknown platform: #{platform}"
        end
      end
    end
  end
end
