require 'rubygems'
require 'sinatra'
require 'json'
require 'pp'

set :bind, '0.0.0.0'

post '/push' do
  push_info = JSON.parse request.body.read
  repo = push_info["repository"]["url"].split(":")[-1]
  command = "cd #{File.dirname(__FILE__)}/#{repo} && /opt/gitlab/embedded/bin/git push --mirror --repo=git@git.lab.esbu.lab.com.au:#{repo}"
  `#{command}`
end
