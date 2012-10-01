require 'bundler'
Bundler.require(:default)

require 'logger'
require 'active_record'

require 'securerandom'

enable :sessions
set :session_secret, ENV["SESSION_SECRET"]

ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])

class User < ActiveRecord::Base
  validates_presence_of :name, :original_name, :email, :auth_token
  validates :uid, presence: true, uniqueness: true

  before_validation on: :create do
    self.auth_token = SecureRandom.hex
  end

  def firstname
    name.split(/\s+/).first rescue ''
  end

  def random_tag
    tags = JSON.parse(json_tags) rescue []
    tags.sample
  end
end

class Post < ActiveRecord::Base

end

before do
  session[:auth_token] = params[:auth_token] if params[:auth_token]
  if session[:auth_token] && u = User.find_by_auth_token(session[:auth_token])
    @user = u
  else
    halt 403, haml(:splash)
  end
end

helpers do
  def e(string)
    if string.nil? || string.empty?
      '(leer)'
    else
      string
    end
  end
end

get '/' do
  #raise User.all.inspect
  haml :index
end

get '/edit' do
  haml :edit
end