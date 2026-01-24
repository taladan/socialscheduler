require 'fileutils'

# --- CONFIGURATION ---
APP_DIR = Dir.pwd
RUBY_PATH = `which ruby`.strip
SCRIPT_PATH = File.join(APP_DIR, 'socialscheduler.rb')
SERVICE_NAME = 'socialscheduler'

# Shortcommand
BIN_NAME = 'ssched'

# Command path
USER_BIN_DIR = File.expand_path("~/.local/bin")

def systemd_available?
  # specific check for user-level systemd availability
  system('systemctl --user list-units > /dev/null 2>&1')
end

def install_systemd
  puts "🔵 Systemd detected. Installing user service..."

  # 1. Create directory if it doesn't exist
  systemd_dir = File.expand_path("~/.config/systemd/user")
  FileUtils.mkdir_p(systemd_dir)

  # 2. Create the .service file
  service_content = <<~SERVICE
    [Unit]
    Description=Facebook Scheduler Runner

    [Service]
    Type=oneshot
    WorkingDirectory=#{APP_DIR}
    ExecStart=#{RUBY_PATH} #{SCRIPT_PATH} run
  SERVICE

  File.write("#{systemd_dir}/#{SERVICE_NAME}.service", service_content)

  # 3. Create the .timer file
  timer_content = <<~TIMER
    [Unit]
    Description=Run Social Scheduler every minute

    [Timer]
    OnCalendar=*:0/1
    Persistent=true

    [Install]
    WantedBy=timers.target
  TIMER

  File.write("#{systemd_dir}/#{SERVICE_NAME}.timer", timer_content)

  # 4. Activate
  puts "   - Reloading daemon and starting timer..."
  system('systemctl --user daemon-reload')
  system("systemctl --user enable #{SERVICE_NAME}.timer")
  system("systemctl --user start #{SERVICE_NAME}.timer")
  
  puts "✅ Systemd installation complete."
end

def install_cron
  puts "🟠 Systemd not found. Falling back to Cron..."

  # 1. Prepare the command
  # We redirect output to a log file so the user can debug issues
  cron_cmd = "* * * * * #{RUBY_PATH} #{SCRIPT_PATH} run >> #{APP_DIR}/cron_log.txt 2>&1"
  
  # 2. Read current crontab
  current_crontab = `crontab -l 2>/dev/null`

  # 3. Check for duplicates to prevent adding it twice
  if current_crontab.include?(SCRIPT_PATH)
    puts "⚠️  It looks like this script is already in your crontab."
    return
  end

  # 4. Append and save
  new_crontab = "#{current_crontab}\n#{cron_cmd}\n"
  
  # Write to a temp file then load it
  File.write('temp_cron', new_crontab)
  system('crontab temp_cron')
  File.delete('temp_cron')

  puts "✅ Cron installation complete."
end

def install_cli_command
  puts "🔵 Creating command '#{BIN_NAME}'..."

  # Ensure ~/.local/bin exists
  FileUtils.mkdir_p(USER_BIN_DIR)

  wrapper_path = File.join(USER_BIN_DIR, BIN_NAME)

  # Create a bash wrapper script
  wrapper_content = <<~BASH
    #!/bin/bash
    # Forward all arguments to the ruby script
    #{RUBY_PATH} #{SCRIPT_PATH} "$0"
  BASH

  File.write(wrapper_path, wrapper_content)
  File.chmod(0755, wrapper_path) # Executable

  puts "✅ Command installed to: #{wrapper_path}"

  # Check if ~/.local/bin  is in user's PATH
  unless ENV['PATH'].include?(USER_BIN_DIR)
    puts "⚠️  NOTE: You may need to restart your terminal or add this to your .bashrc:"
    puts "   export PATH=\"$HOME/.local/bin:$PATH\""
  end
end
# --- MAIN LOGIC ---

puts "🚀 Installing SocialScheduler..."
puts "   Directory: #{APP_DIR}"

if systemd_available?
  install_systemd
else
  install_cron
end

install_cli_command


puts "\n🎉 Setup finished!"
puts "You can now use the command: #{BIN_NAME}"
puts "Example: #{BIN_NAME} add 'Hello World' '2023-10-31 12:00' 'image.jpg'"