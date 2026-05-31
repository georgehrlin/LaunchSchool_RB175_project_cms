require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/reloader'
require 'tilt/erubi'
require 'redcarpet'

require 'pry-byebug'

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

get '/' do
  pattern = File.join(data_path, '*')
  @files_in_data = Dir.glob(pattern). map do |path|
    File.basename(path)
  end
  erb :index, layout: :layout
end

get '/new' do
  erb :new, layout: :layout
end

post '/new' do
  new_file_name = params[:new_file]
  if new_file_name.empty?
    session[:message] = 'A name is required.'
    redirect '/new'
  else
    File.new("data/#{new_file_name}", 'wx')
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
  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)
  @file_content = File.read(file_path)
  erb :edit, layout: :layout
end

post '/:file_name' do
  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)
  File.write(file_path, params['file_edit'])
  session[:message] = "#{@file_name} has been updated."
  redirect '/'
end
