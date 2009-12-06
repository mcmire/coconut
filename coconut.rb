#!/usr/bin/env ruby

PROJ_DIR = File.dirname(__FILE__)

$:.unshift(PROJ_DIR)

require "fileutils"
require "rubygems"

require "sinatra"

gem 'rack-flash'
require 'rack-flash'

require "haml"

#require "creole"
require "wiki_creole"

require "trailing_slash"
use Rack::TrailingSlash

PAGES_DIR = File.expand_path("#{PROJ_DIR}/data/pages")
TRASH_DIR = File.expand_path("#{PROJ_DIR}/data/trash")

helpers do
  def markup(content)
    #Creole.creolize(content)
    content = content.gsub(/\r\n/, "\n")  # so WikiCreole will parse hr's correctly
    content = WikiCreole.creole_parse(content)
    content = content.gsub(/<pre>\s*/, "<pre>")  # fix this, blah blah
  end
  
  def find_pages(read_content=false)
    pages = []
    Dir["#{PAGES_DIR}/*"].each do |page_dir|
      page_name = File.basename(page_dir)
      page = _read_page(page_name, page_dir, read_content)
      pages << page
    end
    pages
  end
  
  def find_page(page_name, read_content=true)
    page_name = normalize_page_name(page_name)
    page = nil
    #if page_name =~ %r|^Special/(.*)$|
    #  page = SPECIAL_PAGES[$1]
    #else
      page_dir = "#{PAGES_DIR}/#{page_name}"
      page = _read_page(page_name, page_dir, read_content)
    #end
    page
  end
  
  def do_page(page_name)
    @page = find_page(page_name)
    @title = @page["title"]
    content = render_page(@page["content"])
    haml :page, :layout => :wiki, :locals => {:content => content}
  end
  
  def render_page(content)
    markup(content)
  end
  
  def normalize_page_name(page_name)
    page_name.gsub(" ", "_")
  end
  alias_method :page_title_to_name, :normalize_page_name
  
  def page_name_to_title(page_name)
    page_name.gsub("_", " ")
  end
  
  def save_page(page_name, content)
    content = content.strip
    content = content.gsub(/\r\n/, "\n")  # so WikiCreole will parse hr's correctly
    page = find_page(page_name)
    page_dir = "#{PAGES_DIR}/#{page["name"]}"
    FileUtils.mkdir_p(page_dir)
    if page["exists"]
      current_version = File.basename(File.readlink("#{page_dir}/current"))
      next_version = current_version.to_i + 1
    else
      redirect "/#{page_name}" if content.empty?
      next_version = 1
    end
    if page["content"] != content
      File.open("#{page_dir}/#{next_version}", "w") {|f| f << content }
      FileUtils.ln_sf("#{next_version}", "#{page_dir}/current")
    end
    if params[:save_exit]
      redirect "/#{page["name"]}"
    elsif params[:save_return]
      redirect "/pages/#{page["name"]}/edit"
    end
  end
  
  # Simple content_for implementation.
  #
  # Set content like so:
  #
  #   - content_for :head do
  #      ...
  #
  # Get content like so:
  #
  #   = content_for :head
  #
  def content_for(sym, &block)
    if block_given?
      instance_variable_set("@content_for_#{sym}", capture_haml(&block))
    else
      instance_variable_get("@content_for_#{sym}")
    end
  end
  
private
  def _read_page(page_name, page_dir, read_content=false)
    metafile = "#{page_dir}/meta.yml"
    pagefile = "#{page_dir}/current"
    page = {
      "name" => page_name,
      "title" => page_name_to_title(page_name),
      "url" => "/" + page_name,
      "dir" => page_dir
    }
    if File.exists?(pagefile)      
      #page = YAML.load_file(metafile)
      if read_content
        page["content"] = File.read(pagefile)
        # this should never really happen but it's just in case
        if page["content"].empty?
          page["content"] = "Well, Jimbo, I reckon this page ain't got no content. You might try the feller next door." 
        end
      end
      page["exists"] = true
    else
      page["content"] = %|Hot dog! You done found a page that don't exist. Tell you what. Why don't you <a href="/pages/new?page_name=#{page_name}">fill 'er in</a>?|
      page["exists"] = false
    end
    page
  end
