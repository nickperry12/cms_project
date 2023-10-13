require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

abs_path = File.expand_path("..", __FILE__)

get "/" do
  @files = Dir.children(abs_path + "/public/project_files").sort

  erb :index, layout: :layout
end

get "/:file_name" do
  file_name = params[:file_name].to_s
  @file_content = File.read(abs_path + "/public/project_files/#{file_name}")

  erb :file_content, layout: :layout
end
