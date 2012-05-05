#!/usr/bin/ruby

require 'find'
require 'fileutils'

app = ARGV.shift

Find.find(app) do |path|
  if File.fnmatch('**/PrivateHeaders', path) || 
      File.fnmatch('**/Headers', path) ||
      if File.fnmatch('**/Documentation', path) 
	puts "Deleting #{path}"
	FileUtils.rm_r(path)
    Find.prune
  end
end