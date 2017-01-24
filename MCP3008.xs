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

const unsigned char inputs[16] = {
    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, // single-ended
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07  // differential
};

void spi_setup (const int channel){
    if (wiringPiSPISetup(channel, 1000000) < 0){
        printf("can't open the SPI bus: %s\n", strerror(errno)) ;
        exit(errno) ;
    }
}

void wpi_setup () {
    if (wiringPiSetupGpio() < 0){
        printf("failed to load wiringPi: %s\n", strerror(errno)) ;
        exit(errno);
    }
}

int fetch (const int channel, const int cs, const int input){

    if (input < 0 || input > 15){
        croak("ADC input channel must be 0-15\n");
    }

    unsigned char buf[3];

    buf[0] = 0x01; // start bit
    buf[1] = inputs[input];

    digitalWrite(cs, LOW); // start conversation

    wiringPiSPIDataRW(channel, buf, 3);

    digitalWrite(cs, HIGH); // end conversation

    return ((buf[1] & 0x03) << 8) + buf[2]; // last 10 bits
}

MODULE = RPi::ADC::MCP3008  PACKAGE = RPi::ADC::MCP3008

PROTOTYPES: DISABLE

void
spi_setup (channel)
    int channel

void
wpi_setup ()

int
fetch (channel, cs, input)
    int channel
    int cs
    int input
