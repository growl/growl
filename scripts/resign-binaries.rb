#!/usr/bin/ruby
require 'find'
require 'fileutils'
require 'getoptlong'

# default signer
signer = "3rd Party Mac Developer Application: The Growl Project, LLC"
problem = false
opts = GetoptLong.new(
		[ "--signing-identity", "-i", GetoptLong::REQUIRED_ARGUMENT ]
	)
opts.each do |opt, arg|
	case opt
		when "--signing-identity"
			signer = arg
	end
end


Find.find(ARGV.shift) do |path|
	if not File.exists? path
		puts "No such file #{path}"
		problem = true
		break
	end
	fileCheck = %x{/usr/bin/file -h "#{path}"}
	if fileCheck.include? "Mach-O universal binary"  or 
        fileCheck.include? "Mach-O 64-bit bundle" or
        fileCheck.include? "Mach-O 64-bit dynamically linked shared library"
        
		#we found a binary now lets call codesign on it and see if it has the right signer
		command = "codesign -f -s \"#{signer}\" \"#{path}\" 2>&1"
        system command
	end
end

if problem
	exit(1)
end
