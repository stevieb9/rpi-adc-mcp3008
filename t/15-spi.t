use strict;
use warnings;

use RPi::ADC::MCP3008;
use Test::More;

my $mod = 'RPi::ADC::MCP3008';

{ # base

    my $o = $mod->new;

    is $o->spi, 0, "spi is 0 by default";
    is $o->spi(1), 1, "spi(1) set ok";

    for (qw(-1 2)){
        my $ok = eval { $o->spi($_); 1; };
        is $ok, undef, "spi() dies with invalid param";
        like $@, qr/spi param must/, "...with ok error";
    }
}
{ # params

    for (0, 1){
        my $o = $mod->new(spi => $_);
        is $o->spi, $_, "spi param $_ set ok";
    }
    for (-1, 2){
        my $ok = eval { $mod->new(spi => $_); 1; };
        is $ok, undef, "new() dies with invalid spi param $_";
        like $@, qr/spi param must/, "...with ok error";
    }
}

done_testing();
