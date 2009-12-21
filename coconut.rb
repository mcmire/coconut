#!/usr/bin/env ruby

ROOT_DIR = File.expand_path(File.dirname(__FILE__))

#$:.unshift(ROOT_DIR, "#{ROOT_DIR}/lib")

require "fileutils"
require "rubygems"

require "sinatra/base"

# Gems
gem 'haml'
  require 'haml'
gem 'rack-flash'
  require 'rack-flash'
gem 'sinatra_more'
  require 'sinatra_more/markup_plugin'
  require 'sinatra_more/render_plugin'
  require 'sinatra_more/routing_plugin'

# Vendored
require "./lib/trailing_slash"
require "./lib/sinatra_reloader"

#------

module Coconut
  config_file = "#{ROOT_DIR}/config.yml"
  if File.exists?(config_file)
    config = YAML.load_file(config_file)
    defaults = {
      "wiki_name" => "My Wiki",
      "available_markup_filters" => %w(kramdown creole maruku)
    }
    @@config = defaults.merge(config)
  else
    raise "You need to make a config file. Rename config.yml.example to config.yml and modify to suit your needs."
  end
  
  def self.config; @@config; end
end

Coconut.config["available_markup_filters"].each do |filter|
  case filter
  when "kramdown"
    gem "kramdown", '>= 0.3.0'
    require "kramdown"
    
    # Add UNAME_STR to rexml
    class REXML::Parsers::BaseParser
      UNAME_STR= "(?:#{NCNAME_STR}:)?#{NCNAME_STR}"
    end
  when "maruku"
    gem "maruku"
    require "maruku"
  when "creole"
    gem 'gmccreight-WikiCreole'
    require 'wiki_creole'
  end
end

#------

module Coconut
  class App < Sinatra::Base
    # For some reason we have to set these explicitly
    set :root, ROOT_DIR
    set :app_file, __FILE__
    
    # These settings are set by Default
    #set :raise_errors, Proc.new { test? }
    set :show_exceptions, Proc.new { development? }
    set :dump_errors, true
    set :logging, Proc.new { ! test? }
    set :methodoverride, true
    set :static, true
    
    #---
    
    register SinatraMore::MarkupPlugin
    register SinatraMore::RenderPlugin
    register SinatraMore::RoutingPlugin

    configure :development do
      use Sinatra::Reloader
    end
    
    enable :sessions
    use Rack::Flash, :sweep => true
    
    if Coconut.config["username"] && Coconut.config["password"]
      use Rack::Auth::Basic do |username, password|
        [username, password] == [Coconut.config["username"], Coconut.config["password"]]
      end
    end
    
    use Rack::TrailingSlash
    
    #---
    
    PAGES_DIR = "#{ROOT_DIR}/data/pages"
    TRASH_DIR = "#{ROOT_DIR}/data/trash"

    helpers do
      def markup(filter, content)
        case filter
        when "creole"
          #Creole.creolize(content)
          content = content.gsub(/\r\n/, "\n")  # so WikiCreole will parse hr's correctly
          content = WikiCreole.creole_parse(content)
          content = content.gsub(/<pre>\s*/, "<pre>")  # fix this, blah blah
        when "maruku"
          content = Maruku.new(content).to_html
        when "kramdown"
          content = Kramdown::Document.new(content).to_html
        end
        content
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
        content = render_page(@page["markup_filter"], @page["content"])
        haml :page, :layout => :wiki, :locals => {:content => content}
      end
  
      def render_page(filter, content)
        markup(filter, content)
      end
  
      def normalize_page_name(page_name)
        page_name.gsub(" ", "_")
      end
      alias_method :page_title_to_name, :normalize_page_name
  
      def page_name_to_title(page_name)
        page_name.gsub("_", " ")
      end
  
      def save_page(page_name, content, meta = {})
        content = content.strip
        content = content.gsub(/\r\n/, "\n")  # so WikiCreole will parse hr's correctly
        page = find_page(page_name)
        page_dir = "#{PAGES_DIR}/#{page["name"]}"
        FileUtils.mkdir_p(page_dir)
        if page["exists"]
          current_version = File.basename(File.readlink("#{page_dir}/current"))
          next_version = current_version.to_i + 1
        else
          redirect "/#{page_name}" and return if content.empty?
          next_version = 1
        end
        if page["content"] != content
          File.open("#{page_dir}/#{next_version}", "w") {|f| f << content }
          FileUtils.ln_sf("#{next_version}", "#{page_dir}/current")
        end
        File.open("#{page_dir}/meta.yml", "w") {|f| YAML.dump(meta, f) }
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
  
      # SimplyButtons helpers
      # http://www.p51labs.com/simply-buttons-v2/
      def button_tag(name, value, html_options = {})
        content_tag :button, {:name => name, :type => "submit"}.merge(html_options) do
          content_tag :span do
            content_tag :span, value
          end
        end
      end
      def button_link_to(*args, &block)
        html_options_given = block_given? ? (args.size == 2) : (args.size == 3)
        args << {} unless html_options_given
        html_options = args[-1]
        if html_options[:class]
          html_options[:class] << " button"
        else
          html_options[:class] = "button"
        end
        content = args.shift unless block_given?
        link_to(*args) do
          content_tag :span do
            (block_given? ? content_tag(:span, &block) : content_tag(:span, content))
          end
        end
      end
      
      def page_title
        title = Coconut.config["wiki_name"]
        title += @title unless title == @title
        title
      end
      
      def hide_main?; @hide_main; end
      def hide_main!; @hide_main = true; end
  
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
          page.merge!(YAML.load_file(metafile)) if File.exists?(metafile)
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

    get "/" do
      @pages = find_pages
      @title = Coconut.config["wiki_name"]
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
      save_page(params[:page_name], params[:content], params[:meta])
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
      save_page(params[:page_name], params[:content], params[:meta])
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
      render_page params[:markup_filter], params[:content]
    end
  end
end