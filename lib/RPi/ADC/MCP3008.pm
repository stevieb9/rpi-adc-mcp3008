package RPi::ADC::MCP3008;

use warnings;
use strict;

our $VERSION = '3.1802';

require XSLoader;
XSLoader::load('RPi::ADC::MCP3008', $VERSION);

use RPi::Const qw(:all);
use WiringPi::API qw(:wiringPi);

sub new {
    my ($class, $channel) = @_;

    my $self = bless {}, $class;

    $self->_channel($channel);

    wiringPiSetupGpio();

    my $spi_channel = $channel > 1 ? 0 : $channel;

    wiringPiSPISetup($spi_channel, 1000000);

    # init the CS pin per the datasheet, if
    # we're in bit-bang mode

    if ($self->_channel > 1){
        pinMode($self->_channel, OUTPUT);
        digitalWrite($self->_channel, HIGH);
    }

    return $self;
}
sub raw {
    my ($self, $input) = @_;
    return fetch($self->_channel, $input);
}
sub percent {
    my ($self, $input) = @_;
    my $ret = fetch($self->_channel, $input);
    return sprintf("%.2f", ($ret / 1023) * 100);
}
sub _channel {
    # spi channel

    my ($self, $chan) = @_;

    $self->{channel} = $chan if defined $chan;

    if (! defined $self->{channel}){
        die "\$channel has not been set. Send it into new()\n";
    }

    return $self->{channel};
}
sub DESTROY {
    my ($self) = @_;

    # reset the CS pin if we're in bit-bang mode

    if ($self->_channel > 1){
        digitalWrite($self->_channel, LOW);
        pinMode($self->_channel, INPUT);
    }
}
sub _vim {};

1;
__END__

=head1 NAME

RPi::ADC::MCP3008 - Interface to the MCP3008 analog to digital converter (ADC)
on Raspberry Pi

=head1 DESCRIPTION

Provides access to the 10-bit, 8 channel MCP3008 analog to digital converter over
the SPI bus, on the dedicated hardware SPI channel pins C<CE0> (0) or C<CE1>
(1), or use any GPIO pin for the CS pin and bit-bang the SPI to keep free the
hardware SPI CS pins.

Requires L<wiringPi|http://wiringpi.com> to be installed, as well as access to
the C C<pthread> library.

This library should work equally well with the MCP3002 and MCP3004, although I
have not tested them.

You can review the MCP3008 L<datasheet|https://stevieb9.github.io/rpi-adc-mcp3008/datasheet/MCP3008.pdf> or the L<breadboard layout|https://stevieb9.github.io/rpi-adc-mcp3008/breadboard/mcp3008.jpg>.

=head1 SYNOPSIS

    use RPi::ADC::MCP3008;

    # 0 or 1 for channel use the onboard hardware CE0
    # or CE1 SPI CS pins. Set to any GPIO pin other than
    # 0 or 1 to use that GPIO pin as your CS instead

    my $spi_channel = 0; # built-in CE0
    # $spi_channel = 21; # use GPIO pin 21 as CS instead

    my $adc = RPi::ADC::MCP3008->new($spi_channel);

    my $adc_channel = 0;

    my $r = $adc->raw($adc_channel);

    ...

=head1 METHODS

=head2 new

Instantiates and returns a new L<RPi::ADC::MCP3008> object after initializing
the SPI bus.

Parameters:

    $channel

Mandatory: Integer, the SPI bus channel to communicate over. C<0> for 
C</dev/spidev0.0> or C<1> for C</dev/spidev0.1>. Alternatively, send in any
GPIO pin number (above 1), and we'll use that GPIO pin as the CS pin instead,
freeing up the two hardware SPI channel pins. We do this by bit-banging the
SPI bus in this case.

=head2 raw

Fetch the raw data from the chosen channel as an integer between C<0> - C<1023>

Parameters:

    $adc_channel

