package Struct::Path::PerlStyle;

use 5.010;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';
use utf8;

use Carp 'croak';
use Safe;
use Text::Balanced qw(extract_bracketed extract_quotelike);
use Text::ParseWords 'parse_line';
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
    '{a}{/pattern/mods}'  # regexp keys match (fully supported, except code expressions)
    '{a}{b}[0,1,2,5]'     # 0, 1, 2 and 5 array's items
    '{a}{b}[0..2,5]'      # same, but using ranges
    '{a}{b}[9..0]'        # descending ranges allowed (perl doesn't)
    '{a}{b}(back){c}'     # step back (to previous level)

=head1 SUBROUTINES

=cut

our $ALIASES;

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

my $HASH_KEY_CHARS = qr/[\p{Alnum}_\.\-\+]/;

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


sub _push_hash {
    my ($steps, $text) = @_;
    my ($body, $delim, $mods, %step, $token, $type);

    while ($text) {
        ($token, $text, $type, $delim, $body, $mods) =
            (extract_quotelike($text))[0,1,3,4,5,10];

        if (not defined $delim) { # bareword
            push @{$step{K}}, $token = $1
                if ($text =~ s/^\s*($HASH_KEY_CHARS+)//);
        } elsif (!$type and $delim eq '"') {
            $body =~ s/($INTP)/$INTP{$1}/gs; # interpolate
            push @{$step{K}}, $body;
        } elsif (!$type and $delim eq "'") {
            push @{$step{K}}, $body;
        } elsif ($delim eq '/' and !$type or $type eq 'm') {
            push @{$step{R}}, $RSAFE->reval("qr/$body/$mods", 1);
            if ($@) {
                (my $err = $@) =~ s/ at \(eval \d+\) .+//s;
                croak "Step #" . scalar @{$steps} .
                    ": failed to evaluate regexp: $err";
            }
        } else { # things like qr, qw and so on
            substr($text, 0, 0, $token);
            undef $token;
        }

        croak "Unsupported key '$text', step #" . @{$steps}
            if (!defined $token);

        $text =~ s/^\s+//; # discard trailing spaces

        if ($text ne '') {
            if ($text =~ s/^,//) {
                croak "Trailing delimiter at step #" . @{$steps}
                    if ($text eq '');
            } else {
                croak "Delimiter expected before '$text', step #" . @{$steps};
            }
        }
    }

    push @{$steps}, \%step;
}

sub _push_hook {
    my ($steps, $text) = @_;

    my ($hook, @args) = parse_line(' ', 0, $text);
    my $neg;
    if ($hook eq 'not' or $hook eq '!') {
        $neg = $hook;
        $hook = shift @args;
    } elsif ($hook =~ /^!/) {
        $neg = 1;
        substr $hook, 0, 1, '';
    }

    croak "Unsupported hook '$hook', step #" . @{$steps}
        unless (exists $HOOKS->{$hook});

    $hook = $HOOKS->{$hook}->(@args); # closure with saved args
    push @{$steps}, ($neg ? sub { not $hook->(@_) } : $hook);
}

sub _push_list {
    my ($steps, $text) = @_;
    my (@range, @step);

    for my $i (split /\s*,\s*/, $text, -1) {
        @range = grep {
            croak "Incorrect array index '$i', step #" . @{$steps}
                unless (eval { $_ == int($_) });
        } ($i =~ /^\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*$/) ? ($1, $2) : $i;

        push @step, $range[0] < $range[-1]
            ? $range[0] .. $range[-1]
            : reverse $range[-1] .. $range[0];
    }

    push @{$steps}, \@step;
}

sub str2path($;$) {
    my ($path, $opts) = @_;

    croak "Undefined path passed" unless (defined $path);

    local $ALIASES = $opts->{aliases} if (exists $opts->{aliases});

    my (@steps, $step, $type);

    while ($path) {
        # separated match: to be able to have another brackets inside;
        # currently mostly for hooks, for example: '( $x > $y )'
        for ('{"}', '["]', '(")', '<">') {
            ($step, $path) = extract_bracketed($path, $_, '');
            last if ($step);
        }

        croak "Unsupported thing in the path, step #" . @steps . ": '$path'"
            unless ($step);

        $type = substr $step,  0, 1, ''; # remove leading bracket
                substr $step, -1, 1, ''; # remove trailing bracket

        if ($type eq '{') {
            _push_hash(\@steps, $step);
        } elsif ($type eq '[') {
            _push_list(\@steps, $step);
        } elsif ($type eq '(') {
             _push_hook(\@steps, $step);
        } else { # <>
            if (exists $ALIASES->{$step}) {
                substr $path, 0, 0, $ALIASES->{$step};
                redo;
            }

            croak "Unknown alias '$step'";
        }
    }

    return \@steps;
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
                    unless (eval { int($i) == $i });
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

                    unless ($k =~ /^$HASH_KEY_CHARS+$/) {
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
