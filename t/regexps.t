#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;
use Struct::Path::PerlStyle qw(ps_serialize);

eval { ps_serialize([{regs => 1}]) };
like($@, qr/^Unsupported hash regs definition, step #0 /);

eval { ps_serialize([{regs => [1]}]) };
like($@, qr/^Regexp expected for regs item, step #0 /);

is(
    ps_serialize([{regs => [qr/^Lonesome regexp$/mi]}]),
    '{/^Lonesome regexp$/mi}',
);

is(
    ps_serialize([{keys => ['Mixed', 'with'], regs => [qr/regular keys/]}]),
    '{Mixed,with,/regular keys/}',
);

is(
    ps_serialize([{regs => [qr/^Anchors$/]}]),
    '{/^Anchors$/}',
);

is(
    ps_serialize([{regs => [qr/Character\b\B\d\D\s\S\w\WClasses/]}]),
    '{/Character\b\B\d\D\s\S\w\WClasses/}',
);

is(
    ps_serialize([{regs => [qr/^Regular\/\/Slashes/]}]),
    '{/^Regular\/\/Slashes/}',
    'Regular slashes'
);

is(
    ps_serialize([{regs => [qr/^TwoBack\\Slashes/]}]),
    '{/^TwoBack\\\\Slashes/}',
    'Back slashes'
);

is(
    ps_serialize([{regs => [qr/Escape\t\n\r\f\b\a\eSequences/]}]),
    '{/Escape\t\n\r\f\b\a\eSequences/}',
    'Escape sequences'
);

is(
    ps_serialize([{regs => [qr/Escape\x{263A}|\x1b|\N{U+263D}|\c[|\o{23072}|\033Sequences2/]}]),
    '{/Escape\x{263A}|\x1b|\N{U+263D}|\c[|\o{23072}|\033Sequences2/u}', # /u mod automatically added
    'Escape sequences2'
);

