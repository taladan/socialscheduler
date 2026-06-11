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
      when 'list'
        Commands::List.new.call
      when 'inspect', 'show'
        Commands::Inspect.new(args[1]).call
      when 'cancel', 'rm', 'delete'
        Commands::Cancel.new(args[1], options).call
      when 'edit', 'update'
        Commands::Edit.new(args[1], options).call
      when 'run'
        Commands::Runner.new.call
      when 'config', 'setup'
        Commands::Config.new.call
      when 'copy', 'cp', 'duplicate', 'dupe', 'replicate', 'xerox'
        Commands::Copy.new(args[1], options).call
      else
        if options[:message] || options[:image]
          Commands::Schedule.new(options).call
        else
          print_help
        end
      end
    end

    private

    def print_help
      puts "Usage:"
      puts "  ssched [-miatc]                 Schedule one or more posts"
      puts "    Flags:"
      puts "      -m MESSAGE                      Add MESSAGE to post"
      puts "      -i PATH/TO/IMAGE.JPG            Add image to post"
      puts "      -a ALT-TEXT                     Add alt text to image"
      puts "      -t TIME                         Schedule post at TIME"
      puts "      -c CATEGORY                     Set post category"
      puts "      -b DATE                         Begining date for a series"
      puts "      -e DATE                         End date for a series"
      puts " "
      puts "  ssched config                                                 Setup API keys"
      puts "  ssched list                                                   Show pending posts"
      puts "  ssched inspect [ID]                                           Show post details"
      puts "  ssched edit [ID] [flags]                                      Edit a post"
      puts "  ssched copy [ID] -t TIME [-b START -e END]"
      puts "  ssched cancel [ID]                                            Remove a post"
      puts "  ssched cancel [ID] --series                                   Remove all posts in a series"
      puts "  ssched run                                                    Force check"
    end

    def parse_options(args)
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: ssched [options]"
        opts.on("-c", "--category CATEGORY") { |c| options[:category] = c }
        opts.on("-m", "--message MESSAGE") { |m| options[:message] = m }
        opts.on("-i", "--image PATH") { |i| options[:image] = i }
        opts.on("-a", "--alt TEXT", "Alt text for screen readers") { |a| options[:alt] = a}
        opts.on("-t", "--time TIME") { |t| options[:time] = t }
        opts.on("-p", "--platform NAME") { |p| options[:platform] = p }
        opts.on("-s", "--series", "Apply to entire series") { |s| options[:series] = s}
        opts.on("-h", "--help") { print_help; exit }
        opts.on("-b", "--begin DATE", "Begin date for recurring posts ") { |b| options[:start] = b}
        opts.on("-e", "--end DATE", "End date for recurring posts ") { |e| options[:end] = e}
      end.parse!(args)
      options
    end
  end
end