require 'fileutils'

# --- CONFIGURATION ---
APP_DIR = Dir.pwd
RUBY_PATH = `which ruby`.strip
SCRIPT_PATH = File.join(APP_DIR, 'bin', 'ssched') 
SERVICE_NAME = 'socialscheduler'
BIN_NAME = 'ssched'
USER_BIN_DIR = File.expand_path("~/.local/bin")

# --- COLORS ---
GREEN = "\e[32m"
BLUE = "\e[34m"
RESET = "\e[0m"

puts "#{GREEN}🚀 Installing SocialScheduler...#{RESET}"
puts "   Directory: #{APP_DIR}"

# 1. Install Systemd Service (User level)
SERVICE_CONTENT = <<~SERVICE
[Unit]
Description=Social Scheduler Daemon
After=network.target

[Service]
Type=oneshot
ExecStart=#{RUBY_PATH} #{SCRIPT_PATH} run
WorkingDirectory=#{APP_DIR}

[Install]
WantedBy=default.target
SERVICE

TIMER_CONTENT = <<~TIMER
[Unit]
Description=Run Social Scheduler every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=#{SERVICE_NAME}.service

[Install]
WantedBy=timers.target
TIMER

# Create systemd user directory if it doesn't exist
systemd_dir = File.expand_path("~/.config/systemd/user")
FileUtils.mkdir_p(systemd_dir)

# Write service files
File.write("#{systemd_dir}/#{SERVICE_NAME}.service", SERVICE_CONTENT)
File.write("#{systemd_dir}/#{SERVICE_NAME}.timer", TIMER_CONTENT)

puts "#{BLUE}🔵 Systemd detected. Installing user service...#{RESET}"

# Enable and start the timer
system("systemctl --user daemon-reload")
system("systemctl --user enable #{SERVICE_NAME}.timer")
system("systemctl --user start #{SERVICE_NAME}.timer")
puts "#{GREEN}✅ Systemd installation complete.#{RESET}"

# 2. Create the Symlink (The 'ssched' command)
FileUtils.mkdir_p(USER_BIN_DIR)
target_link = File.join(USER_BIN_DIR, BIN_NAME)

# Remove existing link if it exists
FileUtils.rm(target_link) if File.exist?(target_link)

# Create new link
File.symlink(SCRIPT_PATH, target_link)
puts "#{BLUE}🔵 Creating command '#{BIN_NAME}'...#{RESET}"
puts "#{GREEN}✅ Command installed to: #{target_link}#{RESET}"

# 3. Interactive Configuration Prompt
puts "\n--------------------------------------------------"
puts "🔑 Initial Configuration"
puts "--------------------------------------------------"
puts "Would you like to configure your API keys now? (y/n)"
print "> "
answer = gets.chomp.downcase

if answer == 'y'
  # We use the full path to the script to ensure it runs the version we just installed
  system("#{RUBY_PATH} #{SCRIPT_PATH} config")
else
  puts "⚠️  Skipping configuration. You can run 'ssched config' later."
end

puts "\n#{GREEN}🎉 Setup finished!#{RESET}"
puts "You can now use the command: ssched"
puts "Example: ssched -m 'Hello World' -t 'tomorrow at noon'"