#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Struct::Path::PerlStyle' ) || print "Bail out!\n";
}

diag( "Testing Struct::Path::PerlStyle $Struct::Path::PerlStyle::VERSION, Perl $], $^X" );
