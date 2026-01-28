require 'json'
require 'time'
require 'koala'
require 'chronic'
require 'securerandom'
require 'fileutils' # Needed to create the directory

module SocialScheduler
  # 1. Define the User Data Directory (~/.socialscheduler)
  USER_DATA_DIR = File.join(Dir.home, '.socialscheduler')

  # 2. Ensure it exists immediately
  FileUtils.mkdir_p(USER_DATA_DIR) unless Dir.exist?(USER_DATA_DIR)

  # 3. Point files to the new location
  QUEUE_FILE = File.join(USER_DATA_DIR, 'queue.json')
  SECRETS_FILE = File.join(USER_DATA_DIR, 'secrets.json')

  # Autoload our classes
  autoload :Post, 'social_scheduler/post'
  autoload :Queue, 'social_scheduler/queue'
  autoload :CLI, 'social_scheduler/cli'
  
  module Platforms
    autoload :Facebook, 'social_scheduler/platforms/facebook'
  end

  module Commands
    autoload :List, 'social_scheduler/commands/list'
    autoload :Inspect, 'social_scheduler/commands/inspect'
    autoload :Cancel, 'social_scheduler/commands/cancel'
    autoload :Schedule, 'social_scheduler/commands/schedule'
    autoload :Edit, 'social_scheduler/commands/edit'
    autoload :Runner, 'social_scheduler/commands/runner'
  end
end