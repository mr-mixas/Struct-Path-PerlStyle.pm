#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 18;

use Struct::Path::PerlStyle qw(ps_serialize);

my $str;

# undef path
eval { $str = ps_serialize(undef) };
ok($@ =~ /^Path must be an arrayref/);

# empty path
$str = ps_serialize([]);
ok($str eq '');

# trash as path step
eval { $str = ps_serialize([{},"garbage"]) };
ok($@ =~ /^Unsupported thing in the path \(step #1\)/);

# trash in hash definition #1
eval { $str = ps_serialize([{garbage => ['a']}]) };
ok($@ =~ /^Unsupported hash definition \(step #0\)/);

# trash in hash definition #2
eval { $str = ps_serialize([{keys => 'a'}]) };
ok($@ =~ /^Unsupported hash definition \(step #0\)/);

### HASHES ###

# empty hash path
$str = ps_serialize([{keys => ['a']},{},{keys => ['c']}]);
ok($str eq '{a}{}{c}');

# simple hash path
$str = ps_serialize([{keys => ['a']},{keys => ['b']},{keys => ['c']}]);
ok($str eq '{a}{b}{c}');

# order specified hash path
$str = ps_serialize([{keys => ['b','a']},{keys => ['c','d']}]);
ok($str eq '{b,a}{c,d}');

# quotes for spaces
$str = ps_serialize([{keys => ['three   spaces']},{keys => ['two  spases']},{keys => ['one ']},{keys => ['none']}]);
ok($str eq "{'three   spaces'}{'two  spases'}{'one '}{none}");

# quotes for tabs
$str = ps_serialize([{keys => ['three			tabs']},{keys => ['two		tabs']},{keys => ['one	']},{keys => ['none']}]);
ok($str eq "{'three			tabs'}{'two		tabs'}{'one	'}{none}");

### ARRAYS ###

# garbage: non number as index
eval { $str = ps_serialize([["a"]]) };
ok($@ =~ /^Incorrect array index 'a' \(step #0\)/);

# garbage: float point as index
eval { $str = ps_serialize([[0.3]]) };
ok($@ =~ /^Incorrect array index '0.3' \(step #0\)/);

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

# Bidirectional ranges
$str = ps_serialize([[-2,-1,0,1,2,1,0,-1,-2]]);
ok($str eq '[-2..2,1..-2]');
