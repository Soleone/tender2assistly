require 'test/unit'
require File.dirname(__FILE__) + '/../lib/tender2assistly'

class Test::Unit::TestCase


  private
  
  def read_fixture(filename)
    File.dirname(__FILE__) + "/fixtures/#{filename}.yml"
  end

end