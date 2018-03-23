#!perl -T

use strict;
use warnings;

use Struct::Path::PerlStyle qw(str2path path2str);
use Test::More tests => 16;

use lib 't';
use _common qw(roundtrip);

### EXCEPTIONS ###

eval { str2path(undef) };
like($@, qr/^Undefined path passed/);

eval { str2path({}) };
like($@, qr/^Unsupported thing in the path, step/);

eval { str2path('{a},{b}') };
like($@, qr/^Unsupported thing in the path, step /, "garbage between path elements");

eval { str2path('{a} []') };
like($@, qr/^Unsupported thing in the path, step /, "space between path elements");

eval { str2path('{a};[]') };
like($@, qr/^Unsupported thing in the path, step /, "semicolon between path elements");

eval { str2path('[0}') };
like($@, qr/^Unsupported thing in the path, step /, "unmatched brackets");

eval { str2path('{a') };
like($@, qr/^Unsupported thing in the path, step /, "unclosed curly brackets");

eval { str2path('[0') };
like($@, qr/^Unsupported thing in the path, step /, "unclosed square brackets");

eval { str2path('(0)') };
like($@, qr/^Unsupported thing .* hook, step /, "parenthesis in the path");

eval { str2path('{a}{b+c}') };
like($@, qr/^Unsupported thing .* for hash key, step /, "garbage in hash keys definition");

eval { str2path('{/a//}') };
like($@, qr|^Unsupported thing .* for hash key, step |, "regexp and one more slash");

eval { path2str(undef) };
like($@, qr/^Arrayref expected for path/, "undef as path");

eval { path2str([{},"garbage"]) };
like($@, qr/^Unsupported thing in the path, step /, "trash as path step");

### Immutable $_ ###

$_ = 'bareword';
eval { str2path($_) };
like($@, qr/^Unsupported thing in the path, step #0 at /);
is($_, 'bareword', '$_ must remain unchanged');

roundtrip ([], '', 'Empty path');
