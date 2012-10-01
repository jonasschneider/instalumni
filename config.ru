require './app'
require 'sprockets'

env = Sprockets::Environment.new
env.append_path "assets"

map '/assets' do
  run env
end

map '/' do
  run Sinatra::Application
end