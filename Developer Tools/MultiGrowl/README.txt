This example demonstrates how to include multiple Growl frameworks in 
your application and dynamically load them based on the currently running 
operating system. I have confirmed that it works on 10.5, 10.6 and 
10.7 (i don't have a 10.4 vm setup). it loads the 1.2.3 framework on 
OSes older than 10.6, and loads the 1.3 framework on OSes 10.6 and 
newer.  Under this setup you don't actually link against any of the 
frameworks, but instead dynamically reference the 
GrowlApplicationBridge class and check that any method you call is 
implemented by the class before calling it. 
