#!/usr/bin/ruby
require 'json'

j = JSON.parse(ARGF.read.gsub('\\\\', '\\'))

# get the uri to know the output filename, then erase from JSON
uri = j[0]['uri']
j.map! {|x| x.delete('uri') ; x}

File.open("/tmp/#{uri}.json", 'w', 0666) {|f| f.puts j.to_json}
