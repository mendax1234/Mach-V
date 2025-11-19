#include "oled.h" 
#include <stddef.h> 

void display_done_image(void) {
    // DEFINE POINTERS LOCALLY HERE:
    volatile unsigned int* OLED_COL_ADDR = (volatile unsigned int*) (MMIO_BASE + OLED_COL_OFF);
    volatile unsigned int* OLED_ROW_ADDR = (volatile unsigned int*) (MMIO_BASE + OLED_ROW_OFF);
    volatile unsigned int* OLED_DATA_ADDR = (volatile unsigned int*) (MMIO_BASE + OLED_DATA_OFF);
    volatile unsigned int* OLED_CTRL_ADDR = (volatile unsigned int*) (MMIO_BASE + OLED_CTRL_OFF);

    // 1. Set the initial cursor position (Top-Left corner: Col 0, Row 0)
    *OLED_COL_ADDR = 0;
    *OLED_ROW_ADDR = 0;
    
    // 2. Set the control register for raster image loading
    *OLED_CTRL_ADDR = OLED_CTRL_RASTER_MODE;
    
    // 3. Stream the image data
    for (size_t i = 0; i < IMAGE_SIZE; i++) {
        *OLED_DATA_ADDR = done_image_data[i];
    }
}