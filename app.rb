# encoding: UTF-8
require 'bundler'
Bundler.require(:default)

require 'logger'
require 'erb'

require 'securerandom'


enable :sessions
set :session_secret, ENV["SESSION_SECRET"]

ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])

Pony.options = {
  :via => :smtp,
  :via_options => {
    :address => 'smtp.sendgrid.net',
    :port => '587',
    :domain => 'heroku.com',
    :user_name => ENV['SENDGRID_USERNAME'],
    :password => ENV['SENDGRID_PASSWORD'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
}

class User < ActiveRecord::Base
  validates_presence_of :name, :original_name, :email, :auth_token
  validates :uid, presence: true, uniqueness: true

  has_many :posts

  attr_accessible :name, :address, :zip_city, :country, :phone, :email, :custom1_name, :custom1_value, :custom2_name, :custom2_value

  before_validation :regenerate_token!, on: :create

  def regenerate_token!
    self.auth_token = SecureRandom.hex
    save! unless new_record?
  end

  def firstname
    return "Nhung" if uid == 'phanthsa' # ;)
    name.split(/\s+/).first rescue ''
  end

  def random_tag
    tags = JSON.parse(json_tags) rescue []
    tags.sample
  end

  def meta_meister
    read_attribute(:meta_meister).gsub(/\(IM!\)\s?/, "")
  end

  def send_reminder!
    return if email.nil? or email.blank?

    template = File.read(File.join(settings.views, 'mail.erb'))
    body = ERB.new(template).result(self.instance_eval { binding })
    subject = "[instALUMNI] Halbjährliche Erinnerung: Dein Fichte-Alumniportal!"
    Pony.mail(:to => self.email, :from => 'js.sokrates@gmail.com', :subject => subject, :body => body)
  end

  def send_welcome!
    return if email.nil? or email.blank?

    template = File.read(File.join(settings.views, 'welcome.erb'))
    body = ERB.new(template).result(self.instance_eval { binding })
    subject = "[instALUMNI] Halbjährliche Erinnerung: Dein Fichte-Alumniportal!"
    Pony.mail(:to => self.email, :from => 'js.sokrates@gmail.com', :subject => subject, :body => body)
  end
end

class Post < ActiveRecord::Base
  belongs_to :user
  attr_accessible :body
  validates_presence_of :body, :user
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