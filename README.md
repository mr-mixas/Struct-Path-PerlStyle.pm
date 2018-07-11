# NAME

Struct::Path::PerlStyle - Perl-style syntax frontend for [Struct::Path](https://metacpan.org/pod/Struct::Path).

<a href="https://travis-ci.org/mr-mixas/Struct-Path-PerlStyle.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Path-PerlStyle.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Path-PerlStyle.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Path-PerlStyle.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Path-PerlStyle"><img src="https://badge.fury.io/pl/Struct-Path-PerlStyle.svg" alt="CPAN version"></a>

# VERSION

Version 0.80

# SYNOPSIS

    use Struct::Path qw(spath);
    use Struct::Path::PerlStyle qw(path2str str2path);

    my $nested = {
        a => {
            b => ["B0", "B1", "B2"],
            c => ["C0", "C1"],
            d => {},
        },
    };

    my @found = path($nested, str2path('{a}{}[0,2]'), deref => 1, paths => 1);

    while (@found) {
        my $path = shift @found;
        my $data = shift @found;

        print "path '" . path2str($path) . "' refer to '$data'\n";
    }

    # path '{a}{b}[0]' refer to 'B0'
    # path '{a}{b}[2]' refer to 'B2'
    # path '{a}{c}[0]' refer to 'C0'

# EXPORT

Nothing is exported by default.

# PATH SYNTAX

Examples:

    '{a}{b}'              # points to b's value
    '{a}{}'               # all values from a's subhash; same for arrays (using empty square brackets)
    '{a}{b,c}'            # b's and c's values
    '{a}{"space inside"}' # key must be quoted unless it is a simple word (single quotes supported as well)
    '{a}{"multi\nline"}'  # same for special characters (if double quoted)
    '{a}{/pattern/mods}'  # regexp keys match (fully supported, except code expressions)
    '{a}{b}[0,1,2,5]'     # 0, 1, 2 and 5 array's items
    '{a}{b}[0..2,5]'      # same, but using ranges
    '{a}{b}[9..0]'        # descending ranges allowed (perl doesn't)
    '{a}{b}(back){c}'     # step back (to previous level)

# SUBROUTINES

## str2path

Convert perl-style string to [Struct::Path](https://metacpan.org/pod/Struct::Path) path structure

    $struct = str2path($string);

## path2str

Convert [Struct::Path](https://metacpan.org/pod/Struct::Path) path structure to perl-style string

    $string = path2str($struct);

# AUTHOR

Michael Samoglyadov, `<mixas at cpan.org>`

# BUGS

Please report any bugs or feature requests to
`bug-struct-path-perlstyle at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-PerlStyle](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-PerlStyle). I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Path::PerlStyle

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path-PerlStyle](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path-PerlStyle)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Struct-Path-PerlStyle](http://annocpan.org/dist/Struct-Path-PerlStyle)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Struct-Path-PerlStyle](http://cpanratings.perl.org/d/Struct-Path-PerlStyle)

- Search CPAN

    [http://search.cpan.org/dist/Struct-Path-PerlStyle/](http://search.cpan.org/dist/Struct-Path-PerlStyle/)

# SEE ALSO

[Struct::Path](https://metacpan.org/pod/Struct::Path), [Struct::Diff](https://metacpan.org/pod/Struct::Diff), [perldsc](https://metacpan.org/pod/perldsc), [perldata](https://metacpan.org/pod/perldata)

# LICENSE AND COPYRIGHT

Copyright 2016,2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
