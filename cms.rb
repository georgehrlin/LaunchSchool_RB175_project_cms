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
  erb :home, layout: :layout
end
