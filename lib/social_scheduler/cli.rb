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
        'image_path' => image_path
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

      if posts.empty?
        # Silent exit for cron
        return
      end

      # Initialize Platform (Just Facebook for now)
      fb = Platforms::Facebook.new

      posts.each do |post|
        begin
          fb.post(post)
          queue.remove(post.id)
        rescue StandardError => e
          puts "❌ Error publishing post #{post.id}: #{e.message}"
        end
      end
    end
  end
end
