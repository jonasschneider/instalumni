task :environment do
  require './app'
end

namespace :db do
  desc "Migrate the database"
  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end

task :import => :environment do
  require 'json'

  JSON.parse(File.read('data.json')).each do |data|
    u = User.new
    u.update_attributes! data, without_protection: true
    u.save!
  end
end

task :send_scheduled_reminders => :environment do
  u = User.where(uid: 'schneijo')

  def do_it!
    users = User.where(uid: 'schneijo')
    users.each do |u|
      u.send_reminder!
    rescue Exception => e
      puts "failed sending to #{u.uid} <#{u.email}>: #{e.inspect}"
    end
  end

  if u.updated_at < 180.days.ago
    puts "time to send a reminder!"
    do_it!
    u.touch
  end
  
end