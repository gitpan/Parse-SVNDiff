package Parse::SVNDiff;
$Parse::SVNDiff::VERSION = '0.02';

use 5.008;
use bytes;
use strict;
use warnings;

use constant SELECTOR_SOURCE => 0b00;
use constant SELECTOR_TARGET => 0b01;
use constant SELECTOR_NEW    => 0b10;

=head1 NAME

Parse::SVNDiff - Subversion binary diff format parser

=head1 VERSION

This document describes version 0.01 of Parse::SVNDiff, released
November 6, 2004.

=head1 SYNOPSIS

    use Parse::SVNDiff;
    $diff = Parse::SVNDiff->new;
    $diff->parse($raw_svndiff);
    $target_text = $diff->apply($source_text);
    $raw_svndiff = $diff->dump;

=head1 DESCRIPTION

This module implements a parser and a dumper for Subversion's I<svndiff> binary
diff format.  The API is still subject to change in the next few versions.

=cut

sub new {
    my $class = shift;
    return bless([], $class);
}

sub parse {
    my $self = shift;

    my $fh;
    if (UNIVERSAL::isa($_[0] => 'GLOB')) {
        $fh = $_[0];
    }
    else {
        open $fh, '<', \$_[0];
    }
    binmode($fh);

    local $/ = \4;
    <$fh> eq "SVN\0" or die "Svndiff has invalid header";

    @$self = ();
    $self->parse_window($fh) until eof($fh);

    return $self;
}

sub dump {
    my $self = shift;

    "SVN\0" . join '', map {
        my $inst_dump = $self->dump_instructions($_->{instructions});
        pack('w w w w w',
            @{$_}{qw( source_offset source_length target_length )},
            length($inst_dump), length($_->{new_data}),
        ),
        $inst_dump, $_->{new_data},
    } @$self;
}

sub dump_instructions {
    my $self         = shift;
    my $instructions = shift;
    my $dump         = '';

    foreach my $inst (@{$instructions}) {
        if ($inst->{length} >= 0b01000000) {
            $dump .= chr($inst->{selector} << 6) . pack('w', $inst->{length});
        }
        else {
            $dump .= chr(($inst->{selector} << 6) + $inst->{length});
        }

        next if $inst->{selector} == SELECTOR_NEW;
        $dump .= pack('w', $inst->{offset});
    }

    return $dump;
}

sub parse_window {
    my $self = shift;
    my $fh   = shift;

    my $source_offset = $self->parse_ber($fh);
    my $source_length = $self->parse_ber($fh);
    my $target_length = $self->parse_ber($fh);

    my $inst_length = $self->parse_ber($fh);
    my $data_length = $self->parse_ber($fh);

    my $instructions = $self->parse_instructions($fh, $inst_length);

    local $/ = \$data_length;
    my $new_data = <$fh>;

    push @$self, {
        source_offset => $source_offset,
        source_length => $source_length,
        target_length => $target_length,
        new_data      => $new_data,
        instructions  => $instructions,
    };
}

sub parse_instructions {
    my $self = shift;
    my $fh   = shift;
    my $len  = shift;
    my @instructions;

    my $pos = tell($fh);

    local $/ = \1;
    while (<$fh>) {
        my $selector = ord($_) >> 6;
        my $length   = (ord($_) % 0b01000000) || $self->parse_ber($fh);

        push @instructions, { 
            selector => $selector,
            length   => $length,
            offset   => (($selector == 0b10) ? 0 : $self->parse_ber($fh)),
        };

        last if (tell($fh) - $pos) >= $len;
    }

    return \@instructions;
}

sub parse_ber {
    my $self = shift;
    my $fh   = shift;
    my $ber  = '';

    local $/ = \1;
    while (<$fh>) {
        $ber .= $_;
        ord($_) & 0b10000000 or last;
    }

    return unpack('w', $ber);
}

sub apply {
    my $self   = shift;
    my $target = '';

    foreach my $window (@$self) {
        my $data_offset   = 0;
        my $target_offset = length($target);
        my $source_offset = $window->{source_offset};
        foreach my $inst (@{ $window->{instructions} }) {
            if ($inst->{selector} == SELECTOR_SOURCE) {
                $target .= substr(
                    $_[0], ($source_offset + $inst->{offset}), $inst->{length}
                );
            }
            elsif ($inst->{selector} == SELECTOR_TARGET) {
                my $offset   = ($target_offset + $inst->{offset});
                my $overflow = ($inst->{length} - (length($target) - $offset));

                if ($overflow <= 0) {
                    $target .= substr($target, $offset, $inst->{length});
                }
                else {
                    my $chunk = 
                    $target .= substr(
                        substr($target, $offset) x (
                            int($overflow / (length($target) - $offset)) + 1
                        ), 0, $inst->{length}
                    );
                }
            }
            else {
                $target .= substr(
                    $window->{new_data},
                    ($data_offset + $inst->{offset}),
                    $inst->{length},
                );
                $data_offset += $inst->{length};
            }
        }
    }

    return $target;
}

1;

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

