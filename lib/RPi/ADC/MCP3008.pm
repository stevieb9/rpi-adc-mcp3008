package RPi::ADC::MCP3008;

use warnings;
use strict;

use Carp qw(croak);
use RPi::SPI;

our $VERSION = '3.1802';

# Control nibble (SGL/DIFF + D2-D0) per ADC input param; 0-7 single-ended
# CH0-CH7, 8-15 the differential pairs (see CHANNEL SELECT in the POD)

my @inputs = (
    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
);

sub new {
    my ($class, $channel) = @_;

    my $self = bless {}, $class;

    # RPi::SPI validates $channel (0/1 for hardware CS, above 1 for GPIO
    # CS, or a hashref of bit-bang params), preps the CS pin where
    # applicable, and croaks on anything invalid

    $self->_spi(RPi::SPI->new($channel, 1000000));

    return $self;
}
sub percent {
    my ($self, $input) = @_;

    my $ret = $self->_fetch($input);

    return sprintf("%.2f", ($ret / 1023) * 100);
}
sub raw {
    my ($self, $input) = @_;
    return $self->_fetch($input);
}
sub _fetch {
    my ($self, $input) = @_;

    if (! defined $input || $input !~ /^\d+$/ || $input > 15){
        croak "ADC input channel must be 0-15\n";
    }

    # Start bit, the control nibble atop byte two, then filler clocks for
    # the chip to answer over (see ON THE WIRE in the POD)

    my $buf = [0x01, $inputs[$input] << 4, 0x00];

    my @ret = $self->_spi->rw($buf, 3);

    return (($ret[1] & 0x03) << 8) + $ret[2];
}
sub _spi {
    my ($self, $spi) = @_;

    $self->{spi} = $spi if defined $spi;
    return $self->{spi};
}
sub _vim {};

1;
__END__

=head1 NAME

RPi::ADC::MCP3008 - Interface to the MCP3008 analog to digital converter (ADC)
on Raspberry Pi

=head1 DESCRIPTION

Provides access to the 10-bit, 8 channel MCP3008 analog to digital converter
over the SPI bus, three ways: the dedicated hardware SPI chip select pins
C<CE0> (0) or C<CE1> (1), any GPIO pin as the chip select (leaving the
hardware CE pins free and untouched), or full software bit-bang on arbitrary
GPIO pins. All SPI transport is handled by L<RPi::SPI>.

Requires L<wiringPi|http://wiringpi.com> version 3.18+ to be installed.

This library also works with the MCP3004, the four-channel device sharing
this datasheet (DS21295): it uses the same control-word format as the
MCP3008, and its channel-select bit D2 is a "don't care" (DS21295
Table 5-1), so the same three-byte frame reads its channels CH0-CH3
correctly. I have not tested it on hardware.

The MCP3002 is B<not> supported: it is a separate device (DS21294) whose
control-word format differs from the MCP3004/3008, so this module's frame
does not address it correctly.

You can review the MCP3008 datasheet, bundled with this distribution as F<docs/datasheet/MCP3008.pdf>, or the L<breadboard layout|https://stevieb9.github.io/rpi-adc-mcp3008/breadboard/mcp3008.jpg>.

=head1 SYNOPSIS

    use RPi::ADC::MCP3008;

    # 0 or 1 for channel use the onboard hardware CE0
    # or CE1 SPI CS pins. Set to any GPIO pin above 1
    # to use that GPIO pin as your CS instead, or send
    # in a hashref of RPi::SPI bit-bang params to run
    # the bus entirely in software

    my $spi_channel = 0; # Built-in CE0
    # $spi_channel = 21; # Use GPIO pin 21 as CS instead

    my $adc = RPi::ADC::MCP3008->new($spi_channel);

    my $adc_channel = 0;

    my $r = $adc->raw($adc_channel);

    ...

=head1 METHODS

=head2 new

Instantiates and returns a new L<RPi::ADC::MCP3008> object after initializing
the SPI bus, through L<RPi::SPI>.