Mandatory: Integer, the ADC input channel to read. C<0> - C<7> for
single-ended (channels CH0-CH7), and between C<8> - C<15> for differential. 
See L</CHANNEL SELECT> for full details on all the various options.

=head2 percent

Fetch the input level as a double floating point number percentage.

Parameters:

    $adc_channel

Mandatory: Integer, the ADC input channel to read. C<0> - C<7> for
single-ended (channels CH0-CH7), and between C<8> - C<15> for differential. 
See L</CHANNEL SELECT> for full details on all the various options.

=head1 TECHNICAL DATA

=head2 DEVICE SPECIFICS

    - 10-bit successive-approximation ADC with on-chip sample and hold
    - Eight single-ended inputs, or four pseudo-differential pairs (the
      MCP3004 is the same interface with four inputs/two pairs)
    - Ratiometric against VREF: straight binary, code 1023 = VREF
    - Runs at 2.7-5.5V, so the Pi's 3.3V rail is fine
    - Max SPI clock 3.6MHz at 5V, 1.35MHz at 2.7V; this module clocks
      the bus at 1MHz, within spec at any supply
    - SPI modes 0,0 and 1,1; the CS/SHDN pin frames every conversion
    - 5nA typical standby current, 500uA max active

Wiring to the Pi: VDD (pin 16) and VREF (pin 15) to 3.3V, AGND (pin 14)
and DGND (pin 9) to ground, CLK (pin 13) to SCLK (GPIO 11), DOUT (pin 12)
to MISO (GPIO 9), DIN (pin 11) to MOSI (GPIO 10), and CS/SHDN (pin 10) to
CE0 (GPIO 8) or CE1 (GPIO 7) - or to whatever GPIO you handed L</new> as
the CS. With VREF fed 3.3V, one LSB works out to ~3.2mV.

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

=head2 ON THE WIRE

Every read - L</raw> and L</percent> both funnel into the same C
function, C<fetch()> - is one full-duplex SPI transaction in mode 0,0:
CS drops, three bytes go out on MOSI while three come back on MISO, and
CS rises. At the module's 1MHz clock the 24 data clocks make a frame
roughly 24us long. The chip samples the input mid-frame and answers
before the frame ends.

With a hardware CS (C<new(0)> or C<new(1)>), the kernel SPI driver
asserts CE0/CE1 around the frame automatically. With a GPIO CS
(C<new(2)> and up), the XS drops that GPIO, runs the same frame on
C</dev/spidev0.0>, then raises it - but the hardware CE0 still toggles
alongside, so don't hang a second device off CE0 in that setup.

Here are the three bytes reading single-ended channel 0 (C<raw(0)>,
control nibble C<1000> from the L</CHANNEL SELECT> table):

           +-----------+-----------+-----------+
    MOSI   | 0000 0001 | 1000 xxxx | xxxx xxxx |
           +-----------+-----------+-----------+
             Start bit    SGL/DIFF     Filler
             (the 1)      D2 D1 D0     clocks
                          + filler

           +-----------+-----------+-----------+
    MISO   | ~~~~ ~~~~ | ~~~~ ~0BB | bbbb bbbb |
           +-----------+-----------+-----------+
             High-Z      Null bit    B7..B0
                         then B9 B8

The seven leading zeros ahead of the start bit are what byte-align the
result: the chip treats the first high DIN bit with CS low as the start
bit, reads SGL/DIFF and D2 D1 D0, samples the selected input (the sample
window opens on the D0 clock and closes half-way through the next),
answers with a low null bit, then shifts out B9..B0 MSB-first on falling
clock edges. The XS keeps the bottom two bits of byte 1 and all of
byte 2:

    ((byte1 & 0x03) << 8) | byte2

For example, 1.65V on CH0 with VREF at 3.3V converts to code 512
(C<10 0000 0000>): byte 1 comes back C<xxxx x010>, byte 2 all zeros,
giving C<< (0x02 << 8) | 0x00 >> = 512, which L</percent> reports as
512 / 1023 * 100 = 50.05%.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

