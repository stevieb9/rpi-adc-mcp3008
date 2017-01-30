package RPi::ADC::MCP3008;

use warnings;
use strict;

our $VERSION = '2.36.1';

require XSLoader;
XSLoader::load('RPi::ADC::MCP3008', $VERSION);

use RPi::WiringPi::Constant qw(:all);
use WiringPi::API qw(:wiringPi);

sub new {
    my ($class, $channel, $cs) = @_;

    my $self = bless {}, $class;

    $self->_channel($channel);
    $self->_cs($cs);

    spi_setup($self->_channel);
    wpi_setup();

    # init the CS pin per the datasheet

    pinMode($self->_cs, OUTPUT);
    digitalWrite($self->_cs, HIGH);

    return $self;
}
sub raw {
    my ($self, $input) = @_;
    return fetch($self->_channel, $self->_cs, $input);
}
sub _channel {
    # spi channel

    my ($self, $chan) = @_;

    if (defined $chan && ($chan != 0 && $chan != 1)){
        die "\$channel param must be 0 or 1\n";
    }

    $self->{channel} = $chan if defined $chan;

    if (! defined $self->{channel}){
        die "\$channel has not been set. Send it into new()\n";
    }

    return $self->{channel};
}
sub _cs {
    # chip select GPIO pin

    my ($self, $cs) = @_;

    if (defined $cs && ($cs < 0 || $cs > 63)){
        die "\$cs param must be a valid GPIO pin number\n";
    }

    $self->{cs} = $cs if defined $cs;

    if (! defined $self->{cs}){
        die "\$cs pin has not been set. Send it into new()\n";
    }

    return $self->{cs};
}
sub DESTROY {
    my ($self) = @_;

    digitalWrite($self->_cs, LOW);
    pinMode($self->_cs, INPUT);
}
sub _vim {};

1;
__END__

=head1 NAME

RPi::ADC::MCP3008 - Interface to the MCP3008 analog to digital converter (ADC)
on Raspberry Pi

=head1 DESCRIPTION

Provides access to the 10-bit, 8 channel MCP3008 analog to digital converter over
the SPI bus.

Requires L<wiringPi|http://wiringpi.com> to be installed, as well as access to
the C C<pthread> library.

=head1 SYNOPSIS

    use RPi::ADC::MCP3008;

    my $spi_channel = 0;
    my $cs = 18;

    my $adc = RPi::ADC::MCP3008->new($spi_channel, $cs);

    my $adc_input = 0;

    my $r = $adc->raw($adc_input);

    ...

=head1 METHODS

=head2 new

Instantiates and returns a new L<RPi::ADC::MCP3008> object after initializing
the SPI bus.

Parameters:

    $channel

Mandatory: Integer, the SPI bus channel to communicate over. C<0> for 
C</dev/spidev0.0> or C<1> for C</dev/spidev0.1>.

    $cs

Mandatory: Integer, the GPIO pin number on the RPi that connects to the C<CS>
pin on the ADC. This pin is used to start and complete communication with the
ADC.

=head2 raw

Fetch the raw data from the chosen channel.

Parameters:

    $input

Mandatory: Integer, the ADC input channel to read. C<0> - C<7> for
single-ended (channels CH0-CH7), and between C<8> - C<15> for differential. 
See L</CHANNEL SELECT> for full details on all the various options.

=head1 TECHNICAL DATA

=head2 CHANNEL SELECT

The MCP3008 allows both single-ended and differential modes of operation.
Single-ended means read the difference of voltage between a single pin and Gnd.
Double-ended means the difference in voltage between two input pins. Here's a
table explaining the various options, and their parameter value. The left-most
bit represents the mode. C<1> for single-ended, and C<0> for differential:

    Param   Bits    Dec     Hex     ADC Channel
    -------------------------------------------

    0       1000    8       0x08    CH0
    1       1001    9       0x09    CH1
    2       1010    10      0x0A    CH2
    3       1011    11      0x0B    CH3
    4       1100    12      0x0C    CH4
    5       1101    13      0x0D    CH5
    6       1110    14      0x0E    CH6
    7       1111    15      0X0F    CH7

    8       0000    0       0x00    CH0+ | CH1-
    9       0001    1       0x01    CH0- | CH1+
    10      0010    2       0x02    CH2+ | CH3-
    11      0011    3       0x03    CH2- | CH3+
    12      0100    4       0x04    CH4+ | CH5-
    13      0101    5       0x05    CH4- | CH5+
    14      0110    6       0x06    CH6+ | CH7-
    15      0111    7       0x07    CH6- | CH7+

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

