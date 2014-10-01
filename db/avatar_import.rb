require_relative '../app'
require 'subprocess'
require 'fileutils'

Dir["var/avatars/*"].each do |a|
  ugly = "tmp/ugly.jpg"
  Subprocess.check_output(["convert", a, "-quality", "35%", ugly])
  uid = File.basename(a, File.extname(a))
  user = User.where(uid: uid).first
  raise a unless user
  user.avatar = Avatar.create!(image: File.read(a).force_encoding('BINARY'), ugly_image:File.read(ugly).force_encoding('BINARY'))
  user.save!
  FileUtils.rm(ugly)
end
