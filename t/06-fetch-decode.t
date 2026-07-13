use strict;
use warnings;

use Test::More;
use RPi::ADC::MCP3008;

# HW-free coverage of the read path (frame build, 10-bit decode, percent math)
# by stubbing the _spi seam. We bless a bare object and inject a fake SPI whose
# rw() records the frame it was handed and returns a canned 3-byte reply, so
# new() - which would open the SPI bus - is never called.

{
    package Fake::SPI;
    sub new  { bless { reply => $_[1], last => undef }, $_[0] }
    sub rw {
        my ($self, $buf, $len) = @_;
        $self->{last} = [@$buf];
        return @{ $self->{reply} };
    }
}

# Control nibble per channel, mirrored from the module: 0-7 single-ended
# CH0-CH7 -> 0x08..0x0F; 8-15 the differential pairs -> 0x00..0x07.
my @control = (
    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
);

sub adc_with_reply {
    my ($reply) = @_;
    my $adc = bless {}, 'RPi::ADC::MCP3008';
    $adc->{spi} = Fake::SPI->new($reply);
    return $adc;
}

# --- 10-bit decode: (byte[1] & 0x03) << 8) + byte[2] ---
is adc_with_reply([0x00, 0x02, 0x00])->raw(0), 512,
    'raw(): decode of [_,0x02,0x00] = 512';

is adc_with_reply([0x00, 0x03, 0xFF])->raw(0), 1023,
    'raw(): full-scale decode = 1023';

is adc_with_reply([0x00, 0x00, 0x00])->raw(0), 0,
    'raw(): zero decode = 0';

is adc_with_reply([0xFF, 0xFC, 0x2A])->raw(0), 0x2A,
    'raw(): byte[1] bits above bit 9 masked off, low byte passes';

# --- percent: raw / 1023 * 100, two decimals ---
is adc_with_reply([0x00, 0x02, 0x00])->percent(0), '50.05',
    'percent(): 512/1023*100 = 50.05';

is adc_with_reply([0x00, 0x03, 0xFF])->percent(0), '100.00',
    'percent(): full scale = 100.00';

is adc_with_reply([0x00, 0x00, 0x00])->percent(0), '0.00',
    'percent(): zero = 0.00';

# --- frame build: [0x01, control_nibble << 4, 0x00] per channel ---
for my $ch (0, 1, 7, 8, 15){
    my $adc = adc_with_reply([0x00, 0x00, 0x00]);
    $adc->raw($ch);
    is_deeply $adc->{spi}{last}, [0x01, $control[$ch] << 4, 0x00],
        sprintf('frame build: channel %d control nibble 0x%02X', $ch, $control[$ch]);
}

done_testing();
