# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mac-Growl.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Mac::Growl') };

#########################

Mac::Growl::RegisterNotifications("PerlApp",["PerlApp-Test"],["PerlApp-Test"]);
sleep(1);	#A brief delay for Growl to process the notification
Mac::Growl::PostNotification("PerlApp","PerlApp-Test","Congratulations","Mac::Growl is working.");