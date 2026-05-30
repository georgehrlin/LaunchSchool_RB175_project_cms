require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/reloader'
require 'tilt/erubi'
require 'pry-byebug'

enable :sessions

before do
  @root = File.expand_path('..', __FILE__)
  @files_in_data = Dir.glob(@root + '/data/*').map { |path| File.basename(path) }
end

def valid_file_name?(file_name)
  @files_in_data.include?(file_name)
end

get '/' do
  erb :index, layout: :layout
end

get '/:file_name' do
  file_name = params[:file_name]

  if valid_file_name?(file_name)
    file_path = @root + '/data/' + file_name
    headers['Content-Type'] = 'text/plain'
    File.read(file_path)
  else
    session[:error] = "#{file_name} does not exist."
    redirect '/'
  end
end
