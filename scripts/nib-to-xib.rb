#!/usr/bin/ruby

require 'find'
require 'fileutils'

def xibify(path)
    Find.find(path) do |subpath|
        if File.extname(subpath) == '.nib'
            newsubpath = File.dirname(subpath) + "/" + File.basename(subpath, '.nib') + '.xib'
            command = "ibtool --upgrade \"#{subpath}\" --write \"#{newsubpath}\""
            puts "#{subpath} to #{newsubpath}"
            
            system command
            system "hg add \"#{newsubpath}\""
            system "hg rm \"#{subpath}\""
            FileUtils.rm_r(subpath)
            
            Find.prune
        end
    end
end

def main
    path = ARGV[0]
    xibify(path)
end


if __FILE__ == $0
	main()
end