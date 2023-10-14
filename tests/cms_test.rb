ENV["RACK_ENV"] = "test" # used by Sinatra and Rack to know if code is being tested

require "minitest/autorun"
require "minitest/reporters"
require "rack/test"
Minitest::Reporters::use!

require_relative "../cms_proj"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "about.txt")
    assert_includes(last_response.body, "history.txt")
  end

  def test_file_content
    history_content = File.read("./public/project_files/history.txt")
    about_content = File.read("./public/project_files/about.txt")
    changes_content = File.read("./public/project_files/changes.txt")
    
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
    filename = "notafile.txt"
    error_message = "#{filename} does not exist."
    get "/#{filename}"
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, error_message)

    get "/"
    assert_equal(200, last_response.status)
    refute_includes(last_response.body, error_message)
  end

  def test_markdown_content
    get "/brady.md"
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "<h1>Tom Brady...</h1>")
  end
end