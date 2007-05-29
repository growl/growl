tell application "Finder"
	tell disk "Growl"
		open
		tell container window
			set current view to icon view
			set toolbar visible to false
			set statusbar visible to false
			set the bounds to {30, 50, 480, 350}
		end tell
		close
		set opts to the icon view options of container window
		tell opts
			set icon size to 56
			set arrangement to not arranged
		end tell
		set background picture of opts to file ".background:growlDMGBackground.png"
		set position of item "Growl.prefPane" to {45, 41}
		set position of item "Extras" to {162, 33}
		--set position of item "Scripts" to {36, 153}
		set position of item "Growl Documentation.webloc" to {128, 123}
		set position of item "Growl version history.webloc" to {265, 41}
		set position of item "Get more styles.webloc" to {383, 41}
		set position of item "Uninstall Growl.app" to {383, 123}
		update without registering applications
		tell container window
			set the bounds to {31, 50, 579, 4000}
			set the bounds to {30, 50, 579, 4000}
		end tell
		update without registering applications
	end tell
	--give the finder some time to write the .DS_Store file
	delay 5
end tell
