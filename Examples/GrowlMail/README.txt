GrowlMail is a Apple Mail plugin. This is an example for implementing Growl support in bundles.


Requirements:
Growl installed
GrowlAppBridge installed

Building GrowlMail

1) Open GrowlMail.xcode
2) Select the deployment build style.
3) Build.

 The finished product will be called GrowlMail.mailbundle and will be in your build directory.

Install:

1) Quite Apple Mail
2) Move the GrowlMail.mailbundle package into ~/Library/Mail/Bundles/
3) Run these two commands in a terminal

	defaults write com.apple.mail EnableBundles -bool True
	defaults write com.apple.mail BundleCompatibilityVersion 1
