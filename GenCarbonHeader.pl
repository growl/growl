#!/usr/bin/perl
use strict;
use warnings;
use POSIX;

#Translate the Cocoa GrowlDefines.h file into one suitable for
#use in Carbon apps, by
#(1) Stripping the protocol information from the file, and
#(2) Converting all @"String" forms into CFSTR("String")

my @infiles = ("GrowlDefines.h", "GrowlAppBridgeDefines.h");
my %outfiles = ("GrowlDefinesInternal.h" => "GrowlDefinesInternalCarbon.h",
		"GrowlDefines.h" => "GrowlDefinesCarbon.h");

foreach my $infile (@infiles) {
	my $outfile = $outfiles{$infile};
	my $line;

	open(COCOA, "<", $infile) or die("Couldn't open $infile: $!");
	open(CARBON, ">", $outfile);

	my $date = POSIX::strftime("%a %Y-%m-%d", localtime);
	print CARBON <<ENDOFHEADER;
//
// $outfile
//
// Automatically generated from $infile on $date by GenCarbonHeader.pl
//

ENDOFHEADER

	while(<COCOA> =~ m{^//}) {}	#Strip the initial comment header

	#Loop until we hit the macros for plugins
	while(defined($line = <COCOA>) && ($line !~ m{/\* ---})) {
		$line =~ s/@"([^"\r\n]*)"/CFSTR("$1")/g;
		foreach my $header (@infiles) {
			$line =~ s/#import "$header"/#import "$outfiles{$header}"/g;
		}
		print CARBON $line;
	}

	close(CARBON);
	close(COCOA);
}

