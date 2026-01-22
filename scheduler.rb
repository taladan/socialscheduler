require 'koala'
require 'json'
require 'time'

# --- CONFIGURATION ---
QUEUE_FILE = 'queue.json'
SECRETS_FILE = 'secrets.json'

# --- HELPER FUNCTIONS ---

def load_secrets
  unless File.exist?(SECRETS_FILE)
    puts "❌ Error: #{SECRETS_FILE} not found."
    puts "   Please create a 'secrets.json' file with your 'page_access_token'."
    exit
  end
  JSON.parse(File.read(SECRETS_FILE))
end

def load_queue
  if File.exist?(QUEUE_FILE)
    JSON.parse(File.read(QUEUE_FILE))
  else
    []
  end
end

def save_queue(queue)
  File.write(QUEUE_FILE, JSON.pretty_generate(queue))
end

def add_post(message, time_string, image_path)
  # 1. Validate Image
  unless File.exist?(image_path)
    puts "❌ Error: Could not find image at: #{image_path}"
    return
  end

  # 2. Validate Time
  begin
    scheduled_time = Time.parse(time_string)
  rescue ArgumentError
    puts "❌ Error: Invalid time format. Try 'YYYY-MM-DD HH:MM'"
    return
  end

  queue = load_queue

  # 3. Create the post object
  post = {
    'id' => Time.now.to_i,
    'message' => message,
    'time' => scheduled_time.to_s,
    'image_path' => File.absolute_path(image_path),
    'status' => 'pending'
  }

  queue << post
  save_queue(queue)
  puts "✅ Post scheduled!"
  puts "   Time:  #{scheduled_time}"
  puts "   Image: #{File.basename(image_path)}"
end

def run_scheduler
  queue = load_queue
  current_time = Time.now
  
  # Load Token securely
  secrets = load_secrets
  token = secrets['page_access_token']
  
  # Initialize Facebook API
  graph = Koala::Facebook::API.new(token)
  
  # Filter posts ready to publish
  posts_to_publish = queue.select do |post| 
    Time.parse(post['time']) <= current_time && post['status'] == 'pending'
  end

  if posts_to_publish.empty?
    return
  end

  posts_to_publish.each do |post|
    begin
      puts "Attempting to publish post #{post['id']}..."
      
      graph.put_picture(
        post['image_path'], 
        { caption: post['message'] }
      )
      
      puts "🚀 Published successfully!"
      queue.delete(post) 
      
    rescue Koala::Facebook::APIError => e
      puts "❌ Facebook API Error: #{e.message}"
    rescue StandardError => e
      puts "❌ System Error: #{e.message}"
    end
  end

  save_queue(queue)
end

# --- COMMAND LINE ARGUMENT HANDLING ---

command = ARGV[0]

case command
when 'add'
  message = ARGV[1]
  time = ARGV[2]
  image_path = ARGV[3]
  
  if message && time && image_path
    add_post(message, time, image_path)
  else
    puts "Usage: ruby scheduler.rb add 'Message' 'YYYY-MM-DD HH:MM' '/path/to/image.jpg'"
  end

when 'run'
  run_scheduler

else
  puts "Usage:"
  puts "  To schedule: ruby scheduler.rb add 'Message' 'Time' 'Image_Path'"
  puts "  To check/run: ruby scheduler.rb run"
end