Parameters:

    $channel

Mandatory: Integer or hashref.

Integer C<0> for C</dev/spidev0.0> or C<1> for C</dev/spidev0.1>, using the
hardware chip select pins (CE0/CE1). Alternatively, send in any GPIO pin
number above C<1> (BCM numbering), and that pin becomes the chip select
instead, freeing up both hardware CS pins. The transfer still runs on the
hardware SPI engine, and the kernel is told to leave CE0/CE1 untouched
during our transactions, so other devices on the hardware chip selects won't
see spurious selects. Both of these modes clock the bus at 1MHz.

Send in a hashref of L<RPi::SPI> bit-bang params instead to run the whole
bus in software on arbitrary GPIO pins (BCM numbering):

    my $adc = RPi::ADC::MCP3008->new({
        clk   => 21, # To CLK on the chip
        mosi  => 20, # To DIN
        miso  => 19, # To DOUT
        cs    => 26, # To CS/SHDN
        delay => 1,  # Microseconds per clock phase
    });

The MCP3008 needs all four lines wired, and L<RPi::SPI>'s default SPI mode
C<0> is the correct one. Set C<delay> between C<1> and C<50>: at C<1> the
clock tops out at 500kHz, within the chip's spec at any supply voltage, and
past C<50> you risk breaching the datasheet's requirement that all ten data
bits finish within 1.2ms of sampling (accuracy degrades beyond it).

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
      the bus at 1MHz in the hardware modes, within spec at any supply
      (see L</new> for the bit-bang clock guidance)
    - SPI modes 0,0 and 1,1; the CS/SHDN pin frames every conversion
    - 5nA typical standby current, 500uA max active

Wiring to the Pi: VDD (pin 16) and VREF (pin 15) to 3.3V, AGND (pin 14)
and DGND (pin 9) to ground, CLK (pin 13) to SCLK (GPIO 11), DOUT (pin 12)
to MISO (GPIO 9), DIN (pin 11) to MOSI (GPIO 10), and CS/SHDN (pin 10) to
CE0 (GPIO 8) or CE1 (GPIO 7) - or to whatever GPIO you handed L</new> as
the CS. In bit-bang mode, CLK, DOUT and DIN go to your chosen C<clk>,
C<miso> and C<mosi> pins instead. With VREF fed 3.3V, one LSB works out
to ~3.2mV.

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

Every read - L</raw> and L</percent> both funnel into the same private
method - is one full-duplex SPI transaction in mode 0,0: CS drops, three
bytes go out on MOSI while three come back on MISO, and CS rises. At the
hardware modes' 1MHz clock the 24 data clocks make a frame roughly 24us
long. The chip samples the input mid-frame and answers before the frame
ends.

With a hardware CS (C<new(0)> or C<new(1)>), the kernel SPI driver
asserts CE0/CE1 around the frame automatically. With a GPIO CS
(C<new(2)> and up), L<RPi::SPI> sets the kernel's C<SPI_NO_CS> flag,
drops the GPIO, runs the same frame on C</dev/spidev0.0>, raises the
GPIO, then restores the flag - the hardware CE0 pin never moves, so
other devices on the hardware chip selects are left alone. In bit-bang
mode, the identical frame is clocked out entirely in software on your
chosen pins.

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
clock edges. We keep the bottom two bits of byte 1 and all of byte 2:

    ((byte1 & 0x03) << 8) | byte2

For example, 1.65V on CH0 with VREF at 3.3V converts to code 512
(C<10 0000 0000>): byte 1 comes back C<xxxx x010>, byte 2 all zeros,
giving C<< (0x02 << 8) | 0x00 >> = 512, which L</percent> reports as
512 / 1023 * 100 = 50.05%.

=head2 DATASHEET

The Microchip MCP3008 datasheet (DS21295D) is distributed with this
software as F<docs/datasheet/MCP3008.pdf>. It covers the control-word
format, the SPI framing, and the conversion timing this module's stack
implements.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
