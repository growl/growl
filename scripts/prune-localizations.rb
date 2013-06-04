#!/usr/bin/ruby

require 'find'
require 'fileutils'
require 'getoptlong'

opts = GetoptLong.new(
                      [ "--save", "-s", GetoptLong::REQUIRED_ARGUMENT ]
                      )
keepers = ["en"]
opts.each do |opt, arg|
    case opt
        when "--save"
        keepers = arg.split(',')
    end
end

path_to_process = ARGV[0]
Find.find(path_to_process) do |path|
    if File.extname(path) == '.lproj'
        unless keepers.include?(File.basename(path, '.lproj'))
            puts "Deleting #{path}"
            FileUtils.rm_r(path)
        end
        Find.prune
    end
end