require 'optparse'

module SocialScheduler
  class CLI
    def self.start(args)
      new.run(args)
    end

    def run(args)
      options = parse_options(args)
      command = args[0]

      if command == 'run'
        execute_due_posts
      elsif options[:message] || options[:image]
        schedule_post(options)
      else
        puts "Usage: ssched [options] or ssched run"
      end
    end

    private

    def parse_options(args)
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: ssched [options]"
        opts.on("-m", "--message MESSAGE") { |m| options[:message] = m }
        opts.on("-i", "--image PATH") { |i| options[:image] = i }
        opts.on("-t", "--time TIME") { |t| options[:time] = t }
        opts.on("-p", "--platform NAME", "Platform (facebook, twitter/x, mastodon, instagram)") { |p| options[:platform] = p}
      end.parse!(args)
      options
    end

    def schedule_post(options)
      # Logic to parse time
      time_input = options[:time]
      scheduled_time = if time_input
                         Chronic.parse(time_input) || Time.parse(time_input)
                       else
                         Time.now
                       end

      # Validate Image path
      image_path = options[:image] ? File.expand_path(options[:image]) : nil

      post = Post.new(
        'message' => options[:message],
        'time' => scheduled_time.to_s,
        'image_path' => image_path,
        'platform' => (options[:platform] || 'facebook').downcase
      )

      if post.valid?
        Queue.new.add(post)
        puts "✅ Post Scheduled for #{scheduled_time}"
      else
        puts "❌ Error: Must provide message or image."
      end
    end

    def execute_due_posts
      queue = Queue.new
      posts = queue.pending_posts

      return if posts.empty? # Silent for cron

      posts.each do |post|
        begin
          publisher = get_publisher_for(post.platform)
          publisher.post(post)
          
          # Only remove if successful
          queue.remove(post.id)
        rescue StandardError => e
          puts "❌ Error publishing post #{post.id}   to #{post.platform}: #{e.message}"
        end
      end
    end

    def get_publisher_for(platform_name)
      case platform_name
      when 'facebook'
        return Platforms::Facebook.new
      when 'twitter', 'x'
        raise "Twitter support coming soon."
      when 'mastodon'
        raise "Mastodon support coming soon."
      when 'instagram'
        raise "Instagram support coming soon."
      when 'bluesky'
        raise "Bluesky support coming soon."
      end
    end
  end
end
