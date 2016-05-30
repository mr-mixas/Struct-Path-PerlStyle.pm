#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 22;

use Struct::Path::PerlStyle qw(ps_parse);

sub pcmp($$) {
    my $str = shift;
    my $got = Data::Dumper->new([ps_parse($str)])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Dump();
    my $exp = Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Dump();
    print STDERR "\nDEBUG for '$str':\ngot: $got\nexp: $exp\n" if ($ENV{DEBUG});;
    return $got eq $exp;
}

# TODO:
# float point numbers as arrays indexes

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

# garbage between path elements
eval { pcmp('{a},{b}', []) };
ok($@ =~ m/^Unsupported thing ',' in the path/);

# space between path elements
eval { pcmp('{a} []', []) };
ok($@ =~ m/^Unsupported thing ' ' in the path/);

# unmatched brackets
eval { pcmp('{a][0}', []) };
ok($@ =~ m/^Unsupported thing ']' in the path/);

# unmatched brackets2
eval { pcmp('[0}', []) };
ok($@ =~ m/^Unsupported thing '}' in the path/);

# parenthesis in the path
eval { pcmp('(0)', []) };
ok($@ =~ m/^Unsupported thing '\(0\)' in the path/);

# garbage: nested steps
eval { pcmp('[[0]]', []) };
ok($@ =~ m/^Unsupported thing '\[0\]' in array item specification/);

# range with one boundary
eval { pcmp('[..3]', []) };
ok($@ =~ m/^Undefined start for range/);

# range with one boundary2
eval { pcmp('[4..]', []) };
ok($@ =~ m/^Unfinished range secified/);

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

# float point indexes
ok(pcmp(
    '[0.3][][3.12]',
    [[0.3],[],[3.12]]
));

