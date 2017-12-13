package Struct::Path::PerlStyle;

use 5.010;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Carp 'croak';
use PPI;
use Safe;
use Scalar::Util 'looks_like_number';
use re qw(is_regexp regexp_pattern);

our @EXPORT_OK = qw(
    path2str
    str2path
);

=encoding utf8

=head1 NAME

Struct::Path::PerlStyle - Perl-style syntax frontend for L<Struct::Path|Struct::Path>.

=begin html

<a href="https://travis-ci.org/mr-mixas/Struct-Path-PerlStyle.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Path-PerlStyle.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Path-PerlStyle.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Path-PerlStyle.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Path-PerlStyle"><img src="https://badge.fury.io/pl/Struct-Path-PerlStyle.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.80

=cut

our $VERSION = '0.80';

=head1 SYNOPSIS

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

=head1 EXPORT

Nothing is exported by default.

=head1 PATH SYNTAX

Examples:

    '{a}{b}'              # points to b's value
    '{a}{}'               # all values from a's subhash; same for arrays (using empty square brackets)
    '{a}{b,c}'            # b's and c's values
    '{a}{"space inside"}' # key must be quoted unless it is a simple word (single quotes supported as well)
    '{a}{"multi\nline"}'  # same for special characters (if double quoted)
    '{a}{"π"}'            # keys containing non ASCII characters also must be quoted*
    '{a}{/pattern/mods}'  # regexp keys match (fully supported, except code expressions)
    '{a}{b}[0,1,2,5]'     # 0, 1, 2 and 5 array's items
    '{a}{b}[0..2,5]'      # same, but using ranges
    '{a}{b}[9..0]'        # descending ranges allowed (perl doesn't)
    '{a}{b}(back){c}'     # step back (to previous level)

    * at least until https://github.com/adamkennedy/PPI/issues/168

=head1 SUBROUTINES

=cut

our $HOOKS = {
    'back' => sub { # step back $count times
        my $static = defined $_[0] ? $_[0] : 1;
        return sub {
            my $count = $static; # keep arg (reusable closure)
            while ($count) {
                croak "Can't step back (root of the structure)"
                    unless (@{$_[0]} and @{$_[1]});
                pop @{$_[0]};
                pop @{$_[1]};
                $count--;
            }
            return 1;
        };
    },
    '=~' => sub {
        croak "Only one arg accepted by '=~'" if (@_ != 1);
        my $arg = shift;
        return sub {
            return (defined ${$_[1]->[-1]} and ${$_[1]->[-1]} =~ $arg) ? 1 : 0;
        }
    },
    'defined' => sub {
        croak "no args accepted by 'defined'" if (@_);
        return sub { return defined (${$_[1]->[-1]}) ? 1 : 0 }
    },
    'eq' => sub {
        croak "Only one arg accepted by 'eq'" if (@_ != 1);
        my $arg = shift;
        return sub {
            return (defined ${$_[1]->[-1]} and ${$_[1]->[-1]} eq $arg) ? 1 : 0;
        };
    },
};

$HOOKS->{'<<'} = $HOOKS->{back}; # backward compatibility ('<<' is deprecated)

my %ESCP = (
    '\\' => '\\\\', # single => double
    '"'  => '\"',
    "\a" => '\a',
    "\b" => '\b',
    "\t" => '\t',
    "\n" => '\n',
    "\f" => '\f',
    "\r" => '\r',
    "\e" => '\e',
);
my $ESCP = join('', sort keys %ESCP);

my %INTP = map { $ESCP{$_} => $_ } keys %ESCP; # swap keys <-> values
my $INTP = join('|', map { "\Q$_\E" } sort keys %INTP);

my $RSAFE = Safe->new;
$RSAFE->permit_only(
    'const',
    'lineseq',
    'qr',
    'leaveeval',
    'rv2gv',
    'padany',
);

=head2 str2path

Convert perl-style string to L<Struct::Path|Struct::Path> path structure

    $struct = str2path($string);

