# encoding: UTF-8
require 'bundler'
Bundler.require(:default)

require 'logger'
require 'erb'
require 'geocoder/railtie'
Geocoder::Railtie.insert
require 'securerandom'

require_relative 'constants'


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
  belongs_to :avatar

  has_many :posts

  before_validation :regenerate_token!, on: :create

  def regenerate_token!
    self.auth_token = SecureRandom.hex
    save! unless new_record?
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

    template = File.read(File.join(Sinatra::Application.settings.views, 'email_reminder.erb'))
    body = ERB.new(template).result(self.instance_eval { binding })
    subject = "[instALUMNI] Halbjährliche Erinnerung: Dein Fichte-Alumniportal!"
    Pony.mail(:to => self.email, :from => 'js.sokrates@gmail.com', :subject => subject, :body => body)
  end

  def send_welcome!
    return if email.nil? or email.blank?

    template = File.read(File.join(Sinatra::Application.settings.views, 'email_welcome.erb'))
    body = ERB.new(template).result(self.instance_eval { binding })
    subject = "[instALUMNI] Dein Fichte-Alumniportal instALUMNI startet!"
    Pony.mail(:to => self.email, :from => 'js.sokrates@gmail.com', :subject => subject, :body => body)
  end

  def send_update!
    return if email.nil? or email.blank?

    Pony.mail(:to => self.email, :from => 'js.sokrates@gmail.com', :subject => update_subject, :body => update_body)
  end

  def update_body
    template = File.read(File.join(Sinatra::Application.settings.views, 'email_update.erb'))
    body = ERB.new(template).result(self.instance_eval { binding })
  end

  def update_subject
    names = (patrees_without_address+patrees_without_recent_post).map(&:firstname).uniq.first(3)
    if names.length > 1
      "[instALUMNI] #{firstname}, wo sind eigentlich #{names.join(", ").sub(/(.*), /, "\\1 und ")}?"
    elsif names.length == 1
      "[instALUMNI] #{firstname}, wo ist eigentlich #{names.first}?"
    else
      "[instALUMNI] #{firstname}, der Awesome-Modus wurde aktiviert!"
    end
  end

  geocoded_by :geocode_address
  after_validation :geocode

  def geocode_address
    [city, country].compact.join(", ")
  end

  def city
    zip_city ? zip_city.gsub(/\d/, '').strip : nil
  end

  def name
    return "Raphaël Kraif" if uid == "kraifra"
    super
  end

  def firstname
    return "Sarah" if uid == "henkensa"
    return "Nhung" if uid == "phanthsa"
    return "Raphaël" if uid == "kraifra"
    len = I18n.transliterate(name).match(/^[A-Z][a-z]*(\-[A-Z][a-z]+)?/).try(:to_s).try(:length)
    return unless len
    name[0, len]
  end

  def patrees_without_recent_post
    User.where('uid IN (?)', SYMMETRICAL_CONNECTION_MAP[self.uid]).select{|u|u.posts.where('created_at > ?', 1.year.ago-60.days).empty?}.first(3)
  end

  def patrees_without_address
    User.where('uid IN (?)', SYMMETRICAL_CONNECTION_MAP[self.uid]).select{|u|u.posts.where('created_at > ?', 1.year.ago-60.days).empty? && !u.address.present?}.first(3)
  end
end

class Post < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :body, :user
end

class Shout < ActiveRecord::Base
  belongs_to :author, class_name: 'User'
  validates_presence_of :body, :author

  CAP = 10
  scope :newest, -> { order('created_at DESC').limit(CAP) }

  def client_attributes
    { author: author.name, created_at: created_at.strftime('%d.%m. %H:%M'), body: CGI.escapeHTML(body.gsub('\\', '')) }
  end
end

class Avatar < ActiveRecord::Base
  validates :image, :ugly_image, presence: true
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

  def avatar(user, opts={})
    scale = opts[:scale] || 2
    id = SecureRandom.hex
    source = "/avatars/#{user.avatar_id}"

    bg_color = "000"

    markup = capture_haml do
      haml_tag :svg, style: 'position: absolute;top:-100000px;left:-100000px' do
        haml_tag :clipPath, id: id do
          haml_tag :circle, cx: 30*scale, cy: 20*scale, r: 28*scale
        end
      end
      haml_tag :img, alt: "Bild von #{user.name}", src: source, style: "width: #{58*scale}px; height: #{75*scale}px;margin-top:#{-5*scale}px; background: ##{bg_color}; -webkit-clip-path: circle(#{28*scale}px at #{30*scale}px #{30*scale}px);clip-path: url(##{id});-webkit-filter:saturate(0) brightness(1.4)"
    end
    markup
  end
end

get '/' do
  haml :index
end

get '/all' do
  haml :all
end

if ENV["EYETRACK"]
  get '/eyetrack' do
    haml :eyetrack
  end
end

get '/edit' do
  haml :edit
end

post '/update' do
  if @user.update_attributes(params[:user].slice(:name, :address, :zip_city, :country, :phone, :email, :custom1_name, :custom1_value, :custom2_name, :custom2_value, :public_address))
    flash[:info] = 'Deine Kontaktdaten wurden gespeichert.'
    redirect '/'
  else
    haml :edit
  end
end

get "/avatars/:id" do
  a = Avatar.find(params[:id])
  content_type "image/jpg"
  cache_control :public, max_age: 60*60*24*365
  a.ugly_image
end

get "/my_avatar/edit" do
  haml :upload
end

put "/my_avatar" do
  img = params[:image][:tempfile].read.force_encoding('BINARY')

  a = Avatar.create!(image: img, ugly_image: img, eyeline: Float(params[:eyeline]))
  @user.avatar = a
  @user.save!
  flash[:info] = "Dein Bild wurde gespeichert!"
  redirect '/'
end

post '/posts' do
  post = @user.posts.build(params["post"].slice("body"))
  if post.save
    flash[:info] = 'Dein Eintrag wurde gespeichert.'
    redirect '/'
  else
    flash[:error] = 'Dein Eintrag konnte nicht gespeichert werden. Falls das Problem bestehen bleibt, wende dich an uns.'
    redirect '/'
  end
end

post '/shouts' do
  @shout = Shout.new(author: @user)
  @shout.update params["shout"].slice("body")
  @shout.save!
  redirect '/#shouts'
end
