default:
	xcodebuild -project Growl.xcode -target Growl -buildstyle Deployment build

growl:
	xcodebuild -project Growl.xcode -target Growl -buildstyle Development build

growlhelperapp:
	xcodebuild -project Growl.xcode -target GrowlHelperApp -buildstyle Development build

display: bubblesnotificationview

bubblesnotificationview:
	xcodebuild -project Growl.xcode -target BubblesNotificationView -buildstyle Development build

clean:
	xcodebuild -project Growl.xcode -alltargets clean
