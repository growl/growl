#!/usr/bin/ruby
require 'find'
require 'fileutils'
require 'getoptlong'


def validate(path,signer)
    problem = false
    files = Array.new
    puts signer+"\n\n"
    Find.find(path) do |subpath|
        if not File.exists? subpath
            puts "No such file #{subpath}"
            problem = true
            break
        end
        fileCheck = %x{/usr/bin/file -h "#{subpath}"}
        if fileCheck.include? "Mach-O"
            files.push(subpath)
        end
        
    end
    
    if files.size()
        names = Array.new
        files.each do |key|
            names.push(File.basename(key))
        end
        longest_key = names.max { |a, b| a.length <=> b.length }
        
        files.each do |key|
            codesign_command = IO.popen("codesign -dvvv \"#{key}\" 2>&1")
            candidate_lines = codesign_command.readlines
            lines = candidate_lines.select {|v| v =~ /Authority=/}
            signature = lines[0]
            signature = signature.gsub("Authority=", "")
            signature = signature.strip
            printf "%-#{longest_key.length}s: %s\n", File.basename(key), signature
            if !signature or !signature.include? "#{signer}"
                problem = true
            end
        end
    end
    
    if not problem
        puts "\nBinary valid"
    else
        puts "\nBinary invalid"
    end
    return problem
end

def main
    path = ARGV[0]
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
    problem = validate(path, signer)
    if problem
        exit(1)
    end
end



if __FILE__ == $0
    main()
end