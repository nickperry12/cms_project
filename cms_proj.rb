require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'redcarpet'

abs_path = File.expand_path("..", __FILE__)

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_content(file)
  content = File.read(file)

  case File.extname(file)
  when ".md"
    render_markdown(content)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  end
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  @files = Dir.glob(abs_path + "/public/project_files/*").map do |file|
    File.basename(file)
  end
end

get "/" do
  erb :index, layout: :layout
end

get "/:file_name" do
  file_name = params[:file_name].to_s
  file_path = "./public/project_files/#{file_name}"

  if !@files.include?(file_name)
    session[:error] = "#{file_name} does not exist."
    redirect "/"
  else
    load_content(file_path)
  end
end
