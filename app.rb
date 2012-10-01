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

  has_many :posts

  attr_accessible :name, :address, :zip_city, :country, :phone, :email, :custom1_name, :custom1_value, :custom2_name, :custom2_value

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
  belongs_to :user
  attr_accessible :body
  validates_presence_of :body
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
  haml :index
end

get '/edit' do
  haml :edit
end

post '/update' do
  if @user.update_attributes(params[:user])
    flash[:info] = 'Deine Kontaktdaten wurden gespeichert.'
    redirect '/'
  else
    haml :edit
  end
end

post '/posts' do
  post = @user.posts.build(params[:post])
  if post.save
    flash[:info] = 'Dein Eintrag wurde gespeichert.'
    redirect '/'
  else
    flash[:error] = 'Dein Eintrag konnte nicht gespeichert werden. Falls das Problem besteht, wende dich an uns.'
    redirect '/'
  end
end