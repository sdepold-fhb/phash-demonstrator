require "rubygems"
require "sinatra"
require "sinatra/reloader" if development?
require "phashion"
require "erb"
require File.dirname(__FILE__) + "/vendor/mojo_magick/lib/mojo_magick.rb"

IMAGE_UPLOAD_PATH = "./public/uploads"

def modify_image(params)
  path = File.expand_path("#{IMAGE_UPLOAD_PATH}/#{params[:filename]}")
  file_ending = MojoMagick::file_ending("#{path}/source*")
  source_path = "#{path}/source.#{file_ending}"
  options = {:quality => params["quality"] || 100, :percent => params["scale"] || 100}
  options_as_string = options.to_a.map{|o| o.join("")}.join("")
  modified = "#{options_as_string}.#{file_ending}"
  modified_path = "#{path}/#{modified}"

  unless File.exists? modified_path
    puts "woooot"
    MojoMagick::resize(source_path, modified_path, options)
  end
  
  modified
end

def compare_images(filename_1, filename_2, threshold=15)
  Phashion::Image::SETTINGS[:dupe_threshold] = threshold

  img1 = Phashion::Image.new(IMAGE_UPLOAD_PATH + "/" + filename_1)
  img2 = Phashion::Image.new(IMAGE_UPLOAD_PATH + "/" + filename_2)
  
  img1.duplicate?(img2)
end

get "/" do
  erb :index
end

get "/analyze/:filename/:file_ending" do
  erb :analyze
end

post "/upload" do
  upload_path = File.expand_path("#{IMAGE_UPLOAD_PATH}/#{Time.now.to_i}")
  file_ending = MojoMagick::file_ending(params[:image][:tempfile].path)
  source = upload_path + "/source.#{file_ending}"

  FileUtils.mkdir_p(upload_path)
  FileUtils.mv(params[:image][:tempfile].path, source)
  
  MojoMagick::resize(source, upload_path + "/thumb.#{file_ending}", :width => 380, :height => 285, :absolute_aspect => true)
  MojoMagick::resize(source, upload_path + "/mini.#{file_ending}", :width => 240, :height => 180, :absolute_aspect => true)
    
  redirect "/analyze/#{File.basename(upload_path)}/#{file_ending}"
end

get "/modify/:filename" do
  modified_filename = modify_image params
  "<img width='380' height='285' src='/uploads/#{params[:filename]}/#{modified_filename}' />"
end

get "/compare/:path_1/:path_2" do
  # path_x is a path inside the public/uploads folder; slashes are masked as pipes
  result = compare_images(params[:path_1].gsub("|", "/"), params[:path_2].gsub("|", "/"), params["threshold"].to_i || 15)
  result ? "Equal" : "Not equal"
end