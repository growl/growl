package require growl

growl register ExampleTclApp "warning error"
growl post warning "TclGrowl launched" "Hi there!"
after 10000
growl post error "TclGrowl quitting" "Bye!"
