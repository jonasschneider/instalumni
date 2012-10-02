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
  #require('net/http');require('uri');require('json');Net::HTTP.post_form(URI.parse("http://requestb.in/???PUTURLHERE???"), d:JSON.dump(Person.all.map{|p|{name: p.name, original_name: p.name, email: p.email, uid: p.uid, meta_meister: p.lks, meta_nachabi: p.nachabi, meta_zukunft: p.zukunft, meta_lebenswichtig: p.lebenswichtig, meta_nachruf: p.nachruf, json_tags: JSON.dump(p.tags.map{|t|t.name})}}))
  require 'json'

  JSON.parse(File.read('data.json')).each do |data|
    u = User.new
    u.update_attributes! data, without_protection: true
    u.save!
  end
end

task :send_scheduled_reminders => :environment do
  u = User.find_by_uid('dummy')
  raise "could not find dummy user" unless u

  def do_it!
    #users = User.where(uid: 'schneijo')
    Users = User.all
    users.each do |u|
      begin
        if u.uid != 'dummy'
          u.send_reminder!
        end
      rescue Exception => e
        puts "failed sending to #{u.uid} <#{u.email}>: #{e.inspect}"
      end
    end
  end

  if u.updated_at < 180.days.ago
    begin
      puts "time to send a reminder!"
      do_it!
      puts "done sending"
    ensure
      u.touch
    end
  end

  eta = (u.updated_at - 180.days.ago) / 1.day
  puts "about #{eta} days until next reminder"
end

task :keep_heroku_awake do
  require 'open-uri'

  begin
    Timeout.timeout(10) do
      open('https://instalumni.herokuapp.com/').read
    end
  rescue Exception => e
  end
end
