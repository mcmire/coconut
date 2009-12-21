# Reload scripts and reset routes on change
# See <http://groups.google.com/group/sinatrarb/browse_thread/thread/a5cfc2b77a013a86>
class Sinatra::Reloader < Rack::Reloader
  def safe_load(file, mtime, stderr = $stderr)
    if File.expand_path(file) == File.expand_path(Coconut::App.app_file)
      Coconut::App.reset!
      stderr.puts "#{self.class}: resetting routes"
    end
    super
  end
end

module Rack::Reloader::Stat
  def figure_path(file, paths)
    found = @cache[file]
    found = file if !found and Pathname.new(file).absolute?
    found, stat = safe_stat(found)
    return found, stat if found

    paths.each do |possible_path|
      path = ::File.join(possible_path, file)
      found, stat = safe_stat(path)
      return ::File.expand_path(found), stat if found
    end
    
    # PATCH: Prevent "no method 'mtime' for #<String>" error
    # in the event that no paths were found.
    # (For some reason this problem only occurs on Passenger.)
    return nil
  end
end