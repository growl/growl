#!/usr/bin/perl
use strict;
use warnings;
use POSIX;

#Translate the Cocoa GrowlDefines.h file into one suitable for
#use in Carbon apps, by
#(1) Stripping the protocol information from the file, and
#(2) Changing imports to includes
#(3) Replacing filenames in #imports/#includes and #include guards
#(4) Converting all @"String" forms into CFSTR("String")
#	(not in that order)

my @infiles = ("GrowlDefines.h", "GrowlDefinesInternal.h");
my %outfiles = ("GrowlDefinesInternal.h" => "GrowlDefinesInternalCarbon.h",
		"GrowlDefines.h" => "GrowlDefinesCarbon.h");
#include guards (needed for Carbon apps, since they don't generally use #import)
my @infileguards = ("_GROWL_GROWLDEFINES_H", "_GROWL_GROWLDEFINESINTERNAL_H");
my %outfileguards = ("_GROWL_GROWLDEFINESINTERNAL_H" => "_GROWL_GROWLDEFINESINTERNALCARBON_H",
		"_GROWLDEFINES_H" => "_GROWLDEFINESCARBON_H");

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
			$line =~ s/#(\s*)import <Growl\/$header>/#$1include <Growl\/$outfiles{$header}>/g;
		}
		$line =~ s/#(\s*)import <(.+)>/#$1include <$2>/g;
		foreach my $guard (@infileguards) {
			$line =~ s/$guard/$outfileguards{$guard}/;
		}
		print CARBON $line;
	}

	close(CARBON);
	close(COCOA);
}

