#include <stdio.h>
#include "xparameters.h"
#include "xgpio.h"
#include "sleep.h" // Include sleep.h for usleep()

#define GPIO_DEVICE_ID XPAR_AXI_GPIO_0_DEVICE_ID // Assuming AXI GPIO is connected to buttons
#define AXI4_BASEADDR XPAR_LAB1PONG_0_S00_AXI_BASEADDR // Base address of your custom AXI4 IP

#define BUTTON_CHANNEL 1  // Assuming buttons are connected to channel 1 of AXI GPIO

#define UP_BUTTON_MASK_P1 0x01  // Mask for the up button for player 1
#define DOWN_BUTTON_MASK_P1 0x02  // Mask for the down button for player 1
#define UP_BUTTON_MASK_P2 0x04  // Mask for the up button for player 2
#define DOWN_BUTTON_MASK_P2 0x08  // Mask for the down button for player 2

#define PADDLE_UP_CMD_P1 0x01   // Command to move paddle 1 up
#define PADDLE_DOWN_CMD_P1 0x02 // Command to move paddle 1 down
#define PADDLE_UP_CMD_P2 0x04   // Command to move paddle 2 up
#define PADDLE_DOWN_CMD_P2 0x08 // Command to move paddle 2 down

int main() {
    XGpio gpio;
    int status;
    u32 prev_button_state = 0;

    // Initialize GPIO driver
    status = XGpio_Initialize(&gpio, GPIO_DEVICE_ID);
    if (status != XST_SUCCESS) {
        printf("Error initializing GPIO\n");
        return XST_FAILURE;
    }

    // Set GPIO direction for input
    XGpio_SetDataDirection(&gpio, BUTTON_CHANNEL, 0xFFFFFFFF); // All bits as input

    // Initialize variables to track button presses
    int paddle1_up_pressed = 0;
    int paddle1_down_pressed = 0;

    while(1) {
        // Read button state
        u32 button_state = XGpio_DiscreteRead(&gpio, BUTTON_CHANNEL);

        // Read left_edge and P2_leftedge from custom AXI4 IP
        u32 left_edge = Xil_In32(AXI4_BASEADDR + 0x10); // Assuming left_edge is at offset 0x10
        u32 P2_leftedge = Xil_In32(AXI4_BASEADDR + 0x0C); // Assuming P2_leftedge is at offset 0x0C

        // Compare left_edge and P2_leftedge to determine paddle 2 movement direction
        if (P2_leftedge > left_edge) {
            // Move paddle 2 up
            Xil_Out32(AXI4_BASEADDR, PADDLE_UP_CMD_P2);
            printf("Paddle 2 moved up\n");

            // Check if the up button for player 1 is pressed
            if (button_state & UP_BUTTON_MASK_P1) {
                // Move paddle 1 up
                Xil_Out32(AXI4_BASEADDR, PADDLE_UP_CMD_P1);
                printf("Paddle 1 moved up\n");
                paddle1_up_pressed = 1;
            } else if (paddle1_up_pressed) {
                // Stop moving paddle 1 up
                Xil_Out32(AXI4_BASEADDR, 0);
                printf("Paddle 1 stopped\n");
                paddle1_up_pressed = 0;
            }
        } else if (P2_leftedge < left_edge) {
            // Move paddle 2 down
            Xil_Out32(AXI4_BASEADDR, PADDLE_DOWN_CMD_P2);
            printf("Paddle 2 moved down\n");

            // Check if the down button for player 1 is pressed
            if (button_state & DOWN_BUTTON_MASK_P1) {
                // Move paddle 1 down
                Xil_Out32(AXI4_BASEADDR, PADDLE_DOWN_CMD_P1);
                printf("Paddle 1 moved down\n");
                paddle1_down_pressed = 1;
            } else if (paddle1_down_pressed) {
                // Stop moving paddle 1 down
                Xil_Out32(AXI4_BASEADDR, 0);
                printf("Paddle 1 stopped\n");
                paddle1_down_pressed = 0;
            }
        } else {
            // Stop moving paddle 2
            Xil_Out32(AXI4_BASEADDR, 0);
            printf("Paddle 2 stopped\n");

            // Check if the up button for player 1 is pressed
            if (button_state & UP_BUTTON_MASK_P1) {
                // Move paddle 1 up
                Xil_Out32(AXI4_BASEADDR, PADDLE_UP_CMD_P1);
                printf("Paddle 1 moved up\n");
                paddle1_up_pressed = 1;
            } else if (paddle1_up_pressed) {
                // Stop moving paddle 1 up
                Xil_Out32(AXI4_BASEADDR, 0);
                printf("Paddle 1 stopped\n");
                paddle1_up_pressed = 0;
            }

            // Check if the down button for player 1 is pressed
            if (button_state & DOWN_BUTTON_MASK_P1) {
                // Move paddle 1 down
                Xil_Out32(AXI4_BASEADDR, PADDLE_DOWN_CMD_P1);
                printf("Paddle 1 moved down\n");
                paddle1_down_pressed = 1;
            } else if (paddle1_down_pressed) {
                // Stop moving paddle 1 down
                Xil_Out32(AXI4_BASEADDR, 0);
                printf("Paddle 1 stopped\n");
                paddle1_down_pressed = 0;
            }
        }

        // Add a delay to reduce CPU usage
        usleep(10000); // 10ms delay
    }

    return 0;
}
