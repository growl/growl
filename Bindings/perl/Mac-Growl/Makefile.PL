use 5.008001;
use ExtUtils::MakeMaker;
use File::Spec::Functions;
use Getopt::Long;

my $opt = {};
GetOptions($opt, 'growlhelperapp=s');

my($GHA) = grep { -e } (
	$opt->{growlhelperapp},
	'/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app'
);

WriteMakefile(
	NAME		=> 'Mac::Growl',
	VERSION_FROM	=> 'lib/Mac/Growl.pm',
	clean		=> {
		'FILES'		=> 'Mac-Growl-* .makeglue'
	},
	NO_META		=> 1,
);

sub findbin {
	my($name) = @_;
	chomp(my $path = `which $name 2>/dev/null`);
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
	return '' unless -e $GHA;
	my $path = findbin('gluemac') or return '';
	return <<"MAKE_FRAG";
.makeglue:
	@\$(PERL) '$path' -I '$GHA'
	@\$(TOUCH) .makeglue

all :: .makeglue

MAKE_FRAG
}
