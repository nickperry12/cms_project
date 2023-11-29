require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

# loads the list of valid users
def load_users
  users_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("./tests/users.yml")
  else
    File.expand_path("./public/users.yml")
  end
  YAML.load_file(users_path)
end

# renders the content of a markdown file
def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

# decides how to load content based on the file type
def load_content(file)
  content = File.read(file)

  case File.extname(file)
  when ".md"
    erb render_markdown(content)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../public/tests", __FILE__)
  else
    File.expand_path("../public/project_files", __FILE__)
  end
end

def valid_file_name?(name)
  if (name =~ /[^A-Za-z0-9\-_.]+/) == nil
    session[:success] = "#{name} was created."
    true
  else
    session[:error] = "A name is required (no special characters)."
    false
  end
end

def validate_credentials(username, password)
  users = load_users

  if users.key?(username)
    secure_password = BCrypt::Password.new(users[username])
    secure_password == password
  else
    false
  end
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  # finds all files in the provided directory and shortens the name to their
  # base name
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |file|
    File.basename(file)
  end
end

# renders the index page
get "/" do
  erb :index, layout: :layout
end

# render page for create a new document
get "/new" do
  if session[:username]
    erb :new, layout: :layout
  else
    session[:error] = "You must be signed in to do that."
    redirect "/"
  end
end

# creates new document
post "/new" do
  file_name = params[:new_doc]
  if valid_file_name?(file_name)
    File.write(File.join(data_path, file_name), "")
    redirect "/"
  else
    erb :new, layout: :layout
  end
end

# renders sign in page
get "/users/sign_in" do
  erb :sign_in, layout: :layout
end

# signs the user in
post "/users/sign_in" do
  username = params[:username]
  password = params[:password]

  if validate_credentials(username, password)
    session[:signed_in] = "Signed in as #{username}."
    session[:username] = username
    redirect "/"
  else
    session[:invalid_credentials] = "Invalid credentials."
    erb :sign_in, layout: :layout
  end
end

# signs the user out
get "/users/sign_out" do
  session[:sign_out] = "You have been signed out."
  session[:signed_in] = nil
  redirect "/"
end

# renders the file content of the chosen file
get "/:file_name" do
  file_name = params[:file_name].to_s
  file_path = File.join(data_path, file_name)

  if !@files.include?(file_name)
    session[:error] = "#{file_name} does not exist."
    redirect "/"
  else
    load_content(file_path)
  end
end

# edit the file of choice
get "/:file_name/edit" do
  if session[:username]
    @file_name = params[:file_name].to_s
    file_path = File.join(data_path, @file_name)
    @file_content = File.read(file_path)
    erb :edit_file, layout: :layout
  else
    session[:error] = "You must be signed in to do that."
    redirect "/"
  end
end

# pushes the changes to the respective file
post "/:file_name" do
  file_name = params[:file_name].to_s
  file_path = File.join(data_path, file_name)
  content = params[:content]
  File.write(file_path, content)
  session[:success] = "#{params[:file_name]} has been updated."

  redirect "/"
end

post "/:file_name/delete" do
  if session[:username]
    file_name = params[:file_name].to_s
    file_path = File.join(data_path, file_name)
    File.delete(file_path)
    session[:success] = "#{file_name} was deleted."
    redirect "/"
  else
    session[:error] = "You must be signed in to do that."
    redirect "/"
  end
end
