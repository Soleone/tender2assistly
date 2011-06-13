class Feed
  ASSET_PATTERN    = /"(\/assets\/\w{40}\/([^"]+))"/
  
  # use this to configure the feed mover
  class << self
    attr_accessor :domain, :tender_domain, :support_domain, :s3_username, :s3_password, :s3_bucket
  end
  
  attr_reader :new_content, :original_content
  
  def initialize(url)
    @url = url
    @original_content, @new_content = nil
    @s3_connection = RightAws::S3.new(self.class.s3_username, self.class.s3_password, :port => 80, :protocol => 'http') 
    @s3_bucket = @s3_connection.bucket(self.class.s3_bucket, true)
  end
  
  def move
    download
    replace_assets
    url = upload
    puts "Exported feed to #{url} (from #{@url})"
    url
  end
  
  
  private
  
  def download
    @original_content = download_file(@url)
  end  
  
  def upload
    key = "feed-#{feed_name(@url)}"
    upload_file(key, @new_content)
  end
  
  def replace_assets
    replace_urls unless @new_content
    @new_content
  end
  
  def replace_urls
    @new_content = @original_content.gsub(ASSET_PATTERN) do |match|
      fullpath = "http://#{self.class.tender_domain}#{$1}"
      filename = $2
      upload_file(filename, download_file(fullpath))
    end
    
    @new_content.gsub!(article_pattern, "http://#{self.class.tender_domain}")
  end
  
  def download_file(path)
    url = URI.parse(path)
    Net::HTTP.start(url.host, url.port) do |http|
      response = http.get(url.path)
      return download_file(response['location']) if response.kind_of?(Net::HTTPRedirection)
      response.body
    end
  end
  
  def upload_file(filename, content)
    return unless @s3_bucket.put(filename, content, {}, 'public-read', {'Content-Type' => content_type_for(filename), 'Cache-Control' => 'public, max-age=31557600'})
    bucket_url = 
    path = @s3_bucket.public_link.gsub(/:80/, '').gsub(/http[^s]/, 'https:')
    "#{path}/#{filename}"
  end

  
  def feed_name(path)
    path.split('/').last
  end

  def content_type_for(filename)
    if mime = MIME::Types.type_for(filename).first
      mime.content_type
    else
      'application/octet-stream'
    end
  end
  
  def article_pattern
    @article_pattern ||= /https?:\/\/#{Regexp.escape(self.class.support_domain)}/
  end
end