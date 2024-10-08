#!/usr/bin/perl

#
# (c) 2009, 2024 by Konstantin Boyandin <konstantin@boyandin.com>
#
# A script to gather all the comments for an authro section on Samizdat-like sites
#
use strict;

sub process_files();
sub process_file($);
sub get_comments_count($);
sub get_file($$);

#
# Prerequisites:
# - the section mirrored already
# - this script is run from the directory containing all the works (.shtml)
# - its directory reflects the section address convention of Samizdat
#
my %vars = ();

#
# Here we go
#
process_files();
exit(0);

#
# For all the non-internal .shtml files repeat the comment-gathering sequence
#

sub process_files() {
	local *DIR;
	
	# Obtain current directory
	$vars{'pwd'} = `pwd`; chomp($vars{'pwd'});
	# Obtain section prefix
	$vars{'spref'} = substr($vars{'pwd'},rindex($vars{'pwd'},'/',rindex($vars{'pwd'},'/')-1));
	
	opendir(DIR, $vars{'pwd'});
	my @files = readdir(DIR);
	closedir(DIR);
	for my $fname (@files) {
		process_file($fname);
	}
	print $vars{'spref'} . "\n";
}

sub process_file($) {
	my ($filename) = @_;
	
	if ($filename =~ /^(?!(stat|index|indexdate|indextitle|indexvote|linklist)).*?\.shtml$/i) {
		my $fname = substr($filename,0,rindex($filename,'.'));
		print "Processing '$fname'\n";
		my $comlink = 'http://samlib.ru/comment' . $vars{'spref'} . '/' . $fname;
		my $ofname = "$fname.comment.0.1.html";
		if ((-e $ofname) && (-s $ofname)) {
			print "File exists: $ofname, skipping\n";
		} else {
			get_file($comlink,$ofname);
		}
		get_comments_count($vars{'pwd'}."/$ofname");
		for (my $a = 0; $a <= $vars{'arccnt'}; $a++) {
			for (my $b = 1; $b <= 26; $b++) {
				$ofname = "$fname.comment.$a.$b.html";
				if ($a == 0) {
					if (($b > 1) && ($b <= $vars{'comcnt'})) {
						$comlink = 'http://samlib.ru/comment' . $vars{'spref'} . '/' . "$fname?PAGE=$b";
						if ((-e $ofname) && (-s $ofname)) {
							print "File exists: $ofname, skipping\n";
						} else {
							get_file($comlink,$ofname);
						}
					}
				} else {
					$comlink = 'http://samlib.ru/comment' . $vars{'spref'} . '/' . "$fname.$a?PAGE=$b";
					if ((-e $ofname) && (-s $ofname)) {
						print "File exists: $ofname, skipping\n";
					} else {
						get_file($comlink,$ofname);
					}
				}
			}
		}
	}
}

sub get_comments_count($) {
	my ($filename) = @_;
	local *CFILE;

	open(CFILE,"<$filename") or die("No comment file $filename");
	$vars{'comcnt'} = $vars{'arccnt'} = 0;
	while (my $line = <CFILE>) {
		chomp($line);
		if ($line =~ /ORDER=reverse.*?\(([0-9]+)\)(.*?\(([0-9]+)\))?/i) {
			$vars{'comcnt'} = $1;
			if (defined($3)) {
				$vars{'arccnt'} = $3;
			} else {
				$vars{'arccnt'} = 0;
			}
			print "Comments count " . $vars{'comcnt'} . ", arc count " . $vars{'arccnt'} . "\n";
		}
	}
	close(CFILE);
}

sub get_file($$) {
	my ($url, $fname) = @_;
	print "Getting '$url' as '$fname'\n";
	my $rc = `wget -nv -c --waitretry=2 -t0 --user-agent="Mozilla/5.0 (X11; U; Linux i686; ru; rv:1.9.0.7) Gecko/2009030503 Fedora/3.0.7-1.fc9 Firefox/3.0.7"  "$url" -O $fname`;
}
