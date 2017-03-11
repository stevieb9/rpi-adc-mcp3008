use warnings;
use strict;
use feature 'say';

use RPi::ADC::MCP3008;

my $adc = RPi::ADC::MCP3008->new(0, 21);

say $adc->raw(0x08);
