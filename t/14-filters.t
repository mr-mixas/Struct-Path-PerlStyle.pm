#!perl -T

use strict;
use warnings;
use Struct::Path::PerlStyle qw(ps_parse);
use Test::More tests => 16;

eval { ps_parse('[0](=>)[-2]') };
like($@, qr/^Unsupported operator '=>' specified/, "Unsupported operator");

eval { ps_parse('[0](<<(<<))[-2]') };
like($@, qr/^Unsupported thing '\(<<\)' as operator argument/, "Unsupported arg type");

eval { ps_parse('[0](<<<<)[-2]') };
like($@, qr/^Unsupported thing '<<' as operator argument/, "Unsupported arg type");

# args passed to callback by Struct::Path (sample)
my $args = [
    [[0],[1]], # path passed as first arg
    ["a","b"], # data refs array as second
];

ok(
    ps_parse('[0](<<)')->[1]->($args->[0], $args->[1]),
    "Step back must returns 1"
);

is_deeply(
    $args,
    [[[0]], ["a"]],
    "One step back"
);

$args = [
    [[0],[1]],
    ["a","b"],
];

ok(
    ps_parse('[0](<<2)')->[1]->($args->[0], $args->[1]),
    "Step back must returns 1"
);

is_deeply(
    $args,
    [[], []],
    "Two steps back"
);

$args = [
    [[0],[1]],
    ["a","b"],
];

eval { ps_parse('[0](<<3)')->[1]->($args->[0], $args->[1]) };
like(
    $@, qr/^Can't step back \(root of the structure\)/,
    "Must fail if backs steps more than current path length"
);

$args = [
    [[0],[1]],
    [\"a",\"b"],
];

eval { ps_parse("[0][1](eq 'b' 'c')")->[2]->($args->[0], $args->[1]) };
like($@, qr/^Only one arg accepted by 'eq'/, "As is");

ok(
    ps_parse("[0][1](eq 'b')")->[2]->($args->[0], $args->[1]),
    "eq must return true value here"
);

ok(
    ps_parse('[0][1](eq "b")')->[2]->($args->[0], $args->[1]),
    "eq must return true value here"
);

ok(
    ! ps_parse("[0][1](eq 'a')")->[2]->($args->[0], $args->[1]),
    "eq must return false value here"
);

$args = [ [[1]], [\undef] ];

ok(
    ! ps_parse('(defined)')->[0]->($args->[0], $args->[1]),
    "'defined' must return false value"
);

ok(
    ps_parse("(not defined)")->[0]->($args->[0], $args->[1]),
    "negate defined's false value"
);

ok(
    ps_parse("(! defined)")->[0]->($args->[0], $args->[1]),
    "negate defined's false value"
);
ok(
    ps_parse("(!defined)")->[0]->($args->[0], $args->[1]),
    "negate defined's false value"
);
