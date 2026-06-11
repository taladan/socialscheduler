module SocialScheduler
  module Commands
    class List
      # Define our ANSI color codes
      STRIPE_BG = "\e[48;5;236m" # 236 is a subtle dark gray. (Use 253 if you use a light terminal theme)
      RESET = "\e[0m"

      def initialize(options = {})
        @options = options
      end

      def call
        queue = Queue.new
        posts = queue.load.select { |p| p.status == 'pending' }

        # 1. APPLY FILTERS
        if @options[:category]
          posts.select! { |p| p.category && p.category.downcase.include?(@options[:category].downcase) }
        end

        if @options[:message]
          posts.select! { |p| p.message && p.message.downcase.include?(@options[:message].downcase) }
        end

        if @options[:image]
          posts.select! { |p| p.image_path && p.image_path.downcase.include?(@options[:image].downcase) }
        end

        if posts.empty?
          puts "📭 Queue is empty (or no posts match your filters)."
          return
        end

        # 2. CHOOSE VIEW
        if @options[:group]
          render_grouped(posts, @options[:group].downcase)
        else
          render_table(posts)
        end
      end

      private

      def render_table(posts)
        layout = "%-9s | %-8s | %-15s | %-35s | %-31s | %s"
        
        # don't strip header
        puts layout % ["ID", "Platform", "Category", "Scheduled Time", "Message", "File name"]
        puts "-" * 130

        # Sort chronologically and add an index to track the row number
        posts.sort_by { |p| Time.parse(p.time) }.each_with_index do |p, index|
          time_obj = Time.parse(p.time)
          time_str = time_obj.strftime('%A, %b %d, %Y at %l:%M%P')
          msg_raw = (p.message || "(Image Only)")
          msg = msg_raw.gsub("\n", " ")
          msg = msg.length > 30 ? msg[0..27] + "..." : msg

          img_name = (p.image_path && !p.image_path.empty?) ? File.basename(p.image_path) : ""

          row_text = layout % [p.id[0..7], p.platform[0..7], p.category || "None", time_str, msg, img_name]

          # Apply Zebra Striping
          if index.even?
            puts row_text
          else
            # add space to ensure the background color fills
            puts "#{STRIPE_BG}#{row_text.ljust(130)}#{RESET}"
          end
        end
      end

      def render_grouped(posts, group_field)
        grouped = posts.group_by do |p|
          case group_field
          when 'category' then p.category || 'Uncategorized'
          when 'image'    then p.image_path ? File.basename(p.image_path) : 'No Image'
          when 'message'  then p.message ? (p.message[0..30].gsub("\n", " ") + "...") : 'No Message'
          when 'series'   
            if p.series_id
              preview = p.message ? p.message[0..35].gsub("\n", " ") + "..." : "(Image Only)"
              "Series #{p.series_id[0..7]} | #{preview}"
            else
               "Single Posts"
            end
          else p.category || 'Uncategorized'
          end
        end

        grouped.each do |group_name, group_posts|
          puts "\n📁 #{group_name.to_s.upcase} (#{group_posts.count} posts)"
          puts "-" * 130 # Expanded line to match table width
          
          # chronological sort
          group_posts.sort_by { |p| Time.parse(p.time) }.each_with_index do |p, index|
            time_str = Time.parse(p.time).strftime('%m/%d/%y @ %I:%M%P')
            msg = p.message ? p.message[0..40].gsub("\n"," ") + '...' : '(Image Only)'
            cat = p.category ? "[#{p.category[0..12]}]".ljust(15) : "[None]         "
            img_indicator = (p.image_path && !p.image_path.empty?) ? " 🖼️  #{File.basename(p.image_path)}" : ""
            
            row_text = "   [#{p.id[0..7]}]  🗓️  #{time_str.ljust(18)} #{cat} 📝 #{msg.ljust(45)}#{img_indicator}"

            # zebrastripe
            if index.even?
              puts row_text
            else
              puts "#{STRIPE_BG}#{row_text.ljust(130)}#{RESET}"
            end
          end
        end
        puts "\n"
      end
    end
  end
end