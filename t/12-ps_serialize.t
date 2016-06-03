#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 10;

use Struct::Path::PerlStyle qw(ps_serialize);

my $str;

# undef path
eval { $str = ps_serialize(undef) };
ok($@ =~ '^Path must be an arrayref');

# empty path
$str = ps_serialize([]);
ok($str eq '');

### HASHES ###

# empty hash path
$str = ps_serialize([{a => undef},{},{c => 0.18}]);
ok($str eq '{a}{}{c}');

# simple hash path
$str = ps_serialize([{a => undef},{b => 0},{c => 0.18}]);
ok($str eq '{a}{b}{c}');

# order specified hash path
$str = ps_serialize([{a => 1,b => 0},{c => 0,d => 1}]);
ok($str eq '{b,a}{c,d}');

### ARRAYS ###
# simple array path
$str = ps_serialize([[2],[],[0]]);
ok($str eq '[2][][0]');

# simple array path
$str = ps_serialize([[2],[5],[0]]);
ok($str eq '[2][5][0]');

# Array path with slices
$str = ps_serialize([[0,2],[7,5,2]]);
ok($str eq '[0,2][7,5,2]');

# Ascending ranges
$str = ps_serialize([[0,1,2],[6,7,8,10]]);
ok($str eq '[0..2][6..8,10]');

# Descending ranges
$str = ps_serialize([[2,1,0],[10,8,7,6]]);
ok($str eq '[2..0][10,8..6]');

