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
		
		codesign_command = IO.popen("codesign -dvvv \"#{path}\" 2>&1")
		candidate_lines = codesign_command.readlines
		lines = candidate_lines.select {|v| v =~ /Authority=/}
		signature = lines[0]
		if !signature or !signature.include? "#{signer}"
			actualsigner = signature.split("=")[1] if signature
			puts "Invalid signature on #{path}\n \texpected: #{signer}\n \tfound: #{actualsigner}"
			problem = true		
        end
        
	end
end

if problem
	exit(1)
end
