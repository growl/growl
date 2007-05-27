tell application "Finder"
	tell disk "Growl-SDK"
		open
		tell container window
			set current view to icon view
			set toolbar visible to false
			set statusbar visible to false
			set the bounds to {30, 50, 490, 360}
		end tell
		close
		set opts to icon view options of container window
		tell opts
			set icon size to 60
			set arrangement to not arranged
		end tell
		set background picture of opts to file ".background:growlSDK.png"
		set position of item "Bindings" to {263, 76}
		set position of item "Frameworks" to {370, 76}
		set position of item "Growl Developer Documentation.webloc" to {263, 196}
		set position of item "Growl version history for developers.webloc" to {370, 183}
		update without registering applications
		tell container window
			set the bounds to {31, 50, 490, 360}
			set the bounds to {30, 50, 490, 360}
		end tell
		update without registering applications
	end tell
	--give the finder some time to write the .DS_Store file
	delay 5
end tell
