#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

#  TestAllVisualDisplays.rb
#  
#
#  Created by Daniel Siemer on 10/31/12.
#

def main
	baseURL = "growl://plugin/preview/"
	bundleIDs = [
		"com.Growl.WebKit.Dangerous",
		"com.Growl.Bezel",
		"com.Growl.Brushed",
		"com.Growl.Bubbles",
		"com.Growl.WebKit.Candybars",
		"com.Growl.WebKit.Crystal",
		"com.Growl.WebKit.Darkroom",
		"com.Growl.WebKit.GarageBand",
		"com.Growl.iCal",
		"com.Growl.MusicVideo",
		"com.Growl.Nano",
		"com.Growl.WebKit.NotifyOS9",
		"com.Growl.WebKit.NotifyOSX",
		"com.Growl.WebkKit.Plain",
		"com.Growl.WebKit.Pseudo-Coda",
		"com.Growl.WebKit.Raaarr",
		"com.Growl.Smoke",
		"com.Growl.WebKit.Starwl",
		"com.Growl.WebKit.Whiteboard"
	]

	bundleIDs.each do |value|
		#puts("testing #{value}")
		system("open", "#{baseURL}#{value}")
	end
end

if __FILE__ == $0
	main
end
