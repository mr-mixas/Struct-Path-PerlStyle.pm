#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 8;

use Struct::Path::PerlStyle qw(ps_serialize);

my $str;

# undef path
eval { $str = ps_serialize(undef) };
#print STDERR Dumper $str;
ok($@ =~ '^Path must be arrayref');

# empty path
$str = ps_serialize([]);
#print STDERR Dumper $str;
ok($str eq '');

### HASHES ###

# empty hash path
$str = ps_serialize([{a => undef},{},{c => 0.18}]);
#print STDERR Dumper $str;
ok($str eq '{a}{}{c}');

# simple hash path
$str = ps_serialize([{a => undef},{b => 0},{c => 0.18}]);
#print STDERR Dumper $str;
ok($str eq '{a}{b}{c}');

# order specified hash path
$str = ps_serialize([{a => 1,b => 0},{c => 0,d => 1}]);
#print STDERR Dumper $str;
ok($str eq '{b,a}{c,d}');

### ARRAYS ###

# simple array path
$str = ps_serialize([[2],[],[0]]);
#print STDERR Dumper $str;
ok($str eq '[2][][0]');

# simple array path
$str = ps_serialize([[2],[5],[0]]);
#print STDERR Dumper $str;
ok($str eq '[2][5][0]');

# Array path with slices and whitespace garbage
$str = ps_serialize([[0,2],[7,5,2]]);
#print STDERR Dumper $str;
ok($str eq '[0,2][7,5,2]');

