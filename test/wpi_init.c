#include <stdio.h>

#include <wiringPi.h>
#include <wiringPiSPI.h>

int main (){
    int ok = mcp3004Setup(400, 0);
    int ret = analogRead(400);
    printf("%d\n", ret);
    return 0;
}
