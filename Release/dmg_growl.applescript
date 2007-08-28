on run -- for testing in script editor
	process_disk_image("Growl", "/Users/evands/growl/Release/Artwork")
end run

on process_disk_image(volumeName, artPath)
	tell application "Finder"
		tell disk volumeName
			open
			tell container window
				set current view to icon view
				set toolbar visible to false
				set statusbar visible to false
				--set the bounds to {30, 50, 579, 600}
			end tell
			close
			set opts to the icon view options of container window
			tell opts
				set icon size to 64
				set arrangement to not arranged
			end tell
			set background picture of opts to file ".background:growlDMGBackground.png"
			set position of item "Growl.mpkg" to {147, 75}
			set position of item "Extras" to {100, 320}
			--set position of item "Scripts" to {36, 153}
			set position of item "Growl Documentation.webloc" to {100, 218}
			set position of item "Growl version history.webloc" to {275, 218}
			set position of item "Get more styles.webloc" to {415, 218}
			set position of item "Uninstall Growl.app" to {415, 320}
			
			-- Custom icons
			my copyIconOfTo(artPath & "/GrowlIcon", "/Volumes/" & volumeName & "/Growl.mpkg")
			
			update without registering applications
			tell container window
				open
				set the_window_id to id
			end tell
			update without registering applications
		end tell
		set bounds of window id the_window_id to {30, 50, 575, 450}
		--give the finder some time to write the .DS_Store file
		delay 5
	end tell
end process_disk_image

on copyIconOfTo(aFileOrFolderWithIcon, aFileOrFolder)
	tell application "Finder" to set f to POSIX file aFileOrFolderWithIcon as alias
	-- grab the file's icon
	my CopyOrPaste(f, "c")
	-- now the icon is in the clipboard
	tell application "Finder" to set c to POSIX file aFileOrFolder as alias
	my CopyOrPaste(result, "v")
end copyIconOfTo

on CopyOrPaste(i, cv)
	tell application "Finder"
		activate
		open information window of i
	end tell
	tell application "System Events" to tell process "Finder" to tell window 1
		keystroke tab -- select icon button
		keystroke (cv & "w") using command down (* (copy or paste) + close window *)
	end tell -- window 1 then process Finder then System Events
end CopyOrPaste