end

# Reload scripts and reset routes on change
# See <http://groups.google.com/group/sinatrarb/browse_thread/thread/a5cfc2b77a013a86>
class Sinatra::Reloader < Rack::Reloader
  def safe_load(file, mtime, stderr = $stderr)
    if file == Sinatra::Application.app_file
      ::Sinatra::Application.reset!
      stderr.puts "#{self.class}: resetting routes"
    end
    super
  end
end

config_file = File.expand_path(File.dirname(__FILE__) + '/config.yml')
if File.exists?(config_file)
  CoconutConfig = YAML.load_file(config_file)
else
  raise "You need to make a config file. Rename config.yml.example to config.yml and modify to suit your needs."
end

configure :development do
  use Sinatra::Reloader
end

enable :sessions
use Rack::Flash, :sweep => true

use Rack::Auth::Basic do |username, password|
  [username, password] == [CoconutConfig["username"], CoconutConfig["password"]]
end

get "/" do
  @pages = find_pages
  @title = "Index"
  haml :index, :layout => :wiki
end

get "/pages/new" do
  @page = find_page(params[:page_name])
  if @page["exists"]
    redirect "/pages/#{@page["name"]}/edit"
  else
    @title = "Adding page '#{@page["title"]}'"
    haml :page_form, :layout => :wiki
  end
end
post "/pages" do
  save_page(params[:page_name], params[:content])
end

get "/:page_name" do |page_name|
  do_page(page_name)
end

get "/pages/:page_name" do |page_name|
  redirect "/#{page_name}"
end

get "/pages/:page_name/edit" do
  @page = find_page(params[:page_name])
  if @page["exists"]
    @title = "Editing page '#{@page["title"]}'"
    haml :page_form, :layout => :wiki
  else
    redirect "/pages/new?page_name=#{@page["name"]}"
  end
end
put "/pages/:page_name" do
  save_page(params[:page_name], params[:content])
end

get "/pages/:page_name/delete" do
  @page = find_page(params[:page_name])
  if @page["exists"]
    @title = "Deleting page '#{@page["title"]}'"
    haml :delete_page, :layout => :wiki
  else
    redirect "/#{@page["name"]}"
  end
end
delete "/pages/:page_name" do
  page = find_page(params[:page_name], false)
  if page["exists"] && params[:commit]
    FileUtils.mkdir_p(TRASH_DIR)
    FileUtils.mv(page["dir"], TRASH_DIR)
  end
  redirect "/#{page["name"]}"
end

get "/pages/:page_name/rename" do
  @page = find_page(params[:page_name], false)
  if @page["exists"]
    @title = "Rename page '#{@page["title"]}'"
    haml :rename_page, :layout => :wiki
  else
    redirect "/#{@page["name"]}"
  end
end
put "/pages/:page_name/rename" do
  @page = find_page(params[:page_name], false)
  if @page["exists"]
    old_name = @page["name"]
    new_name = normalize_page_name(params[:new_name])
    old_dir = @page["dir"]
    new_dir = File.dirname(@page["dir"]) + "/" + new_name
    if File.exists?(new_dir)
      flash[:error] = "That page already exists, budday-boy!!"
      # TODO: Maybe extract the above into a method, call that instead
      @title = "Rename page '#{@page["title"]}'"
      haml :rename_page, :layout => :wiki
    else
      FileUtils.mv(old_dir, new_dir)
      redirect "/#{new_name}"
    end
  else
    redirect "/#{@page["name"]}"
  end
end

post "/pages/preview" do
  #sleep 4
  render_page params[:content]
end