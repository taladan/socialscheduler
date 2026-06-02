module SocialScheduler
  module Commands
    class Config
      def call
        puts "🔧 Social Scheduler Configuration"
        puts "--------------------------------"
        
        # Load existing secrets so we don't overwrite other platforms
        secrets = {}
        if File.exist?(SocialScheduler::SECRETS_FILE)
          begin
            secrets = JSON.parse(File.read(SocialScheduler::SECRETS_FILE))
          rescue JSON::ParserError
            secrets = {}
          end
        end

        puts "Which platform would you like to configure?"
        puts "1. Facebook"
        puts "2. Twitter / X"
        print "Select (1-2): "
        
        choice = $stdin.gets.chomp

        case choice
        when '1'
          configure_facebook(secrets)
        when '2'
          configure_twitter(secrets)
        else
          puts "❌ Invalid selection."
        end
      end

      private

      def configure_facebook(secrets)
        puts "\n🔵 Facebook Setup"
        puts "Paste your Page Access Token below (hidden input recommended):"
        print "> "
        token = $stdin.gets.chomp.strip

        if token.empty?
          puts "❌ Error: Token cannot be empty."
          return
        end

        secrets['page_access_token'] = token
        save_secrets(secrets)
        puts "✅ Facebook configuration saved!"
      end

      def configure_twitter(secrets)
        puts "\n⚫ Twitter Setup"
        puts "Paste your API Key:"
        print "> "
        api_key = $stdin.gets.chomp.strip
        
        puts "Paste your API Secret:"
        print "> "
        api_secret = $stdin.gets.chomp.strip

        if api_key.empty? || api_secret.empty?
          puts "❌ Error: Keys cannot be empty."
          return
        end

        secrets['twitter_api_key'] = api_key
        secrets['twitter_api_secret'] = api_secret
        save_secrets(secrets)
        puts "✅ Twitter configuration saved!"
      end

      def save_secrets(secrets)
        File.write(SocialScheduler::SECRETS_FILE, JSON.pretty_generate(secrets))
        # Set file permissions to 600 (Read/Write for owner only) for security
        File.chmod(0600, SocialScheduler::SECRETS_FILE)
      end
    end
  end
end