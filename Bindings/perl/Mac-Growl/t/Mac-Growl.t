# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mac-Growl.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Mac::Growl') };

#########################

Mac::Growl::RegisterNotifications("PerlApp",["Perl Notification"],["Perl Notification"]);
Mac::Growl::PostNotification("PerlApp","Perl Notification","Congratulations","Mac::Growl is working.");
Mac::Growl::PostNotification("PerlApp","Perl Notification","If things are working...", "This should 'stick'",1);