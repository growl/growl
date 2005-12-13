README for Gmail+Growl, source release.
(For developer instructions, scroll down.)

Gmail+Growl is distributed under the (revised) BSD license. Here is the license and applicable legal statements (copyright or other) in their entirety:

--
 BSD License
 
 Copyright (c) 2005, Jesper <wootest@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 * Neither the name of Gmail+Growl or Jesper, nor the names of Gmail+Growl's contributors 
 may be used to endorse or promote products derived from this software without
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The name Gmail is owned by Google, Inc. Growl is owned by the Growl Development Team.
 Likewise, the logos of those services are owned and copyrighted to their owners.
 No ownership of any of these is assumed or implied, and no infringement is intended.
--

DEVELOPER INSTRUCTIONS
======================

Gmail+Growl is a Mac OS X application, built to be compatible with Mac OS X 10.3.9 and all versions of 10.4. It's not yet a "universal binary", meaning that its 10.4 builds contain both PowerPC- and Intel-native binaries - this is because it's not yet technically possible since an underlying framework (Growl) is not yet "universal" itself.

Gmail+Growl builds heavily on the Gmail Notifier and the notification framework Growl. This means that not only doesn't Gmail+Growl check your Gmail inbox itself (it just tells Gmail Notifier to do so), it's not displaying the notifications itself either (it just tells Growl to do so).

What this also means is that it's unabashedly Mac OS X-based. If you're thinking of porting this to Linux derivates (or other *nix-family OSes) or why not Windows, thanks for taking an interest, but I'm afraid you'd be better off writing brand new code for your OS of choice - and you'll also need to find new ways to display notifications and actually check the Gmail inbox.

Gmail+Growl is an Xcode 2.1 ".xcodeproj" project. This means that you will need to have OS X 10.4 ("Tiger") or more installed. If you're using a lower version of OS X, I'm sorry.

For more info on this product or on the technologies on which it builds: 
* Growl: <http://growl.info/>
* Gmail: <http://gmail.com>
* Gmail Notifier: <http://toolbar.google.com/gmail-helper/index.html>
* Gmail+Growl: <http://wootest.net/gmailgrowl/>

Any questions? Send an email to <wootest+gmailgrowl@gmail.com>.