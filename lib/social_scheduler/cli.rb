require 'optparse'

module SocialScheduler
  class CLI
    def self.start(args)
      new.run(args)
    end

    def run(args)
      options = parse_options(args)
      command = args[0]

      case command
      when 'run'
        execute_due_posts
      when 'list'
        list_queue
      when 'inspect', 'show'
        inspect_post(args[1])
      when 'cancel', 'rm', 'delete'
        cancel_post(args[1])
      when 'edit', 'update'
        edit_post(args[1], options)
      else
        if options[:message] || options[:image]
          schedule_post(options)
        else
          print_help
        end
      end
    end

    private

    def print_help
      puts "Usage:"
      puts "  ssched -m 'Msg' -t 'Time'   Schedule a post"
      puts "  ssched list                 Show pending posts"
      puts "  ssched cancel [ID]          Remove a post (partial ID works)"
      puts "  ssched run                  Force scheduler to check for due posts"
    end

    def list_queue
      queue = Queue.new
      posts = queue.load.select { |p| p.status == 'pending' }

      if posts.empty?
        puts "📭 Queue is empty."
        return
      end

      # Define a layout format string
      # %-9s means "Left-align string in a 9-character wide space"
      layout = "%-9s | %-8s | %-35s | %s"

      # Print Header (No emojis to ensure perfect alignment)
      puts layout % ["ID", "Platform", "Scheduled Time", "Message"]
      puts "-" * 90

      posts.each do |p|
        # Format: Wednesday, Jan 28, 2026 at 2:06pm
        # %A=Day, %b=Mon, %d=DayNum, %Y=Year, %l:%M%P = 3:00pm
        time_obj = Time.parse(p.time)
        time_str = time_obj.strftime('%A, %b %d, %Y at %l:%M%P')

        # Clean up message (truncate to 30 chars for display)
        msg_raw = p.message || "(Image Only)"
        msg = msg_raw.gsub("\n", " ")
        msg = msg.length > 30 ? msg[0..27] + "..." : msg

        # Print the row
        puts layout % [
          p.id[0..7],       # First 8 chars of ID
          p.platform[0..7], # First 8 chars of Platform (allows 'facebook')
          time_str,         # The long date format
          msg
        ]
      end
    end

    def cancel_post(prefix)
      if prefix.nil?
        puts "❌ Error: Please provide an ID (or part of one)."
        puts "   Example: ssched cancel a1b2"
        return
      end

      queue = Queue.new
      candidates = queue.find_by_prefix(prefix)

      if candidates.empty?
        puts "❌ No post found starting with '#{prefix}'"
      elsif candidates.count > 1
        puts "⚠️  Ambiguous ID. Did you mean one of these?"
        candidates.each { |p| puts "   - #{p.id[0..7]} (#{p.message})" }
      else
        post = candidates.first
        queue.remove(post.id)
        puts "✅ Cancelled post #{post.id[0..7]}..."
        puts "   '#{post.message}'"
      end
    end

    def parse_options(args)
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: ssched [options]"
        opts.on("-m", "--message MESSAGE") { |m| options[:message] = m }
        opts.on("-i", "--image PATH") { |i| options[:image] = i }
        opts.on("-t", "--time TIME") { |t| options[:time] = t }
        opts.on("-p", "--platform NAME") { |p| options[:platform] = p }
        opts.on("-h", "--help") { print_help; exit }
      end.parse!(args)
      options
    end

    def schedule_post(options)
      time_input = options[:time]
      scheduled_time = if time_input
                         Chronic.parse(time_input) || Time.parse(time_input)
                       else
                         Time.now
                       end
      image_path = options[:image] ? File.expand_path(options[:image]) : nil

      post = Post.new(
        'message' => options[:message],
        'time' => scheduled_time.to_s,
        'image_path' => image_path,
        'platform' => (options[:platform] || 'facebook').downcase 
      )

      if post.valid?
        Queue.new.add(post)
        puts "✅ [#{post.platform.capitalize}] Scheduled (ID: #{post.id[0..7]})"
        puts "   Date: #{scheduled_time.strftime('%A, %b %d at %l:%M%P')}"
      else
        puts "❌ Error: Must provide message or image."
      end
    end

    def execute_due_posts
      queue = Queue.new
      posts = queue.pending_posts

      return if posts.empty?

      posts.each do |post|
        begin
          publisher = get_publisher_for(post.platform)
          publisher.post(post)
          queue.remove(post.id)
        rescue StandardError => e
          puts "❌ Error publishing #{post.id[0..7]} to #{post.platform}: #{e.message}"
        end
      end
    end

    def get_publisher_for(platform_name)
      case platform_name
      when 'facebook'
        return Platforms::Facebook.new
      when 'twitter', 'x'
        raise "Twitter support is coming soon!" 
      else
        raise "Unknown platform: #{platform_name}"
      end
    end

    def inspect_post(prefix)
      if prefix.nil?
        puts "❌ Error: Please provide an ID."
        return
      end

      queue = Queue.new
      candidates = queue.find_by_prefix(prefix)

      if candidates.empty?
        puts "❌ No post found starting with '#{prefix}'"
        return
      end

      if candidates.count > 1
        puts "⚠️  Ambiguous ID. Did you mean one of these?"
        candidates.each { |p| puts "   - #{p.id[0..7]} (#{p.message[0..20]}...)" }
        return
      end

      post = candidates.first
      
      puts "========================================"
      puts " 📮 Post Details"
      puts "========================================"
      puts "ID:       #{post.id}"
      puts "Platform: #{post.platform.capitalize}"
      puts "Time:     #{post.time}"
      puts "Image:    #{post.image_path || '(None)'}"
      puts "Status:   #{post.status}"
      puts "----------------------------------------"
      puts "MESSAGE:"
      puts post.message # This prints the full multiline text!
      puts "========================================"
    end

    def edit_post(prefix, options)
      if prefix.nil?
        puts "❌ Error: Please provide an ID."
        return
      end

      if options.empty?
        puts "⚠️  No changes specified."
        puts "   Usage: ssched edit [ID] -m 'New Msg' -t 'New Time'"
        return
      end

      queue = Queue.new
      candidates = queue.find_by_prefix(prefix)

      if candidates.empty?
        puts "❌ No post found starting with '#{prefix}'"
        return
      elsif candidates.count > 1
        puts "⚠️  Ambiguous ID. Did you mean one of these?"
        candidates.each { |p| puts "   - #{p.id[0..7]} (#{p.message})" }
        return
      end

      # We found the post!
      post = candidates.first

      puts "✏️  Editing Post #{post.id[0..7]}..."

      # Apply changes if flags were provided
      if options[:message]
        post.message = options[:message]
        puts "   - Message updated"
      end

      if options[:image]
        path = File.expand_path(options[:image])
        if File.exist?(path)
          post.image_path = path
          puts "   - Image updated"
        else
          puts "❌ Error: Image not found at #{path}"
          return
        end
      end

      if options[:time]
        new_time = Chronic.parse(options[:time]) || Time.parse(options[:time]) rescue nil
        if new_time
          post.time = new_time.to_s
          puts "   - Time rescheduled to #{new_time.strftime('%A, %b %d at %l:%M%P')}"
        else
          puts "❌ Error: Could not parse time '#{options[:time]}'"
          return
        end
      end

      if options[:platform]
        post.platform = options[:platform].downcase
        puts "   - Platform changed to #{post.platform}"
      end

      # Validate and Save
      if post.valid?
        queue.update(post)
        puts "✅ Changes saved!"
      else
        puts "❌ Error: Post became invalid (must have message or image)."
        puts "   Changes NOT saved."
      end
    end
  end
end