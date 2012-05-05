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
    destPath = "../Plugins/System/GrowlAction/"
    FileUtils.cp_r(srcPath, destPath)
    
    srcPath = path+"/Contents/PlugIns/MailMe.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/MailMe/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Speech.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Speech/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/SMS.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/SMS/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/iCal.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/iCal/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Brushed.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Brushed/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/MusicVideo.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/MusicVideo/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Nano.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Nano/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Smoke.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Smoke/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Bubbles.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Bubbles/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/PlugIns/Bezel.growlView/Contents/Resources/"+language
    destPath = "../Plugins/Displays/Bezel/"
    FileUtils.cp_r(srcPath, destPath)

    srcPath = path+"/Contents/Resources/"+language
    destPath = "../Core/Resources/"
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