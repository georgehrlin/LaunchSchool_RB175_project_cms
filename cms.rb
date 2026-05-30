require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/reloader'
require 'tilt/erubi'
require 'redcarpet'

require 'pry-byebug'

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

root = File.expand_path('..', __FILE__)

helpers do
  def render_markdown(markdown_text)
    markdown.render(markdown_text)
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

  if File.file?(file_path)
    if File.basename(file_path).end_with?('.md')
      markdown.render(File.read(file_path))
    else
      headers['Content-Type'] = 'text/plain'
      File.read(file_path)
    end
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end
end