=cut

sub str2path($;$);
sub str2path($;$) {
    my ($path, $opts) = @_;

    croak "Undefined path passed" unless (defined $path);
    my $doc = PPI::Document->new(ref $path ? $path : \$path);
    croak "Failed to parse passed path '$path'" unless (defined $doc);
    my @out;

    for my $step (map { $_->can('elements') ? $_->elements : $_ } $doc->elements) {
        $step->prune('PPI::Token::Whitespace') if $step->can('prune');

        if ($step->isa('PPI::Structure') and $step->start eq '{' and $step->finish) {
            push @out, {};
            for my $t (map { $_->elements } $step->children) {
                if ($t->isa('PPI::Token::Word') or $t->isa('PPI::Token::Number')) {
                    push @{$out[-1]->{K}}, $t->content;
                } elsif ($t->isa('PPI::Token::Operator') and $t eq ',') {
                    ;
                } elsif ($t->isa('PPI::Token::Quote::Single')) {
                    push @{$out[-1]->{K}}, $t->literal;
                } elsif ($t->isa('PPI::Token::Quote::Double')) {
                    push @{$out[-1]->{K}}, $t->string;
                    $out[-1]->{K}->[-1] =~ s/($INTP)/$INTP{$1}/gs; # interpolate
                } elsif (
                    $t->isa('PPI::Token::Regexp::Match') or
                    $t->isa('PPI::Token::QuoteLike::Regexp')
                ) {
                    push @{$out[-1]->{R}}, $RSAFE->reval(
                        'qr/' . $t->get_match_string . '/' .
                        join('', keys %{$t->get_modifiers}), 1
                    );
                    if ($@) {
                        (my $err = $@) =~ s/ at \(eval \d+\) .+//s;
                        croak "Step #$#out: failed to evaluate regexp: $err";
                    }
                } else {
                    croak "Unsupported thing '$t' for hash key, step #$#out";
                }
            }
        } elsif ($step->isa('PPI::Structure') and $step->start eq '[' and $step->finish) {
            push @out, [];
            my $range;
            for my $t (map { $_->elements } $step->children) {
                if ($t->isa('PPI::Token::Number')) {
                    croak "Incorrect array index '$t', step #$#out"
                        unless ($t->content == int($t));
                    if (defined $range) {
                        push @{$out[-1]},
                            ($range < $t->content ? $range .. $t : reverse $t .. $range);
                        $range = undef;
                    } else {
                        push @{$out[-1]}, int($t);
                    }
                } elsif ($t->isa('PPI::Token::Operator') and $t eq ',') {
                    ;
                } elsif ($t->isa('PPI::Token::Operator') and $t eq '..') {
                    $range = pop(@{$out[-1]});
                    croak "Range start absent, step #$#out"
                        unless (defined $range);
                } else {
                    croak "Unsupported thing '$t' for array index, step #$#out";
                }
            }
            croak "Unfinished range secified, step #$#out" if ($range);
        } elsif ($step->isa('PPI::Structure') and $step->start eq '(' and $step->finish) {
            my ($hook, @args) = map { $_->elements } $step->children;
            my $neg;
            if ($hook eq 'not' or $hook eq '!') {
                $neg = $hook;
                $hook = shift @args;
            }
            croak "Unsupported thing '$hook' as hook, step #" . @out
                unless ($hook->isa('PPI::Token::Operator') or $hook->isa('PPI::Token::Word'));
            croak "Unsupported hook '$hook', step #" . @out
                unless (exists $HOOKS->{$hook});
            @args = map {
                if ($_->isa('PPI::Token::Quote::Single') or $_->isa('PPI::Token::Number')) {
                    $_->literal;
                } elsif ($_->isa('PPI::Token::Quote::Double')) {
                    $_->string;
                } else {
                    croak "Unsupported thing '$_' as hook argument, step #" . @out;
                }
            } @args;
            $hook = $HOOKS->{$hook}->(@args); # closure with saved args
            push @out, ($neg ? sub { not $hook->(@_) } : $hook);
        } elsif ($step->isa('PPI::Token::Symbol') and $step->raw_type eq '$') {
            my $name = substr($step, 1); # cut off sigil
            croak "Unknown alias '$name'" unless (exists $opts->{aliases}->{$name});
            push @out, @{str2path($opts->{aliases}->{$name}, $opts)};
        } else {
            croak "Unsupported thing '$step' in the path, step #" . @out;
        }
    }

    return \@out;
}

