#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 26;

use Struct::Path::PerlStyle qw(ps_parse);

sub pcmp($$) {
    my $str = shift;
    my $got = Data::Dumper->new([ps_parse($str)])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Dump();
    my $exp = Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Dump();
    print STDERR "\nDEBUG for '$str':\ngot: $got\nexp: $exp\n" if ($ENV{DEBUG});;
    return $got eq $exp;
}

# udndef path
eval { pcmp(undef, []) };
ok($@);

# non-scalar path
eval { pcmp({}, []) };
ok($@ =~ m/^Failed to parse passed path 'HASH\(/);

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

# garbage in index definition
eval { pcmp('[0-2]', []) };
ok($@ =~ m/^Unsupported thing '-' in array item specification \(step #0\)/);

# range with one boundary
eval { pcmp('[..3]', []) };
ok($@ =~ m/^Undefined start for range/);

# range with one boundary2
eval { pcmp('[4..]', []) };
ok($@ =~ m/^Unfinished range secified/);

# floating point array indexes
eval { pcmp('[3.1415]', []) };
ok($@ =~ m/^Floating-point numbers not allowed as array indexes \(step #0\)/);

# garbage in hash keys definition
eval { pcmp('{a}{b+c}', []) };
ok($@ =~ m/^Unsupported thing '\+' in hash key specification \(step #1\)/);

### HASHES ###

# Plain hash path
ok(pcmp(
    '{a}{b}{c}',
    [{keys => ['a']},{keys => ['b']},{keys => ['c']}]
));

# Hash path with slices and whitespace garbage
ok(pcmp(
    '{ c,a, b}{e  ,d }',
    [{keys => ['c','a','b']},{keys => ['e','d']}]
));

# Empty hash path
ok(pcmp(
    '{}{}{}',
    [{},{},{}]
));

# Spaces as delimiters
ok(pcmp(
    '{a b}{e d}',
    [{keys => ['a','b']},{keys => ['e','d']}]
));

# Quotes
ok(pcmp(
    "{'a', 'b'}{' c d'}",
    [{keys => ['a','b']},{keys => [' c d']}]
));

# Double quotes
ok(pcmp(
    '{"a", "b"}{" c d"}',
    [{keys => ['a','b']},{keys => [' c d']}]
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

# float point indexes with zero after dot is allowed
ok(pcmp(
    '[0.0][1][2.0]',
    [[0],[1],[2]]
));

# big numbers
ok(pcmp(
    '[99999999999999999999]',
    [['1e+20']]
));
