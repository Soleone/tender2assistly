require File.dirname(__FILE__) + '/test_helper'

class AssetReplacerTest < Test::Unit::TestCase
  def setup
    credentials = read_fixture('credentials')
    Feed.s3_username = credentials['s3_username']
    Feed.s3_password = credentials['s3_password']
    Feed.s3_bucket   = credentials['s3_bucket']
    
    Feed.support_domain = 'support.yourcompany.com'
    Feed.tender_domain  = 'yourcompany.tenderapp.com'
    @feed_url = 'http://example.com/yourfeed.rss'
    @feed = Feed.new(@feed_url)
  end
    
  def test_extracts_tender_urls
    @feed.download
    assert_no_match /s3\.amazonaws\.com\/entp-tender-production/, @feed.send(:replace_assets)
  end
  
  def test_move
    asser_match /s3\.amazonaws\.com/, @feed.move
  end
  
  def test_content_type_for
    assert_equal 'image/jpeg', @feed.send(:content_type_for, 'test.jpg')
    assert_equal 'image/jpeg', @feed.send(:content_type_for, 'test.jpeg')
    assert_equal 'image/png',  @feed.send(:content_type_for, 'test.png')
    assert_equal 'image/gif',  @feed.send(:content_type_for, 'test.gif')
  end
end