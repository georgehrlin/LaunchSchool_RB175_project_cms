require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/reloader'
require 'tilt/erubi'

root = File.expand_path("..", __FILE__)

get "/" do
  # @files = Dir.children("data/") # Original solution from myself
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :index, layout: :layout
end

get "/:filename" do
  # @file = File.readlines("data/#{params[:file_name]}") # Original solution from myself
  file_path = root + "/data/" + params[:filename]

  headers["Content-Type"] = "text/plain"
  File.read(file_path)
end
