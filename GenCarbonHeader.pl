#!/usr/bin/perl
use strict;
use warnings;
use POSIX;

#Translate the Cocoa GrowlDefines.h file into one suitable for
#use in Carbon apps, by
#(1) Stripping the protocol information from the file, and
#(2) Converting all @"String" forms into CFSTR("String")

my $infile = shift || "GrowlDefines.h";
my $outfile = shift || "GrowlDefinesCarbon.h";
my $line;

open(COCOA, "<", $infile) or die("Couldn't open $infile: $!");
open(CARBON, ">", $outfile);

my $date = POSIX::strftime("%a %b %Y", localtime);
print CARBON <<ENDOFHEADER;
//
// $outfile
//
// Automatically generated from $infile on $date by GenCarbonHeader.pl
//

ENDOFHEADER

while(<COCOA> =~ m{^//}) {}	#Strip the initial comment header

#Loop until we hit the protocol declarations
while(defined($line = <COCOA>) && ($line !~ m{^@}))
{
	$line =~ s/@"(.*)"/CFSTR("$1")/g;
	print CARBON $line;
}

close(CARBON);
close(COCOA);