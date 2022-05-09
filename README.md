## Overview
This project uses memory-mapped IO (MMIO) to implement of a basic version of the arcade game Frogger in the MIPS assembly language.

## How to Play
The goal of the game is to use the WASD input keys to move the frog into either of the two designated goal areas at the other side of the board. You must avoid getting hit by cars and falling into the water, as well as avoid colliding with the spiders on the logs and the alligators that randomly cover the goal area.

To run the program, execute the following steps:
  1. Assemble the program by clicking Run > Assemble
  2. Set up the display by clicking Tools > Bitmap Display
  3. Configure the display:
    - Set Unit Width in Pixles to 8
    - Set Unit Height in Pixels to 8
    - Set Display Width in Pixels to 256
    - Set Display Height in Pixels to 258
    - Set Base Address for Display to 0x10008000 ($gp)
    - Click Connect to MIPS
  4. Set up the keyboard simulator by clicking Tools > Keyboard and Display MMIO Simulator, and then clicking Connect to MIPS on the simulator window that appears
  5. Run the program by clicking Run > Go

To terminate the program while it is still executing, click Run > Stop to ensure the program quits safely.
