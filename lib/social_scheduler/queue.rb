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

    def update(updated_post)
      posts = load
      # Get matching index
      index = posts.find_index { |p| p.id == updated_post.id }

      if index
        posts[index] = updated_post
        save(posts)
        return true
      else
        return false
      end
    end

    def pending_posts
      load.select { |p| p.due? }
    end

    def remove(post_id)
      posts = load
      posts.reject! { |p| p.id == post_id }
      save(posts)
    end

    def remove_series(series_id)
      return 0 if series_id.nil?

      posts = load
      original_count = posts.count 
      posts.reject! { |p| p.series_id == series_id}

      save(posts)
      original_count - posts.count
    end

    def find_by_prefix(prefix)
      return [] if prefix.nil? || prefix.empty?
      load.select { |p| p.id.start_with?(prefix)}
    end

    def find_by_category(category)
      return [] if category.nil? || category.empty?
      load.select { |p| p.category.downcase == category.downcase}
    end
  end
end
