use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Spec::Functions;
use Getopt::Long;

my $opt = {};
GetOptions($opt, 'growlhelperapp=s');

my $REQUIRED = '0.6.0';

my($GHA) = grep { -e } (
	$opt->{growlhelperapp} || '',
	'/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app'
);

my $goodversion = checkversion();
warn "... but we will attempt to install anyway.\n" unless $goodversion;

WriteMakefile(
	NAME		=> 'Mac::Growl',
	VERSION_FROM	=> 'lib/Mac/Growl.pm',
	clean		=> {
		'FILES'		=> 'Mac-Growl-* .makeglue'
	},
	NO_META		=> 1,
);

sub checkversion {
	my $info = catfile($GHA, updir(), updir(), qw(Info.plist));

	my $fh;
	unless (open($fh, '<', $info)) {
		warn "warning: Growl cannot be found!\n";
		return;
	}

	my $version;
	while (<$fh>) {
		if ($version) {
			m|^\s*<string>([\d.]+)</string>\s*$|;
			$version = $1;
			last;
		} elsif (m|^\s*<key>CFBundleVersion</key>\s*$|) {
			$version = 1;
			next;
		}
	}

	if (! defined $version) {
		warn "warning: Growl version cannot be found!\n";
		return;
	}

	my($V, $R) = map { join '', map { chr } split /\./, $_ } ($version, $REQUIRED);
	if ($V lt $R) {
		warn "warning: Growl version is $version; minimum $REQUIRED required!\n";
		return;
	}

	return 1;
}


sub findbin {
	my($name) = @_;
	chomp(my $path = `which $name`);
	if (!$path || $path =~ /\bno gluemac\b/) {
		my @paths = qw(/usr/local/bin /System/Library/Perl/Extras/bin /sw/bin /usr/bin);
		for (@paths) {
			my $test = catfile($_, $name);
			if (-e $test) {
				$path = $test;
				last;
			}
		}
	}
	return $path;
}

sub MY::postamble {
	return '' unless -e $GHA && $goodversion;
	my $path = findbin('gluemac') or return '';
	return <<"MAKE_FRAG";
.makeglue:
	@\$(PERL) '$path' -I '$GHA'
	@\$(TOUCH) .makeglue

all :: .makeglue

MAKE_FRAG
}
