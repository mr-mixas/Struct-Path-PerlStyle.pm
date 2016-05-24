#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 13;

use Struct::Path::PerlStyle qw(ps_parse);

sub pcmp($$) {
    my $str = shift;
    my $got = Data::Dumper->new([ps_parse($str)])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Dump();
    my $exp = Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Dump();
    print STDERR "\nDEBUG for '$str':\ngot: $got\nexp: $exp\n";
    return $got eq $exp;
}

# TODO:
# range with one boundary
# garbage like '{a][0}' and so on
# float point array indexes
# space and other garbage between path elements

# udndef path
eval { pcmp(undef, []) };
ok($@);

# non-scalar path
eval { pcmp({}, []) };
ok($@);

# empty path
ok(pcmp(
    '',
    []
));

### HASHES ###

# Plain hash path
ok(pcmp(
    '{a}{b}{c}',
    [{a => 0},{b => 0},{c => 0}]
));

# Hash path with slices and whitespace garbage
ok(pcmp(
    '{ c,a, b}{e  ,d }',
    [{c => 0,a => 1,b => 2},{e => 0,d => 1}]
));

# Empty hash path
ok(pcmp(
    '{}{}{}',
    [{},{},{}]
));

# Spaces as delimiters
ok(pcmp(
    '{a b}{e d}',
    [{a => 0,b => 1},{e => 0,d => 1}]
));

# Quotes
ok(pcmp(
    "{'a', 'b'}{' c d'}",
    [{a => 0,b => 1},{' c d' => 0}]
));

# Double quotes
ok(pcmp(
    '{"a", "b"}{" c d"}',
    [{a => 0,b => 1},{' c d' => 0}]
));

### ARRAYS ###

# Array path with slices
ok(pcmp(
    '[2][5][0]',
    [[2],[5],[0]]
));

# Array path with slices and whitespace garbage
ok(pcmp(
    '[ 0,2][7,5 , 2]',
    [[0,2],[7,5,2]]
));

# Array path with ranges
ok(pcmp(
    '[0..3][8..5]',
    [[0..3],[reverse 5..8]] # perl doesn't support backward ranges, Struct::Path::PerlStyle does =)
));

# Empty array path
ok(pcmp(
    '[][][]',
    [[],[],[]]
));

