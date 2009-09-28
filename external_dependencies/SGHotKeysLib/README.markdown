SGHotKeyLib - Hot Keys For Mac OS X Leopard And Beyond
=========================

* Maintained by [Justin Williams](http://carpeaqua.com)
* Originally by Quentin D. Carnicelli

What is SGHotKeyLib?
-------------------------

SGHotKeysLib is a fork of Quentin D. Carnicelli's excellent [PTHotKeysLib](http://rogueamoeba.com/sources/) library for registering shortcut keys on Mac OS X.

PTHotKeysLib has served us well for many years, but as I was upgrading my company's applications to run natively in 64 bit I was running into issues.  The original code itself used many deprecated methods, 32 bit integer types, etc.  As I fixed those issues, my OCD started to get the best of me and I started reformatting and rewriting portions of the code using modern Objective-C practices and paradigms.  

SGHotKeysLib does the following:

* Adopts Objective-C 2.0 syntax, properties and other language features (suck it dot syntax haters)
* Uses Leopard's Text Input Sources (no patching required)
* Runs natively in 64 bit
* Supports Garbage Collection
* Removes legacy code support (no more checking for 10.1, no more Project Builder)
* Cleans up the code formatting & variable declarations
* Puts the code on Github for hot forking action

What's in the box?
-------------------------

SGHotKeysLib includes:

* The SGHotKeysLib itself 
* A sample application that demonstrates how it works.  

The sample uses a custom-built version of the [ShortcutRecorder](http://code.google.com/p/shortcutrecorder/) framework to demonstrate setting a hot key.  

All The Other Stuff
-------------------------

SGHotKeysLib is a modernization of a piece of code many of us have been using for several years, and I'm sure it could be improved even more.  If you have ideas for how to do that, please fork away. 

Please report [bugs and request features](http://secondgear.lighthouseapp.com/projects/34579-sghotkeyslib/tickets/new) on the [Lighthouse SGHotKeysLib project site](http://secondgear.lighthouseapp.com/projects/34579-sghotkeyslib/tickets?q=all).

---------------------------------------

* **1.1** 

  * Added support for traditional retain/release memory management
  * Resolved some compiler warnings that didn't show up in [REDACTED]

* **1.0** Original release