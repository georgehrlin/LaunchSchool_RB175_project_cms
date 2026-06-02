require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/reloader'
require 'tilt/erubi'
require 'redcarpet'
require 'yaml'

require 'pry-byebug'

CREDENTIALS = YAML.load_file('signin_credentials.yml')

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def render_markdown(markdown_text)
  markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown_renderer.render(markdown_text)
end

def load_file_content(file_path)
  content = File.read(file_path)
  case File.extname(file_path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    erb render_markdown(content)
  end
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = 'You must be signed in to do that.'
    redirect '/'
  end
end

get '/' do
  pattern = File.join(data_path, '*')
  @files_in_data = Dir.glob(pattern). map do |path|
    File.basename(path)
  end
  erb :index
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  username = params[:username]
  password = params[:password]

  if CREDENTIALS.key?(username) && CREDENTIALS[username] == password
    session[:username] = username
    session[:message] = 'Welcome!'
    redirect '/'
  else
    status 422
    session[:message] = 'Invalid credentials.'
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:username)
  session[:message] = 'You are signed out.'
  redirect '/'
end

get '/new' do
  require_signed_in_user
  erb :new
end

post '/new' do
  require_signed_in_user

  new_file_name = params[:new_file]

  if new_file_name.empty?
    session[:message] = 'A name is required.'
    status 422
    erb :new
  elsif !new_file_name.end_with?('.md') && !new_file_name.end_with?('.txt')
    session[:message] = 'The file type must be .md or .txt.'
    status 422
    erb :new
  else
    new_file_path = File.join(data_path, new_file_name)
    File.new(new_file_path, 'wx')
    session[:message] = "#{new_file_name} was created."
    redirect '/'
  end
end

get '/:file_name' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end
end

get '/:file_name/edit' do
  require_signed_in_user

  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)
  @file_content = File.read(file_path)
  erb :edit
end

post '/:file_name' do
  require_signed_in_user

  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)
  File.write(file_path, params['file_edit'])
  session[:message] = "#{@file_name} has been updated."
  redirect '/'
end

post '/:file_name/delete' do
  require_signed_in_user

  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)
  File.delete(file_path)
  session[:message] = "#{file_name} has been deleted."
  redirect '/'
end
