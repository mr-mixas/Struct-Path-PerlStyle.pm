# NAME

Struct::Path::PerlStyle - Perl-style syntax frontend for [Struct::Path](https://metacpan.org/pod/Struct::Path).

# VERSION

Version 0.23

# SYNOPSIS

    use Struct::Path::PerlStyle qw(ps_parse ps_serialize);

    $struct = ps_parse('{a}{b}[1]');    # Struct::Path compatible
    $string = ps_serialize($struct);    # convert Struct::Path path to string

# EXPORT

Nothing is exported by default.

# SUBROUTINES

## ps\_parse

Parse perl-style string to [Struct::Path](https://metacpan.org/pod/Struct::Path) path

    $struct_path = ps_parse($string);

Path syntax examples:

    "{a}{b}"              # means b's value
    "{a}{}"               # all values from a's subhash; same for arrays (using empty square brackets)
    "{a}{b,c}"            # b's and c's values
    "{a}{b c}"            # same, space is also a delimiter
    "{a}{'space inside'}" # keys with spaces/tabs must be quoted (double quotes supported as well)
    "{a}{b}[0,1,2,5]"     # 0, 1, 2 and 5 array's items
    "{a}{b}[0..2,5]"      # same, but using ranges
    "{a}{b}[9..0]"        # descending ranges allowed (perl doesn't)

## ps\_serialize

Serialize [Struct::Path](https://metacpan.org/pod/Struct::Path) path to perl-style string

    $string = ps_serialize($struct_path);

# AUTHOR

Michael Samoglyadov, `<mixas at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-struct-path-native at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-PerlStyle](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-PerlStyle). I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

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

[Struct::Path](https://metacpan.org/pod/Struct::Path), [Struct::Diff](https://metacpan.org/pod/Struct::Diff), [perldata](https://metacpan.org/pod/perldata)

# LICENSE AND COPYRIGHT

Copyright 2016 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
