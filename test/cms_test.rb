ENV["RACK_ENV"] = "test"

require 'fileutils'

require 'minitest/autorun'
require 'rack/test'

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def test_index
    create_document 'about.md'
    create_document 'changes.txt'

    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
  end

  def test_viewing_text_document
    create_document 'about.txt', "I am about.txt line1.\nI am about.txt line 2."

    get '/about.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, 'I am about.txt line 2.'
  end

  def test_invalid_file_name
    get '/iaminvalid.file'
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'iaminvalid.file does not exist.'

    get '/'
    refute_includes last_response.body, 'iaminvalid.file does not exist.'
  end

  def test_markdown_to_html
    create_document 'markdown.md', "# Markdown is...\n - A lightweight markup language\n- Used to add formatting to plain text files"

    get '/markdown.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'to add formatting to plain text files'
  end

  def test_editing_a_document
    create_document 'javascript.md', "# JavaScript is...\n - A high-level, multi-paradigm programming language"

    get '/javascript.md/edit'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_updating_a_document
    create_document 'javascript.md', "# JavaScript is...\n - A high-level, multi-paradigm programming language"

    post '/javascript.md', file_edit: 'testing'
    assert_equal 302, last_response.status

    get last_response['Location']
    assert_includes last_response.body, "javascript.md has been updated."

    get '/javascript.md'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'testing'
  end
end
