module SocialScheduler
  module Commands
    class List
      def call
        queue = Queue.new
        posts = queue.load.select { |p| p.status == 'pending' }

        if posts.empty?
          puts "📭 Queue is empty."
          return
        end

        layout = "%-9s | %-8s | %-15s | %-35s | %-31s | %s"
        puts layout % ["ID", "Platform", "Category", "Scheduled Time", "Message", "File name"]
        puts "-" * 120

        posts.each do |p|
          time_obj = Time.parse(p.time)
          time_str = time_obj.strftime('%A, %b %d, %Y at %l:%M%P')
          msg_raw = (p.message || "(Image Only)")
          msg = msg_raw.gsub("\n", " ")
          msg = msg.length > 30 ? msg[0..27] + "..." : msg

          if p.image_path && !p.image_path.empty?
            img_name = File.basename(p.image_path)
            img_name = img_name.length > 20 ? "..." + img_name[-17..-1] : img_name
          else
            img_name = ""
          end

          puts layout % [p.id[0..7], p.platform[0..7], p.category, time_str, msg, File.basename(img_name)]
        end
      end
    end
  end
end
