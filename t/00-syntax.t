#!/usr/bin/env perl

use strict;
my @files;
BEGIN {
	@files = ( 'blib/lib/Apache2/Warn.pm' );
}
use Test::More tests => 0+@files;
for (@files) {
	my $out = `$^X -w -c $_ 2>&1`;
	if ($out !~ /syntax OK$/s) {
		ok 0, "$_";
		diag $out;
	} else {
		ok 1, "$_";
		diag $out;
	}
}
