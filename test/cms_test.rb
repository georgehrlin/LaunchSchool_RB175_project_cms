ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'

require_relative '../cms.rb'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'about.txt'
    assert_includes last_response.body, 'changes.txt'
    assert_includes last_response.body, 'history.txt'
    assert_includes last_response.body, 'ruby.md'
  end

  def test_viewing_text_document
    get '/about.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, 'I am about.txt line 2.'
  end

  def test_invalid_file_name
    get '/iaminvalid.lol'
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'iaminvalid.lol does not exist.'

    get '/'
    refute_includes last_response.body, 'iaminvalid.lol does not exist.'
  end

  def test_markdown_to_html
    get '/ruby.md'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'simplicity and productivity'
  end

  def test_editing_a_document
    get '/javascript.md/edit'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_updating_a_document
    post '/javascript.md', file_edit: 'testing'
    assert_equal 302, last_response.status

    get last_response['Location']
    assert_includes last_response.body, "javascript.md has been updated."

    get '/javascript.md'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'testing'
  end
end
