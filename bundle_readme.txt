If you are getting libv8 compile errors, do the following before running bundle install

bundle config --local build.libv8 --with-cxx=/usr/local/bin/g++-4.2
