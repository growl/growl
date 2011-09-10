#!/usr/bin/ruby

require 'find'
require 'fileutils'

require 'nib-to-xib.rb'

def lproj(path)
    found = nil
    Find.find(path) do |subpath|
        if File.extname(subpath) == '.lproj'
            found = File.basename(subpath)
            break
        end
    end
    return found
end

def import(path, language)
    srcPath = path+"/Contents/Library/Automator/Show Growl Notification.action/Contents/Resources/"+language
    destPath = "../Plugins/System/GrowlAction/"+language
    FileUtils.cp_r(srcPath, destPath)
    
    srcPath = path+"/Contents/PlugIns/MailMe.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/MailMe/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Speech.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Speech/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/SMS.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/SMS/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/iCal.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/iCal/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Brushed.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Brushed/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/MusicVideo.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/MusicVideo/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Nano.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Nano/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Smoke.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Smoke/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Bubbles.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Bubbles/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Bezel.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Bezel/"+language
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/Resources/"+language
    destPath = "../Core/Resources/"+language
    FileUtils.cp_r(srcPath, destPath)
    
end

def main

    path = ARGV[0]
    xibify(path)
    language = lproj(path)
    puts language
    import(path, language)
end

if __FILE__ == $0
	main()
end