=head2 path2str

Convert L<Struct::Path|Struct::Path> path structure to perl-style string

    $string = path2str($struct);

=cut

sub path2str($) {
    my $path = shift;

    croak "Arrayref expected for path" unless (ref $path eq 'ARRAY');
    my $out = '';
    my $sc = 0; # step counter

    for my $step (@{$path}) {
        my @items;

        if (ref $step eq 'ARRAY') {
            for my $i (@{$step}) {
                croak "Incorrect array index '" . ($i // 'undef') . "', step #$sc"
                    unless (looks_like_number($i) and int($i) == $i);
                if (@items and (
                    $items[-1][0] < $i and $items[-1][-1] == $i - 1 or   # ascending
                    $items[-1][0] > $i and $items[-1][-1] == $i + 1      # descending
                )) {
                    $items[-1][1] = $i; # update range
                } else {
                    push @items, [$i]; # new range
                }
            }

            for (@{items}) {
                $_ = abs($_->[0] - $_->[-1]) < 2
                    ? join(',', @{$_})
                    : "$_->[0]..$_->[-1]"
            }

            $out .= "[" . join(",", @{items}) . "]";
        } elsif (ref $step eq 'HASH') {
            my $types = [ grep { exists $step->{$_} } qw(K R) ];
            if (keys %{$step} != @{$types}) {
                $types = { map { $_, 1 } @{$types} };
                my @errs = grep { !exists $types->{$_} } sort keys %{$step};
                croak "Unsupported hash definition (" .
                    join(',', @errs) . "), step #$sc"
            }

            if (exists $step->{K}) {
                croak "Unsupported hash keys definition, step #$sc"
                    unless (ref $step->{K} eq 'ARRAY');

                for my $k (@{$step->{K}}) {
                    croak "Unsupported hash key type 'undef', step #$sc"
                        unless (defined $k);
                    croak "Unsupported hash key type '@{[ref $k]}', step #$sc"
                        if (ref $k);

                    push @items, $k;

                    unless (looks_like_number($k) or $k =~ /^[0-9a-zA-Z_]+$/) {
                        # \w doesn't fit -- PPI can't parse unquoted utf8 hash keys
                        # https://github.com/adamkennedy/PPI/issues/168#issuecomment-180506979
                        $items[-1] =~ s/([\Q$ESCP\E])/$ESCP{$1}/gs;    # escape
                        $items[-1] = qq("$items[-1]");                 # quote
                    }
                }
            }

            if (exists $step->{R}) {
                croak "Unsupported hash regexps definition, step #$sc"
                    unless (ref $step->{R} eq 'ARRAY');

                for my $r (@{$step->{R}}) {
                    croak "Regexp expected for regexps item, step #$sc"
                        unless (is_regexp($r));

                    my ($patt, $mods) = regexp_pattern($r);
                    $patt =~ s|/|\\/|g;
                    push @items, "/$patt/$mods";
                }
            }

            $out .= "{" . join(",", @items) . "}";
        } else {
            croak "Unsupported thing in the path, step #$sc";
        }
        $sc++;
    }

    return $out;
}

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-struct-path-perlstyle at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-PerlStyle>. I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

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

L<Struct::Path>, L<Struct::Diff>, L<perldsc>, L<perldata>

=head1 LICENSE AND COPYRIGHT

Copyright 2016,2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path::PerlStyle
