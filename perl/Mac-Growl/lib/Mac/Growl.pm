package Mac::Growl;

use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mac::Growl ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
RegisterNotification PostNotifications
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.20';

require XSLoader;
XSLoader::load('Mac::Growl', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Mac::Growl - Perl extension for registering and sending Growl Notifications on OS X

=head1 SYNOPSIS

  use Mac::Growl qw{RegisterNotifications, PostNotification};

  RegisterNotifications("MyPerlApp", \@allNotifications, \@defaultNotifications);
  PostNotification("MyPerlApp", $notificationName, $notificationTitle, $notificationDescription);

=head1 DESCRIPTION

Mac::Growl provides a simple notification for perl apps to register themselves with and send notifications to the OS X notification application Growl.
	
Mac::Growl defines two methods:
	
=over 4

=item RegisterNotifications(appname, allNotifications, defaultNotifications);

RegisterNotifications takes the name of the application sending notifications, as well as a reference to a list of all notifications the app sends out, and a reference to an array of all the notifications to be enabled by default.

=item PostNotification(appname, name, title, description);

PostNotification takes the name of the sending application (normally the same as passed to the Register call), the name of the notification (should be one of the list passed to Register, and a title and description to be displayed by Growl

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

http://sourceforge.net/projects/growl

#growl on irc.freenode.net

=head1 AUTHOR

Nelson Elhage, E<lt>nelhage@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Nelson Elhage

This Library is released under the BSD license. I hate legalese, so
someone who hates it slightly less will have to fix this section.

=cut
