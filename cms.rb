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

root = File.expand_path('..', __FILE__)

def render_markdown(markdown_text)
  markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown_renderer.render(markdown_text)
end

def load_file_content(file_path)
  content = File.read(file_path)
  case File.extname(file_path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    File.read(file_path)
  when '.md'
    render_markdown(content)
  end
end

get '/' do
  @files_in_data = Dir.glob(root + '/data/*'). map do |path|
    File.basename(path)
  end
  erb :index, layout: :layout
end

get '/:file_name' do
  file_name = params[:file_name]
  file_path = root + '/data/' + file_name

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end
end

get '/:file_name/edit' do
  @file_name = params[:file_name]
  file_path = root + '/data/' + @file_name
  @file_content = File.read(file_path)
  erb :edit, layout: :layout
end

post '/:file_name' do
  @file_name = params[:file_name]
  file_path = root + '/data/' + @file_name
  File.write(file_path, params['file_edit'])
  session[:message] = "#{@file_name} has been updated."
  redirect '/'
end
