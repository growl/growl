package require growl

set curdir [file dirname [info script]]
growl register ExampleTclApp "warning error" ${curdir}/pwrdLogo75.gif
growl post warning "TclGrowl launched" "Hi there!"
after 10000
growl post error "TclGrowl quitting" "Bye!" ${curdir}/../../images/icons/growl-icon-(png).png
