GrowlView.xctemplate readme

GrowlView.xctemplate is an XCode template for making a .growlView (cocoa) plugin for Growl.  These can be either displays such as smoke, or actions such as speech.  The xctemplate directory needs to be placed inside the following directory:

~/Library/Developer/XCode/Templates/Growl

(you will likely need to create at least the Growl directory, if not the Templates directory).

From there, simply create a new project, selecting either action, or display, and all the base files needed for the selected type will be created.

For any growlView that includes:
Info.plist, including the author and description fields, and prepopulated primary class depending on type of growlView
Growl<ProjectName>PreferencePane.h/m, the subclass of GrowlPluginPreferencePane that links your UI to our storage method for plugin configurations.
Growl<ProjectName>PrefPane.xib
GrowlPlugins.framework, a copy of the framework we use for storing the primary classes your plugin will want/need from us.  You do not need to bundle this with your app, we bundle it with Growl.app.

For an action growlView, that includes:
Growl<ProjectName>Action.h/m the primary plugin class, subclassed from GrowlActionPlugin, which will be what is called to dispatch a notification.

For a display view, that includes:
many classes which have not been refined for 2.0, much less implemented in the template