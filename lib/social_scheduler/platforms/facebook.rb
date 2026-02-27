module SocialScheduler
  module Platforms
    class Facebook
      def initialize
        secrets = load_secrets
        @api = Koala::Facebook::API.new(secrets['page_access_token'])
      end

      def post(post_object)
        puts "   Attempting to publish to Facebook..."
        
        if post_object.image_path && File.exist?(post_object.image_path)
          params = { caption: post_object.message }

          if post_object.alt_text && !post_object.alt_text.empty?
            params[:alt_text_custom] = post_object.alt_text
          end

          @api.put_picture(post_object.image_path, params) 
        
        elsif post_object.message
          @api.put_connections("me", "feed", message: post_object.message)
        end
        
        puts "   🚀 Facebook Publish Success!"
      end

      private

      def load_secrets
        unless File.exist?(SocialScheduler::SECRETS_FILE)
          raise "Secrets file not found at #{SocialScheduler::SECRETS_FILE}"
        end
        JSON.parse(File.read(SocialScheduler::SECRETS_FILE))
      end
    end
  end
end
