package RPi::ADC::MCP3008;

use warnings;
use strict;

our $VERSION = '0.01';

BEGIN {

    my @subs = qw(mode spi);

    no strict 'refs';

    for my $sub (@subs) {
        *$sub = sub {
            my ($self, $p) = @_;

            if (defined $p) {
                if ($p != 0 && $p != 1) {
                    if ($sub eq 'mode') {
                        die "$sub param must be either 1 for single-ended mode, ".
                                "or 0 for differential mode\n";
                    }
                    elsif ($sub eq 'spi') {
                        die "$sub param must be either 0 for SPI channel 0, or ".
                                "1 for SPI channel 1.\n";
                    }
                }
                $self->{$sub} = $p;
            }
            return $self->{$sub};
        }
    }
}

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    my $mode = defined $args{mode} ? $args{mode} : 0;
    $self->mode($mode);

    my $spi  = defined $args{spi} ? $args{spi} : 0;
    $self->spi($spi);

    return $self;
}

1;
__END__

=head1 NAME

RPi::ADC::MCP3008 - Interface to the MCP300x analog to digital converters (ADC)
on Raspberry Pi

=head1 DESCRIPTION

Provides access to the MCP300x series analog to digital converters (ADC) on
Raspberry Pi.

Requires L<wiringPi|http://wiringpi.com> to be installed, as well as access to
the C C<pthread> library.

=head1 SYNOPSIS

    use RPi::ADC::MCP3008;

    my $adc = RPi::ADC::MCP3008->new;

    ...

=head1 METHODS

=head2 new

Instantiates and returns a new L<RPi::ADC::MCP3008> object. All parameters are
sent in as a single hash.

Parameters:

    $mode

Optional. Sets the operating mode. C<0> for single-ended mode, or C<1> for
differential mode. See L</OPERATING MODES> for further details.

    $spi

Optional. Sets the SPI channel the ADC is listening on. C<0> for SPI channel 0
(which is the default), and C<1> for SPI channel 1.

=head2 mode

Sets/gets the ADC's operating mode.

Parameters:

    $mode

Optional. C<0> for single-ended mode, or C<1> for differential mode. See
L</OPERATING MODES> for further details.

Return: The currently used mode.

=head2 spi

Sets/gets the SPI channel the ADC is connected to.

Parameters:

    $channel

Optional. C<0> for SPI channel 0 (which is the default), and C<1> for SPI
channel 1.

Return: The currently used SPI channel number.

=head1 TECHNICAL DATA

Both the MCP3004 and MCP3008 are supported. The MCP3004 has four input pins in
single-ended mode and two input channel pairs in differential mode. The MCP3008
has eight inputs in single-ended mode, and four input pairs in differential
mode.

=head2 OPERATING MODES

The MCP300x ADCs have two operating modes, single-ended and differential. In
single-ended mode, the input result is the difference between the analog input
pin and ground. In differential mode, the result will be the difference between
the input pin, and it's corresponding diff pin.

MCP3004 differential pin map:

    Input   Diff against
    --------------------
    1       2
    3       4

MCP3008 differential pin map:

    Input   Diff against
    --------------------
    1       2
    3       4
    5       6
    7       8

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rpi-adc-mcp3008 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RPi-ADC-MCP3008>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of RPi::ADC::MCP3008
