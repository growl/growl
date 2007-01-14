#!/usr/bin/perl

MAIN:{
	my @files = ();
	opendir( DIR, shift @ARGV ) or die "Unable to open directory: $!";
	@files = readdir(DIR);
	closedir( DIR );
	
	foreach my $file ( @files ){
		next if $file =~ /^\./;
		next if $file !~ /\.tif$/;
		
		system("tiffutil","-cat", $file) and die "Unable to tiffutil: $!";
		system("mv", "out.tiff", $file) and die "Unable to mv: $!";
	}
}