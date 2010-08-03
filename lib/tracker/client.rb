require 'rubygems'
require 'rexml/document'
require 'rest_client'
require 'uri'
require 'time'
require 'json/pure'

# A Ruby class to call the Tracker REST API.  You might use this if you want to
# manage your Tracker apps from within a Ruby program, such as Capistrano.
# 
# Example:
# 
#   require 'tracker'
#   tracker = Tracker::Client.new('me@example.com', 'mypass')
#   tracker.create('myapp')
#
class Tracker::Client
  def self.version
    '0.0.0'
  end

  def self.gem_version_string
    "tracker-gem/#{version}"
  end
  
  attr_reader :host, :user, :password

  def initialize(user, password, host='web:1602')
    @user = user
    @password = password
    @host = host
  end

  # Show a list of projects which you are a collaborator on.
  def list
    get 'projects'
  end

  # Create a new project, with an optional name.
  def create_project(name)
    post('projects', {:name => name})["project"]
  end

  def todo_lists(project_id)
    get "projects/#{project_id}/todo_lists"
  end

  def todos(project_id)
    get "projects/#{project_id}/todos"
  end

  def todos_complete(project_id)
    get "projects/#{project_id}/todos/complete"
  end

  def create_todo(project_id, todo)
    post("projects/#{project_id}/todos", :todo => todo)
  end

  def show_todo(project_id, ticket_id)
    get("projects/#{project_id}/todos/#{ticket_id}")
  end

  def notes(project_id)
    get "projects/#{project_id}/notes"
  end

  # Update an app.  Available attributes:
  #   :name => rename the app (changes http and git urls)
  def update(name, attributes)
    put("/apps/#{name}", :app => attributes).to_s
  end

  # Destroy the app permanently.
  def destroy(name)
    delete("/apps/#{name}").to_s
  end

  # Get a list of collaborators on the app, returns an array of hashes each with :email
  def list_collaborators(app_name)
    doc = xml(get("/apps/#{app_name}/collaborators").to_s)
    doc.elements.to_a("//collaborators/collaborator").map do |a|
      { :email => a.elements['email'].text }
    end
  end

  class AppCrashed < RuntimeError; end

  # support for console sessions
  class ConsoleSession
    def initialize(id, app, client)
      @id = id; @app = app; @client = client
    end
    def run(cmd)
      @client.run_console_command("/apps/#{@app}/consoles/#{@id}/command", cmd, "=> ")
    end
  end

  # Execute a one-off console command, or start a new console tty session if
  # cmd is nil.
  def console(app_name, cmd=nil)
    if block_given?
      id = post("/apps/#{app_name}/consoles").to_s
      yield ConsoleSession.new(id, app_name, self)
      delete("/apps/#{app_name}/consoles/#{id}").to_s
    else
      run_console_command("/apps/#{app_name}/console", cmd)
    end
  rescue RestClient::RequestFailed => e
    raise(AppCrashed, e.response.to_s) if e.response.code.to_i == 502
    raise e
  end

  # internal method to run console commands formatting the output
  def run_console_command(url, command, prefix=nil)
    output = post(url, command).to_s
    return output unless prefix
    if output.include?("\n")
      lines  = output.split("\n")
      (lines[0..-2] << "#{prefix}#{lines.last}").join("\n")
    else
      prefix + output
    end
  rescue RestClient::RequestFailed => e
    raise e unless e.http_code == 422
    e.http_body
  end

  def on_warning(&blk)
    @warning_callback = blk
  end

  ##################

  def resource(uri)
      RestClient::Resource.new("http://#{host}/api/", user, password)[uri]
  end

  def get(uri, extra_headers={})    # :nodoc:
    process(:get, uri, extra_headers)
  end

  def post(uri, payload="", extra_headers={})    # :nodoc:
    process(:post, uri, extra_headers, payload)
  end

  def put(uri, payload, extra_headers={})    # :nodoc:
    process(:put, uri, extra_headers, payload)
  end

  def delete(uri, extra_headers={})    # :nodoc:
    process(:delete, uri, extra_headers)
  end

  def process(method, uri, extra_headers={}, payload=nil)
    headers  = tracker_headers.merge(extra_headers)
    args     = [method, payload, headers].compact
    response = resource(uri).send(*args)

    extract_warning(response)
    JSON.parse(response)
  end

  def extract_warning(response)
    return unless response
    if response.headers[:x_tracker_warning] && @warning_callback
      warning = response.headers[:x_tracker_warning]
      @displayed_warnings ||= {}
      unless @displayed_warnings[warning]
        @warning_callback.call(warning)
        @displayed_warnings[warning] = true
      end
    end
  end

  def tracker_headers   # :nodoc:
    {
      'X-Tracker-API-Version' => '2',
      'User-Agent'           => self.class.gem_version_string,
      'X-Ruby-Version'       => RUBY_VERSION,
    }
  end

  def xml(raw)   # :nodoc:
    REXML::Document.new(raw)
  end

  def escape(value)  # :nodoc:
    escaped = URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    escaped.gsub('.', '%2E') # not covered by the previous URI.escape
  end
end
