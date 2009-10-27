# Coconut

Coconut is a little wiki app written in Sinatra. It aims to be easy to install (just unpack and go; no need to set up a database), easy to configure (global variables? really?? what century is this?!?), and easy to extend (no need to monkeypatch my code and potentially clash with other extensions).

While it's not quite complete, it's perfectly usable. Try it out:

    sudo gem install sinatra
    git clone git://github.com/mcmire/coconut.git
    cd coconut
    # copy config.yml.example to config.yml and modify to suit your needs
    ruby coconut.rb -p 3000 -e production
  
Then, just hit up http://localhost:3000. (Isn't Sinatra great?)