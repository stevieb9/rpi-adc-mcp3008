use strict;
use warnings;

use Test::More;
use RPi::ADC::MCP3008;

# HW-free: every case fails the ADC input validation before the SPI layer
# is ever touched, so no wiringPi setup or wiring is needed. We never call
# new() (that would open the SPI bus)

my $adc = bless {}, 'RPi::ADC::MCP3008';

for my $method (qw(percent raw)){
    eval { $adc->$method() };
    like $@, qr/input channel must be 0-15/, "$method: missing input croaks";

    eval { $adc->$method('x') };
    like $@, qr/input channel must be 0-15/, "$method: non-integer croaks";

    eval { $adc->$method(-1) };
    like $@, qr/input channel must be 0-15/, "$method: negative input croaks";

    eval { $adc->$method(16) };
    like $@, qr/input channel must be 0-15/, "$method: input above 15 croaks";
}

done_testing();
