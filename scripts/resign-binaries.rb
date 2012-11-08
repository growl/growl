#!/usr/bin/ruby
require 'find'
require 'fileutils'
require 'getoptlong'

def sign(path,signer)
	problem = false
	command = ['codesign', '--preserve-metadata=identifier,entitlements,resource-rules,requirements', '-f', '-s', "\""+signer+"\"", "\""+path+"\""]
	system command.join(' ')
	status = $?
	if status.exitstatus != 0
		puts "Failed to run: #{command}"
		problem = true
	end
	return problem
end

def resign(path, signer)
	problem = false
	if not File.exists? path
		puts "No such file #{path}"
		problem = true
		break
	end
    
	Find.find(path) do |subpath|
		fileCheck = %x{/usr/bin/file -h "#{subpath}"}
		if fileCheck.include? "Mach-O"
			#we found a binary now lets call codesign on it and see if it has the right signer
			problem = sign(subpath, signer)
		elsif path[-10..-1] == '.framework'
    		versions = Dir.glob(path+"/Versions/*")
    		for version in versions
      			if File.basename(version) != 'Current'       
      		          problem = resign(version, signer)
        		end
 			end
		end
	end
	return problem
end

def main
    signer = "3rd Party Mac Developer Application: The Growl Project, LLC"
	path = ARGV[0]
	opts = GetoptLong.new(
                          [ "--signing-identity", "-i", GetoptLong::REQUIRED_ARGUMENT ]
                          )
	opts.each do |opt, arg|
        case opt
            when "--signing-identity"
			signer = arg
		end
	end
    resign(path, signer)
end

if __FILE__ == $0
	main()
end