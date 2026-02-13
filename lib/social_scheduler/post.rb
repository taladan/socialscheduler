module SocialScheduler
  class Post
    attr_accessor :category, :id, :series_id, :message, :time, :image_path, :status, :platform

    def initialize(data = {})
      @category = data['category']
      @id = data['id'] || SecureRandom.uuid
      @series_id = data['series_id']
      @message = data['message']
      @time = data['time'] # Stored as string
      @image_path = data['image_path']
      @status = data['status'] || 'pending'
      @platform = data['platform'] || 'facebook'
    end

    def to_h
      {
        'category' => @category,
        'id' => @id,
        'series_id' => @series_id,
        'message' => @message,
        'time' => @time,
        'image_path' => @image_path,
        'status' => @status,
        'platform' => @platform
      }
    end

    def due?(current_time = Time.now)
      return false unless @status == 'pending'
      Time.parse(@time) <= current_time
    end

    def valid?
      (!@message.nil? || !@image_path.nil?)
    end
  end
end
