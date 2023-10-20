ENV["RACK_ENV"] = "test" # used by Sinatra and Rack to know if code is being tested

require "minitest/autorun"
require "minitest/reporters"
require "rack/test"
require "fileutils"
Minitest::Reporters::use!

require_relative "../cms_proj"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def test_index
    create_document("changes.txt")
    create_document("about.txt")
    create_document("history.txt")

    get "/"
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "about.txt")
    assert_includes(last_response.body, "history.txt")
  end

  def test_file_content
    create_document("changes.txt")
    create_document("about.txt")
    create_document("history.txt")

    changes = File.join(data_path, "changes.txt")
    history = File.join(data_path, "history.txt")
    about = File.join(data_path, "about.txt")
    
    history_content = File.read(history)
    about_content = File.read(about)
    changes_content = File.read(changes)
    
    get "/history.txt"
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, history_content)

    get "/about.txt"
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, about_content)

    get "/changes.txt"
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, changes_content)
  end

  def test_document_not_found
    get "notafile.txt"

    assert_equal(302, last_response.status)
    assert_equal("notafile.txt does not exist.", session[:error])
  end

  def test_markdown_content
    create_document("brady.md", "<h1>Tom Brady...</h1>")

    get "/brady.md"

    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "<h1>Tom Brady...</h1>")
  end

  def test_edit_document
    post "/changes.txt", content: "new content"

    assert_equal 302, last_response.status
    assert_equal "changes.txt has been updated.", session[:success]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_create_document
    get "/new"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<input")
    assert_includes(last_response.body, %q(<button class="create" type="submit"))

    post "/new", new_doc: "newfile.txt"

    assert_equal(302, last_response.status)
    assert_equal("newfile.txt was created.", session[:success])

    get "/"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "newfile.txt")
  end

  def test_delete_document
    create_document("new_doc.txt")
    file_name = "new_doc.txt"
    file_path = File.join(data_path, file_name)

    post "/#{file_name}/delete"
    
    assert_equal(302, last_response.status)
    assert_equal("new_doc.txt was deleted.", session[:success])
    get "/"

    assert_equal(200, last_response.status)
    assert_nil(session[:success])

    get "/"

    refute_includes(last_response.body, "new_doc.txt")
  end

  def test_signin_form
    get "/users/sign_in"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<input")
    assert_includes(last_response.body, %q(<button type="submit"))
  end

  def test_successful_sign_in
    post "/users/sign_in", username: "admin", password: "secret"
    
    assert_equal(302, last_response.status)
    assert_equal("Signed in as admin.", session[:signed_in])
    assert_equal("admin", session[:username])

    get last_response["Location"]

    assert_includes(last_response.body, "<a href=\"/users/sign_out\">Sign Out</a>")
  end

  def test_unsuccessful_sign_in
    post "/users/sign_in", username: "hocus", password: "pocus"
    assert_equal(200, last_response.status)
    assert_nil(session[:invalid_credentials])
    assert_includes(last_response.body, "Invalid credentials.")
  end
end