RSpec.describe SocialScheduler::Post do
  let(:valid_attributes) do
    {
      'message' => 'Hello World',
      'time' => (Time.now + 3600).to_s,
      'image_path' => '/tmp/test.jpg'
    }
  end

  describe '#initialize' do
    it 'creates a post with a generated ID' do
      post = described_class.new(valid_attributes)
      expect(post.id).not_to be_nil
    end

    it 'defaults status to pending' do
      post = described_class.new(valid_attributes)
      expect(post.status).to eq('pending')
    end
  end

  describe '#valid?' do
    it 'is valid with a message' do
      post = described_class.new('message' => 'Hi')
      expect(post.valid?).to be true
    end

    it 'is invalid without message or image' do
      post = described_class.new({})
      expect(post.valid?).to be false
    end
  end

  describe '#due?' do
    it 'returns true if the time has passed' do
      past_time = (Time.now - 60).to_s
      post = described_class.new('time' => past_time)
      expect(post.due?).to be true
    end
  end
end