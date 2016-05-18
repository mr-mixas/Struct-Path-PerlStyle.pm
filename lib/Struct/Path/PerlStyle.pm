package Struct::Path::PerlStyle;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use Carp qw(croak);
use PPI::Lexer;

BEGIN { our @EXPORT_OK = qw(ps_parse ps_serialize) }

=head1 NAME

Struct::Path::PerlStyle - Perl-style Path syntax frontend for Struct::Path.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Struct::Path::PerlStyle qw(ps_parse ps_serialize);

    $struct = ps_parse('{a}{b}[1]'); # Struct::Path compatible
    $string = ps_serialize($struct);

=head1 EXPORT

Nothing exports by default.

=head1 SUBROUTINES

=head2 ps_parse

Parse perl-style struct path string to Struct::Path format

Path syntax examples:

    "{a}{b}"              # means b's value
    "{a}{}"               # all values from a's subhash; same for arrays (using empty square brackets)
    "{a}{b,c}"            # b's and c's values
    "{a}{b c}"            # same, space is also a delimiter (except if quoted)
    "{a}{b}[0,1,2,5]"     # 0, 1, 2 and 5 array's items
    "{a}{b}[0..2,5]"      # same, but using ranges
    "{a}{b}[9..0]"        # descending ranges allowed (perl doesn't)

=cut

sub ps_parse($) {
    my $doc = PPI::Lexer->lex_source(shift);
    my $out;

    for my $c (map { $_->elements } $doc->children) {
        $c->prune('PPI::Token::Whitespace');
        my @tokens = map { $_->elements } $c->children;

        if ($c->isa('PPI::Structure::Block') or
            ($c->isa('PPI::Structure::Constructor') and $c->first_token->content eq '{')) {
            push @{$out}, {};
            for my $t (@tokens) {
                next if ($t->isa('PPI::Token::Operator') and $t->content eq ',');
                $out->[-1]->{$t->content} = keys %{$out->[-1]};
            }
        } elsif ($c->isa('PPI::Structure::Constructor') and $c->first_token->content eq '[') {
            push @{$out}, [];
            my $is_range;
            for my $t (@tokens) {
                if ($t->isa('PPI::Token::Number')) {
                    if ($is_range) {
                        my $start = pop(@{$out->[-1]});
                        push @{$out->[-1]}, ($start < $t->content ? $start..$t->content : reverse $t->content..$start);
                    } else {
                        push @{$out->[-1]}, $t->content + 0;
                    }
                } elsif ($t->isa('PPI::Token::Operator') and $t->content eq ',') {
                    $is_range = undef;
                } elsif ($t->isa('PPI::Token::Operator') and $t->content eq '..') {
                    $is_range = $t;
                } else {
                    croak "Unsupported thing '" . $t->content . "' in array's item specification";
                }
            }
        } else {
            croak "Unsupported thing in the path";
        }
    }

    return $out;
}

=head2 ps_serialize

Serialize Struct::Path format to perl-style string

=cut

sub ps_serialize($) {
    croak "Not implemented yet";
}

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-path-native at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-PerlStyle>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Path::PerlStyle

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path-PerlStyle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Path-PerlStyle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Path-PerlStyle>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Path-PerlStyle/>

=back

=head1 SEE ALSO

L<Struct::Path>, L<Struct::Diff>, L<perldata>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path::PerlStyle
