#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>

#include <wiringPi.h>
#include <wiringPiSPI.h>

static int fd;

void load_spi_driver (){
    if (system("gpio load spi") == -1){
        fprintf (stderr, "Can't load the SPI driver: %s\n", strerror (errno)) ;
        exit (EXIT_FAILURE) ;
    }
}

void spi_setup (int spi_channel){
    if ((fd = wiringPiSPISetup(spi_channel, 1000000)) < 0){
        fprintf (stderr, "Can't open the SPI bus: %s\n", strerror (errno)) ;
        exit (EXIT_FAILURE) ;
    }
}

int fetch (int load_spi, int spi, int mode, int input){

    if(load_spi == TRUE){
        loadSpiDriver();
    }

    wiringPiSetup () ;
    spiSetup(spi);

    if(mode == 1){
        // single-ended requires 0x08
        mode = mode << 3;
    }

    if(input < 0 || input > 7){
        return -1;
    }

    // start bit

    unsigned char buffer[3] = {1};

    buffer[1] = (mode + input) << 4;

    wiringPiSPIDataRW(spi, buffer, 3);

    // get the last 10 bits

    return ((buffer[1] & 3) << 8) + buffer[2];
}

MODULE = RPi::ADC::MCP3008  PACKAGE = RPi::ADC::MCP3008

PROTOTYPES: DISABLE

void
load_spi_driver ()
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        load_spi_driver();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
spi_setup (spi_channel)
	int	spi_channel
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        spi_setup(spi_channel);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
fetch (load_spi, spi, mode, input)
	int	load_spi
	int	spi
	int	mode
	int	input

