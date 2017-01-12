use strict;
use warnings;

use RPi::ADC::MCP3008;
use Test::More;

my $mod = 'RPi::ADC::MCP3008';

{ # base

    my $o = $mod->new;

    is $o->mode, 0, "mode is 0 by default";
    is $o->mode(1), 1, "mode(1) set ok";

    for (qw(-1 2)){
        my $ok = eval { $o->mode($_); 1; };
        is $ok, undef, "mode() dies with invalid param";
        like $@, qr/mode param must/, "...with ok error";
    }
}
{ # params

    for (0, 1){
        my $o = $mod->new(mode => $_);
        is $o->mode, $_, "mode param $_ set ok";
    }
    for (-1, 2){
        my $ok = eval { $mod->new(mode => $_); 1; };
        is $ok, undef, "new() dies with invalid mode param $_";
        like $@, qr/mode param must/, "...with ok error";
    }
}

done_testing();
