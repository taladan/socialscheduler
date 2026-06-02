RSpec.describe SocialScheduler::Platforms::Facebook do
  # 1. Create a "fake" API object
  let(:mock_api) { instance_double(Koala::Facebook::API) }
  
  # 2. Fake the secrets loader so we don't need a real secrets.json
  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:read).and_return('{"page_access_token": "fake_token"}')
    # When our code calls Koala.new, give it our fake object
    allow(Koala::Facebook::API).to receive(:new).and_return(mock_api)
  end

  describe '#post' do
    context 'with an image' do
      it 'calls put_picture' do
        # Create a post object that has an image
        post = SocialScheduler::Post.new(
          'message' => 'Caption',
          'image_path' => '/tmp/fake.jpg'
        )
        
        # We tell the test: "Assume this file actually exists"
        allow(File).to receive(:exist?).with('/tmp/fake.jpg').and_return(true)

        # THE TEST: Expect put_picture to be called with specific args
        expect(mock_api).to receive(:put_picture).with('/tmp/fake.jpg', { caption: 'Caption' })

        # Run the code
        subject.post(post)
      end
    end

    context 'text only' do
      it 'calls put_connections' do
        post = SocialScheduler::Post.new('message' => 'Just text')

        # THE TEST: Expect put_connections to be called
        expect(mock_api).to receive(:put_connections).with("me", "feed", message: 'Just text')

        subject.post(post)
      end
    end
  end
end