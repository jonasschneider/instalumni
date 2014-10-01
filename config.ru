require './app'
require 'sprockets'
require 'rack/cache'

env = Sprockets::Environment.new
env.append_path "assets"

use Rack::Cache,
  :verbose     => true,
  :metastore   => 'heap:/',
  :entitystore => 'heap:/'

map '/assets' do
  run env
end

map '/' do
  use ActiveRecord::ConnectionAdapters::ConnectionManagement
  run Sinatra::Application
end
