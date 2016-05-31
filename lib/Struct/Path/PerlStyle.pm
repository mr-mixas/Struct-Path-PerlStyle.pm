package Struct::Path::PerlStyle;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use Carp qw(croak);
use PPI::Lexer qw();

our @EXPORT_OK = qw(ps_parse ps_serialize);

=head1 NAME

Struct::Path::PerlStyle - Perl-style syntax frontend for L<Struct::Path|Struct::Path>.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Struct::Path::PerlStyle qw(ps_parse ps_serialize);

    $struct = ps_parse('{a}{b}[1]');    # L<Struct::Path|Struct::Path> compatible
    $string = ps_serialize($struct);    # convert Struct::Path path to string

=head1 EXPORT

Nothing exports by default.

=head1 SUBROUTINES

=head2 ps_parse

Parse perl-style string to L<Struct::Path|Struct::Path> path

    $struct_path = ps_parse($string);

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
    my $path = shift;
    croak "Undefined path passed" unless (defined $path);
    my $doc = PPI::Lexer->lex_source($path);
    croak "Failed to parse passed path '$path'" unless (defined $doc);
    my $out = [];

    for my $step ($doc->elements) {
        croak "Unsupported thing '" . $step->content . "' in the path" unless ($step->can('elements'));
        for my $item ($step->elements) {
            $item->prune('PPI::Token::Whitespace') if $item->can('prune');

            if ($item->isa('PPI::Structure::Block') or
                ($item->isa('PPI::Structure::Constructor') and $item->first_token->content eq '{')) {
                push @{$out}, {};
                for my $t (map { $_->elements } $item->children) {
                    my $key;
                    if ($t->isa('PPI::Token::Word')) {
                        $key = $t->content;
                    } elsif ($t->isa('PPI::Token::Operator') and $t->content eq ',') {
                        next;
                    } elsif ($t->isa('PPI::Token::Quote')) {
                        $key = substr(substr($t->content, 1), 0, -1);
                    } else {
                        croak "Unsupported thing '" . $t->content . "' in hash key specification";
                    }
                    $out->[-1]->{$key} = keys %{$out->[-1]};
                }
            } elsif ($item->isa('PPI::Structure::Constructor') and $item->first_token->content eq '[') {
                push @{$out}, [];
                my $is_range;
                for my $t (map { $_->elements } $item->children) {
                    if ($t->isa('PPI::Token::Number')) {
                        if ($is_range) {
                            my $start = pop(@{$out->[-1]});
                            croak "Undefined start for range" unless (defined $start);
                            push @{$out->[-1]},
                                ($start < $t->content ? $start..$t->content : reverse $t->content..$start);
                            $is_range = undef;
                        } else {
                            push @{$out->[-1]}, $t->content + 0;
                        }
                    } elsif ($t->isa('PPI::Token::Operator') and $t->content eq ',') {
                        $is_range = undef;
                    } elsif ($t->isa('PPI::Token::Operator') and $t->content eq '..') {
                        $is_range = $t;
                    } else {
                        croak "Unsupported thing '" . $t->content . "' in array item specification";
                    }
                }
                croak "Unfinished range secified" if ($is_range);
            } else {
                croak "Unsupported thing '" . $item->content . "' in the path" ;
            }
        }
    }

    return $out;
}

=head2 ps_serialize

Serialize L<Struct::Path|Struct::Path> path to perl-style string

    $string = ps_serialize($struct_path);

=cut

sub ps_serialize($) {
    my $path = shift;
    croak "Path must be arrayref" unless (ref $path eq 'ARRAY');

    my $out = '';
    my $sc = 0; # step counter

    for my $step (@{$path}) {
        if (ref $step eq 'ARRAY') {
            $out .= "[";
            $out .= join(",", @{$step}); # TODO: ranges (convert sequences to ranges)
            $out .= "]";
        } elsif (ref $step eq 'HASH') {
            $out .= "{" . join(",", sort { $step->{$a} <=> $step->{$b} } keys %{$step}) . "}";
        } else {
            croak "Unsupported thing in the path (step #$sc)";
        }
    }

    return $out;
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
