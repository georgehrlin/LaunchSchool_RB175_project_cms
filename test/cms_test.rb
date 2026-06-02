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

  def session
    last_request.env['rack.session']
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

  def admin_session
    { 'rack.session' => { username: 'admin' } }
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
    get '/iaminvalid.md'
    assert_equal 302, last_response.status
    assert_equal 'iaminvalid.md does not exist.', session[:message]

    get '/'
    refute_includes last_response.body, 'iaminvalid.file does not exist.'
  end

  def test_markdown_to_html
    create_document 'markdown.md', "# Markdown is...\n - A lightweight markup language\n- Used to add formatting to plain text files"

    get '/markdown.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<h1>Markdown is...</h1>'
    assert_includes last_response.body, 'to add formatting to plain text files'
  end

  def test_acess_edit_page_of_a_document
    create_document 'javascript.md', "# JavaScript is...\n - A high-level, multi-paradigm programming language"

    get '/javascript.md/edit', {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_acess_edit_page_of_a_document_when_signed_out
    create_document 'javascript.md', "# JavaScript is...\n - A high-level, multi-paradigm programming language"

    get '/javascript.md/edit'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']
  end

  def test_update_a_document
    create_document 'javascript.md', "# JavaScript is...\n - A high-level, multi-paradigm programming language"

    post '/javascript.md', { file_edit: 'testing' }, admin_session
    assert_equal 'javascript.md has been updated.', session['message']
    assert_equal 302, last_response.status

    get '/javascript.md'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'testing'
  end

  def test_update_a_document_when_signed_out
    create_document 'javascript.md', "# JavaScript is...\n - A high-level, multi-paradigm programming language"

    post '/javascript.md'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']
  end

  def test_acccess_page_to_add_a_new_file
    get '/new', {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'a new document:'
  end

  def test_acccess_page_to_add_a_new_file_when_signed_out
    get '/new'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']
  end

  def test_add_a_new_file
    post '/new', { new_file: 'test_file.md' }, admin_session
    assert_equal 302, last_response.status
    assert_equal 'test_file.md was created.', session['message']
    assert File.exist?(File.join(data_path, 'test_file.md'))
  end

  def test_add_a_new_file_when_signed_out
    post '/new'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']
  end

  def test_add_a_new_file_without_a_name
    post '/new', {new_file: ''}, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A name is required.'
  end

  def test_delete_a_file
    create_document 'file_to_be_deleted.md'
    assert File.exist?(File.join(data_path, 'file_to_be_deleted.md'))

    post '/file_to_be_deleted.md/delete', {}, admin_session
    assert_equal 'file_to_be_deleted.md has been deleted.', session[:message]
    refute File.exist?(File.join(data_path, 'file_to_be_deleted.md'))
  end

  def test_delete_a_file_when_signed_out
    create_document 'file_to_be_deleted.md'
    assert File.exist?(File.join(data_path, 'file_to_be_deleted.md'))

    post '/file_to_be_deleted.md/delete'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']
  end

  def test_sign_in_with_valid_credentials
    credentials = load_credentials
    username = credentials.keys.sample
    password = credentials[username]
    post '/users/signin', username: username, password: password
    assert_equal 302, last_response.status
    assert_equal username, session[:username]
    assert_equal 'Welcome!', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'Welcome!'
  end

  def test_sign_in_with_invalid_credentials
    post '/users/signin', username: 'invalid', password: 'wrong password'
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, 'Invalid credentials.'
  end

  def test_sign_out_button
    get '/', {}, admin_session
    assert_includes last_response.body, "Signed in as admin."

    post '/users/signout'
    assert_equal 302, last_response.status
    assert_equal 'You are signed out.', session[:message]

    get last_response['Location']
    assert_nil session[:username]
    assert_includes last_response.body, 'Sign In'
  end
end
