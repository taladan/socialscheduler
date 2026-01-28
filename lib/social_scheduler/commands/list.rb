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

        layout = "%-9s | %-8s | %-35s | %s"
        puts layout % ["ID", "Platform", "Scheduled Time", "Message"]
        puts "-" * 85

        posts.each do |p|
          time_obj = Time.parse(p.time)
          time_str = time_obj.strftime('%A, %b %d, %Y at %l:%M%P')
          msg = (p.message || "(Image Only)").gsub("
", " ")
          msg = msg.length > 30 ? msg[0..27] + "..." : msg
          puts layout % [p.id[0..7], p.platform[0..7], time_str, msg]
        end
      end
    end
  end
end
