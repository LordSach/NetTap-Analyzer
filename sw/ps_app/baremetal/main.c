#include "xparameters.h"
#include <stdio.h>


int main() {
init_platform();
xil_printf("NetTap Analyzer bare-metal boot.\n");
cleanup_platform();
return 0;
}
