module SocialScheduler
  class Queue
    def initialize
      @file = SocialScheduler::QUEUE_FILE
    end

    def load
      return [] unless File.exist?(@file)
      data = JSON.parse(File.read(@file))
      # Convert hashes back into Post objects
      data.map { |d| Post.new(d) }
    end

    def save(posts)
      data = posts.map(&:to_h)
      File.write(@file, JSON.pretty_generate(data))
    end

    def add(post)
      posts = load
      posts << post
      save(posts)
    end

    def pending_posts
      load.select { |p| p.due? }
    end

    def remove(post_id)
      posts = load
      posts.reject! { |p| p.id == post_id }
      save(posts)
    end

    def find_by_prefix(prefix)
      return [] if prefix.nil? || prefix.empty?
      load.select { |p| p.id.start_with?(prefix)}
    end
  end
end
