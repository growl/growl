#!/usr/bin/env tclsh
package require growl

growl register ExampleTclApp "warning error" pwrdLogo75.gif
growl post warning "TclGrowl launched" "Hi there!"
after 10000
growl post error "TclGrowl quitting" "Bye!" ../../images/icons/growl-icon-(png).png
