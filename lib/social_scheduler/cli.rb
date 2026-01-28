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
        Commands::Cancel.new(args[1]).call
      when 'edit', 'update'
        Commands::Edit.new(args[1], options).call
      when 'run'
        Commands::Runner.new.call
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
      puts "  ssched -m 'Msg' -t 'Time'   Schedule a post"
      puts "  ssched list                 Show pending posts"
      puts "  ssched inspect [ID]         Show post details"
      puts "  ssched edit [ID] [flags]    Edit a post"
      puts "  ssched cancel [ID]          Remove a post"
      puts "  ssched run                  Force check"
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
  end
end