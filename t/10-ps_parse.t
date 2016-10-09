#!perl -T

use strict;
use warnings;
use Struct::Path::PerlStyle qw(ps_parse);
use Test::More tests => 28;

### EXCEPTIONS ###

eval { ps_parse(undef) };
like($@, qr/^Undefined path passed/);

eval { ps_parse({}) };
like($@, qr/^Failed to parse passed path 'HASH\(/);

eval { ps_parse('{a},{b}') };
like($@, qr/^Unsupported thing ',' in the path/, "garbage between path elements");

eval { ps_parse('{a} []') };
like($@, qr/^Unsupported thing ' ' in the path/, "space between path elements");

eval { ps_parse('{a][0}') };
like($@, qr/^Unsupported thing ']' in the path/, "unmatched brackets");

eval { ps_parse('[0}') };
like($@, qr/^Unsupported thing '}' in the path/, "unmatched brackets2");

eval { ps_parse('(0)') };
like($@, qr/^Unsupported thing '\(0\)' in the path/, "parenthesis in the path");

eval { ps_parse('[[0]]') };
like($@, qr/^Unsupported thing '\[0\]' in array item specification/, "garbage: nested steps");

eval { ps_parse('[0-2]') };
like($@, qr/^Unsupported thing '-' in array item specification \(step #0\)/, "garbage in index definition");

eval { ps_parse('[..3]') };
like($@, qr/^Undefined start for range/, "range with one boundary");

eval { ps_parse('[4..]') };
like($@, qr/^Unfinished range secified/, "range with one boundary2");

eval { ps_parse('[3.1415]') };
like($@, qr/^Floating-point numbers not allowed as array indexes \(step #0\)/, "floating point array indexes");

eval { ps_parse('{a}{b+c}') };
like($@, qr/^Unsupported thing '\+' in hash key specification \(step #1\)/, "garbage in hash keys definition");

### EMPTY PATH ###

is_deeply(
    ps_parse(''),
    [],
    "empty string - empty path"
);

### HASHES ###

is_deeply(
    ps_parse('{0}{01}{"2"}'),
    [{keys => [0]},{keys => ["01"]},{keys => [2]}],
    "numbers as hash keys"
);

is_deeply(
    ps_parse('{a}{b}{c}'),
    [{keys => ['a']},{keys => ['b']},{keys => ['c']}],
    "plain hash path"
);

is_deeply(
    ps_parse('{ c,a, b}{e  ,d }'),
    [{keys => ['c','a','b']},{keys => ['e','d']}],
    "hash path with slices and whitespace garbage"
);

is_deeply(
    ps_parse('{}{}{}'),
    [{},{},{}],
    "empty hash path"
);

is_deeply(
    ps_parse('{a b}{e d}'),
    [{keys => ['a','b']},{keys => ['e','d']}],
    "spaces as delimiters"
);

is_deeply(
    ps_parse("{'a', 'b'}{' c d'}"),
    [{keys => ['a','b']},{keys => [' c d']}],
    "quotes"
);

is_deeply(
    ps_parse('{"a", "b"}{" c d"}'),
    [{keys => ['a','b']},{keys => [' c d']}],
    "double quotes"
);

### ARRAYS ###

is_deeply(
    ps_parse('[2][5][0]'),
    [[2],[5],[0]],
    "array path with slices"
);

is_deeply(
    ps_parse('[ 0,2][7,5 , 2]'),
    [[0,2],[7,5,2]],
    "array path with slices and whitespace garbage"
);

is_deeply(
    ps_parse('[0..3][8..5]'),
    [[0..3],[reverse 5..8]],
    "perl doesn't support backward ranges, Struct::Path::PerlStyle does =)"
);

is_deeply(
    ps_parse('[][][]'),
    [[],[],[]],
    "empty array path"
);

is_deeply(
    ps_parse('[0.0][1][2.0]'),
    [[0],[1],[2]],
    "float point indexes with zero after dot is allowed"
);

is_deeply(
    ps_parse('[0][-1][-2]'),
    [[0],[-1],[-2]],
    "negative indexes"
);

### OPERATORS ###

is_deeply(
    ps_parse('[0]<[-2]'),
    [[0],$Struct::Path::PerlStyle::OPERATORS->{'<'},[-2]],
    "step back"
);
