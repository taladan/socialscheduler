require 'json'
require 'time'
require 'koala'
require 'chronic'

# Define the Module and global paths
module SocialScheduler
  # Root is one level up from "lib"
  ROOT_DIR = File.expand_path('../..', __FILE__)
  QUEUE_FILE = File.join(ROOT_DIR, 'queue.json')
  SECRETS_FILE = File.join(ROOT_DIR, 'secrets.json')

  # Autoload our classes
  autoload :Post, 'social_scheduler/post'
  autoload :Queue, 'social_scheduler/queue'
  autoload :CLI, 'social_scheduler/cli'
  
  module Platforms
    autoload :Facebook, 'social_scheduler/platforms/facebook'
  end
end
