-- main.applescript
-- GrowlAction

-- IMPORTANT: Remember to save the compiled script to main.scpt before committing!

on run {input_items, parameters}
	set the output_items to input_items
	set the notification_title to (|notificationTitle| of parameters) as string
	set the notification_description to ""
	set testParams to parameters & {|notificationDescription|:"ZOMG SUPER SEKRIT TESTING STRING"}
	if (|notificationDescription| of testParams is not "ZOMG SUPER SEKRIT TESTING STRING") then
		set the notification_description to (|notificationDescription| of parameters) as string
	end if
	if the notification_description is ""
		set notification_description to (input_items) as string
	end if
	set the notification_priority to (priority of parameters) as integer
	set the notification_sticky to (sticky of parameters) as boolean
	tell application "GrowlHelperApp"
		register as application "Automator" all notifications {"Automator notification"} default notifications {"Automator notification"} icon of application "Automator"
		notify with name "Automator notification" title notification_title description notification_description application name "Automator" sticky notification_sticky priority notification_priority
	end tell
	return input_items
end run
