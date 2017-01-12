use strict;
use warnings;

use RPi::ADC::MCP3008;
use Test::More;

my $mod = 'RPi::ADC::MCP3008';

{ # base
    my $o = $mod->new;

    is ref $o, 'RPi::ADC::MCP3008', "object is in ok class";
}

done_testing();
