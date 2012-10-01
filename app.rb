require 'sinatra'

get '/' do
  haml :index
end

get '/edit' do
  haml :edit
end