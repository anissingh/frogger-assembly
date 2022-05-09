#####################################################################
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#####################################################################
.data
displayAddress: .word 0x10008000
waterColour: .word 0x0066cc
safeColour: .word 0xffdd99
roadColour: .word 0x4d4d4d
red: .word 0xff0000
green: .word 0x00ff00
blue: .word 0x0000ff
white: .word 0xffffff
black: .word 0x000000

frogColour: .word 0xff00ff
frogWinColour: .word 0xffff00
logColour: .word 0xbf8040
goalColour: .word 0x004d00
nonValidGoalColour: .word 0x1a1100
gameOverMsgColour: .word 0x23fa8f
alligatorColour: .word 0x006600
frogDeathColour: .word 0xff9900

roadRowOne: .space 512
roadRowTwo: .space 512
waterRowOne: .space 512
waterRowTwo: .space 512
boardNoFrog: .space 4096
goalRow: .space 512
displayBuffer: .space 4096

frog_x: .word 14
frog_y: .word 28
frog_facing: .word 3

road_r1_y: .word 20
road_r2_y: .word 24

car_1_r1_x: .word 0
car_2_r1_x: .word 16
car_1_r2_x: .word 2
car_2_r2_x: .word 18

water_r1_y: .word 8
water_r2_y: .word 12

log_1_r1_x: .word 0
log_2_r1_x: .word 16
log_1_r2_x: .word 2
log_2_r2_x: .word 18

alligator_x: .word 0
alligator_y: .word 4

goal_1_x: .word 8
goal_2_x: .word 20

object_width: .word 8

update_objects_r_timer: .word 23
update_objects_l_timer: .word 14
board_updated_right: .word 0
board_updated_left: .word 0
collision_occurred_log_right: .word 0
collision_occurred_log_left: .word 0

log_1_colour_collisions: .word 0xbf8041
log_2_colour_collisions: .word 0xbf8042

frog_lives: .word 5
.text
main:
	# Initialize static parts of boardNoFrog
	jal initialize_static_board_no_frog
	
	# Initialize default (static) goal area pixels
	jal initialize_default_goal_area_pixels
	
	# Central processing game loop
	game_loop:
	
	###################################################################
	# Decide if leftmost x values of right-moving objects need updating
	###################################################################
	# Move a right-moving object
	lw $t0, update_objects_r_timer # load value of update_objects_r_timer into $t0
	beq $t0, 23, update_r_objects # branch to update the right-moving object positions if update_objects_r_timer == 23
	# If we make it here, we don't need to update right-moving object positions
	# We didn't update the board here, so set board_updated_right = 0
	la $t0, board_updated_right # set $t0 to address of board_updated_right
	sw $zero, 0($t0) # set board_updated_right = 0
	j check_update_l_objects # jump to see if we need to update left objects
	
	
	###################################################################
	# Update leftmost x values of right-moving objects
	###################################################################
	update_r_objects:
	# First set board_updated_right = 1
	la $t0, board_updated_right # set $t0 to address of board_updated_right
	addi $t1, $zero, 1 # set $t1 = 1
	sw $t1, 0($t0) # set board_updated_right = 1
	
	# Next set update_objects_r_timer back to 0
	la $t0, update_objects_r_timer # set $t0 to address of update_objects_r_timer
	sw $zero, 0($t0) # set update_objects_r_timer to 0
	
	# Move frog if frog is on a right-moving log
	addi $a3, $zero, 1 # set $a3 = 1 to signify checking right-moving logs
	jal handle_frog_on_log
	la $t0, collision_occurred_log_right # load address of collision_occurred_log_right into $t0
	sw $v0, 0($t0) # store the return value of the function in this variable (1 if frog collided with edge of
		       # screen due to log pushing it (so a collision occurred), 0 otherwise)
	
	# Update right object positions by moving them for each row
	addi $a3, $zero, 1 # set $a3 to 1 to signify to update right-moving objects
	jal update_obj_positions
	
	# Update alligator position
	jal update_alligator_pos
	
	# Jump to checking if we need to update left-moving objects
	j check_update_l_objects # (not necessary, but nice to have for consistency)


	###################################################################
	# Decide if leftmost x values of left-moving objects need updating
	###################################################################
	check_update_l_objects:
	# Move a left-moving object ~ 4/3 x speed of right-moving objects
	lw $t0, update_objects_l_timer # load value of update_objects_l_timer into $t0
	beq $t0, 14, update_l_objects # branch to update the left-moving object positions if update_objects_r_timer == 14
	# If we make it here, we don't need to update left-moving object positions
	# Set board_updated_left = 0
	la $t0, board_updated_left # set $t0 to address of board_updated_left
	sw $zero, 0($t0) # set board_updated_left = 0
	j update_screen # jump to updating screen
	
	
	###################################################################
	# Update leftmost x values of left-moving objects
	###################################################################
	update_l_objects:
	# First set board_updated_left = 1
	la $t0, board_updated_left # set $t0 to address of board_updated_left
	addi $t1, $zero, 1 # set $t1 = 1
	sw $t1, 0($t0) # set board_updated_left = 1
	
	# Next set update_objects_l_timer back to 0
	la $t0, update_objects_l_timer # set $t0 to address of update_objects_l_timer
	sw $zero, 0($t0) # set update_objects_l_timer to 0
	
	# Move frog if frog is on a left-moving log
	xor $a3, $a3, $a3 # set $a3 = 0 to signify checking left-moving logs
	jal handle_frog_on_log
	la $t0, collision_occurred_log_left # load address of collision_occurred_log_left into $t0
	sw $v0, 0($t0) # store the return value of the function in this variable (1 if frog collided with edge of
		       # screen due to log pushing it (so a collision occurred), 0 otherwise)
	
	# Update left object positions by moving them for each row
	xor $a3, $a3, $a3 # set $a3 to 0 to signify to update left-moving objects
	jal update_obj_positions
	
	j update_screen # jump to updating screen (not necessary here)
	
	
	###################################################################
	# Beginning of updating the screen to display changes
	###################################################################
	update_screen:
	# Check if objects were moved on board
	lw $t0, board_updated_right
	lw $t1, board_updated_left
	or $t0, $t0, $t1 # set $t0 = 1 iff right moving or left moving objects were updated
	beq $t0, 1, update_board_objects # branch to update board objects if objects were moved
	# If we make it here, no objects were moved, so jump to drawing screen and frog
	j draw_screen_and_frog
	
	###################################################################
	# Update objects if they were moved
	###################################################################
	update_board_objects:
	# Update allocated memory space for pixel values
	# Road Row 1
	la $a0, roadRowOne # load address of memory
	lw $a1, roadColour # load background colour
	lw $a2, red # load object colour
	xor $a3, $a3, $a3 # set $a3 to 0 to signify to use road row 1 values
	
	# Update values
	jal update_pixel_vals
	
	# Road Row 2
	la $a0, roadRowTwo # load address of memory
	lw $a1, roadColour # load background colour
	lw $a2, red # load object colour
	addi $a3, $zero, 1 # set $a3 to 1 to signify to use road row 2 values
	
	# Update values
	jal update_pixel_vals
	
	# Water Row 1
	la $a0, waterRowOne # load address of memory
	lw $a1, waterColour # load background colour
	lw $a2, logColour # load object colour
	addi $a3, $zero, 2 # set $a3 to 2 to signify to use water row 1 values
	
	# Update values
	jal update_pixel_vals
	
	# Water Row 2
	la $a0, waterRowTwo # load address of memory
	lw $a1, waterColour # load background colour
	lw $a2, logColour # load object colour
	addi $a3, $zero, 3 # set $a3 to 3 to signify to use water row 2 values
	
	# Update values
	jal update_pixel_vals
	
	# Goal row 1
	jal update_pixels_goal_area # Update memory values
	
	j draw_screen_and_frog # jump to drawing screen and frog (not necessary here)
	
	
	###################################################################
	# Draw screen and frog
	###################################################################
	draw_screen_and_frog:
	# Draw screen
	jal draw_board
	
	lw $t0, collision_occurred_log_right # load value of collion_occurred_log_right into $t0
	lw $t1, collision_occurred_log_left # load value of collision_occurred_log_left into $t1
	or $t0, $t0, $t1 # set $t0 = 1 iff a frog collided with a log
	beq $t0, 1, collision_occurred # branch to handle a collision if frog collided with edge of screen due to
				       # log pushing it
	# Note: Did not just branch immediately after function call so the board could be updated without the
	# frog on it. This is consistent with other collisions, which are handled below, so when the game
	# undergoes the frog respawn delay upon a frog death, the frog is not on the screen
	
	###################################################################
	# Win detection
	###################################################################
	jal check_frog_win
	
	###################################################################
	# Collision detection with objects that kill frog
	###################################################################
	# Handle collisions with a car
	lw $a3, red # load the car colour as a function parameter
	jal handle_collisions
	beq $v0, 1, collision_occurred # branch to collision_occurred if handle_collisions returns 1
	
	# Handle collisions with water
	lw $a3, waterColour # load the water colour as a function parameter
	jal handle_collisions
	beq $v0, 1, collision_occurred # branch to collision_occurred if handle_collisions returns 1
	
	# Handle collisions with non-valid goal areas
	lw $a3, nonValidGoalColour
	jal handle_collisions
	beq $v0, 1, collision_occurred # branch to collision_occurred if handle_collisions returns 1
	
	# Handle collisions with alligators
	lw $a3, alligatorColour
	jal handle_collisions
	beq $v0, 1, collision_occurred # branch to collision_occurred if handle_collisions returns 1
	
	# Handle collisions with spiders
	lw $a3, black
	jal handle_collisions
	beq $v0, 1, collision_occurred # branch to collision_occurred if handle_collisions returns 1
	
	# If we make it here, no collision occurred, so collisions have finished being handled
	j collision_handled # jump to end of collision handling
	
	
	###################################################################
	# Collision occurred
	###################################################################
	collision_occurred:
	# If we had a collision, decrement frog lives by 1
	la $t0, frog_lives # load address of frog_lives into $t0
	lw $t1, frog_lives # load value of frog_lives into $t1
	addi $t1, $t1, -1 # subtract 1 from value of frog_lives
	sw $t1 0($t0) # store this new value into memory location of frog_lives
	
	# Death animation
	# Draw frog death colour
	lw $a3, frogDeathColour
	jal draw_player_frog
	jal write_buffer
	# Sleep
	li $v0, 32 # syscall for sleep
	li $a0, 250 # 150ms = ~0.25s
	syscall
	# Draw screen and write buffer to screen
	jal draw_board
	jal write_buffer
	# Sleep
	li $v0, 32 # syscall for sleep
	li $a0, 250 # 150ms = ~0.25s
	syscall
	# Draw frog death colour
	lw $a3, frogDeathColour
	jal draw_player_frog
	jal write_buffer
	# Sleep
	li $v0, 32 # syscall for sleep
	li $a0, 250 # 250ms = ~0.25s
	syscall
	# Draw screen and write buffer to screen
	jal draw_board
	jal write_buffer
	# Sleep
	li $v0, 32 # syscall for sleep
	li $a0, 250 # 250ms = ~0.25s
	syscall
	
	# Sleep for a second to give a basic respawn animation
	li $v0, 32 # syscall for sleep
	li $a0, 1000 # 1000ms = 1s
	syscall
	
	# End game if frog died
	lw $t1, frog_lives # load value of frog_lives back into $t1
	beqz $t1, game_ended # branch to game_ended if frog_lives == 0
	
	# Need to reset collision_occurred_log_left and _right because it is only updated when objects move,
	# so it will likely still say the frog is colliding with a log when it isn't the log collisions just 
	# haven't been checked again
	la $t0, collision_occurred_log_right # load memory location for collision_occurred_log_right
	sw $zero, 0($t0) # set collision_occurred_log_right to 0
	la $t0, collision_occurred_log_left # load memory location for collision_occurred_log_left
	sw $zero, 0($t0) # set collision_occurred_log_left to 0
	
	# Update frog_x and frog_y to starting position
	la $t4, frog_x # load frog_x address into $t4
	addi $t5, $zero, 14 # set frog_x new value = 14 
	sw $t5, 0($t4) # write this new value to frog_x
	la $t4, frog_y # load frog_y address into $t4
	addi $t5, $zero, 28 # set frog_y new value = 28
	sw $t5, 0($t4) # write this new value to frog_y
	
	# Set frog to be front facing
	la $t4, frog_facing # load memory address of frog_facing
	addi $t5, $zero, 3 # set $t5 = 3
	sw $t5, 0($t4) # set frog_facing = 3 (which represents forward)
	
	# Clear any previous keystrokes
	la $t8, 0xffff0000 # load memory location storing whether or not keyboard input occurred
	sw $zero, 0($t8) # set to 0 to signify no keyboard input
	
	##################################################################
	# Any potential collisions have been handled
	##################################################################
	collision_handled:
	
	# Draw frog
	lw $a3, frogColour
	jal draw_player_frog
	
	# Handle keystrokes
	jal handle_keystrokes
	
	# Write display buffer to screen
	jal write_buffer
	
	# Sleep ~60 times every second 500 / 17 = 29.4117 ~ 29
	li $v0, 32
	li $a0, 17 # 1000 / 60 = 16.66667 ~ 17
	lw $t0, update_objects_r_timer # load value of update_objects_r_timer into $t0
	la $t1, update_objects_r_timer # load address of update_objects_r_timer into $t1
	addi $t0, $t0, 1 # add 1 to update_objects_r_timer value
	sw $t0, 0($t1) # store this updated value in update_objects_r_timer
	lw $t0, update_objects_l_timer # load value of update_objects_l_timer into $t0
	la $t1, update_objects_l_timer # load address of update_objects_l_timer into $t1
	addi $t0, $t0, 1 # add 1 to update_objects_l_timer value
	sw $t0, 0($t1) # store this updated value in update_objects_l_timer
	syscall
	
	j game_loop # jump to start of game loop

	game_ended:
	jal draw_game_over_screen # draw game over screen
	jal handle_game_over # wait for the user to type y/n and update values appropriately
			     # if user wishes to restart game
	beq $v0, 1, Exit # Branch to exit if the user wished to quit the game
	# If we make it here, the user wanted to retry, so jump to start of game loop
	j game_loop

	Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
	

# Draw board function
draw_board:
	##########################################
	# Draw blank game state display area
	##########################################
	# Load function arguments to draw blank display area
	li $a0, 32
	li $a1, 4
	la $a2, displayBuffer
	lw $a3, green
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	##########################################
	# Draw frog lives remaining
	##########################################
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw lives
	jal draw_frog_lives
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	##########################################
	# Draw goal area
	##########################################
	# Load function arguments to draw goal row
	li $a0, 32
	li $a1, 4
	la $a2, displayBuffer
	addi $a2, $a2, 512 # translate starting memory location to start of goal area
	la $a3, goalRow
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw row one of water
	jal draw_rect_mem
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	##########################################
	# Draw water row one
	##########################################
	# Load function arguments to draw row one of water
	li $a0, 32
	li $a1, 4
	la $a2, displayBuffer
	addi $a2, $a2, 1024 # translate to start of water row one
	la $a3, waterRowOne
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw row one of water
	jal draw_rect_mem
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	##########################################
	# Draw water row two
	##########################################
	# Load function arguments to draw row two of water
	li $a0, 32
	li $a1, 4
	la $a2, displayBuffer
	addi $a2, $a2, 1536 # translate to start of water row two
	la $a3, waterRowTwo
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw row two of water
	jal draw_rect_mem
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	##########################################
	# Draw safe zone
	##########################################
	# Load function arguments to draw safe zone
	li $a0, 32
	li $a1, 4
	la $a2, displayBuffer
	addi $a2, $a2, 2048 # translate to start of safe zone
	lw $a3, safeColour
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw safe zone
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer

	##########################################
	# Draw road row one
	##########################################
	# Load function arguments to draw row one of road
	li $a0, 32
	li $a1, 4
	la $a2, displayBuffer
	addi $a2, $a2, 2560 # translate to start of road row one
	la $a3, roadRowOne
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw row one of road
	jal draw_rect_mem
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	##########################################
	# Draw road row two
	##########################################
	# Load function arguments to draw row two of road
	li $a0, 32
	li $a1, 4
	la $a2, displayBuffer
	addi $a2, $a2, 3072 # translate to start of road row two
	la $a3, roadRowTwo
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw row two of road
	jal draw_rect_mem
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	##########################################
	# Draw start area
	##########################################
	# Load function arguments to draw start area
	li $a0, 32
	li $a1, 4
	la $a2, displayBuffer
	addi $a2, $a2, 3584 # translate to start of start area
	lw $a3, green
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw start area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Draw spider on log 2 row 2
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	jal draw_spider_log_2_r2
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Draw spider on log 1 row 1
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	jal draw_spider_log_1_r1
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	jr $ra # return

# Draw player frog function
# Function uses: $s0, $s1, $s2, $s3, $s4
# Paramater: $a3 -> colour of frog
draw_player_frog:
	move $s0, $a3 # store frog colour in $s0
	# Call function to calculate leftmost pixel of frog
	lw $a0, frog_x # load function argument for x position
	lw $a1, frog_y # load function argument for y position
	la $a2, displayBuffer # load function argument for board address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function
	jal convert_xy_to_pixel
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Draw frog
	# $s1 represents starting address to draw from frog
	move $a0, $v0 # set $a0 to the return value of the function (start address to draw frog at)
	move $a3, $s0 # set $a3 to frog colour
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function
	jal draw_frog
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	jr $ra # return


# Function that draws a frog
# Parameters: $a0 = starting address to draw frog at, $a3 = frog colour
draw_frog:
	#frog facing direction: 0 = right, 1 = backwards, 2 = left, 3 = straight
	move $s0, $a3 # store frog colour in $s0
	# $s1 represents current pixel to draw from frog
	move $s1, $a0 # set $s0 to the starting address to draw frog at
	lw $s2, frog_facing # get direction of frog
	beq $s2, 0, draw_frog_facing_right # branch to draw frog facing right
	beq $s2, 1, draw_frog_facing_backwards # branch to draw frog facing backwards
	beq $s2, 2, draw_frog_facing_left # branch to draw frog facing left
	# If we make it here, frog_facing = 3, so draw frog facing straight
	sw $s0, 0($s1) # paint top-left pixel of frog's left hand
	addi $s1, $s1, 128 # go to next row
	sw $s0, 0($s1) # paint second pixel of frog's left hand
	addi $s1, $s1, 128 # 
	addi $s1, $s1, 128 # go down 2 rows
	sw $s0, 0($s1) # paint leftmost pixel of frog's base
	addi $s1, $s1, 4 # go right one pixel
	sw $s0, 0($s1) # paint second pixel of frog's base
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 4 # go right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's base
	addi $s1, $s1, 4 # go right one pixel
	sw $s0, 0($s1) # paint last pixel of frog's base
	addi $s1, $s1, -128 # 
	addi $s1, $s1, -128 # go up 2 rows
	sw $s0, 0($s1) # paint a pixel of frog's right arm
	addi $s1, $s1, -128 # 
	sw $s0, 0($s1) # paint top-right pixel of frog (top pixel of right arm)
	j draw_frog_return # jump to return
	
	draw_frog_facing_right:
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -124 # go up one row and right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -124 # go up one row and right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 4 # go right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -384 # go up 3 rows
	sw $s0, 0($s1) # paint a pixel of frog's body
	j draw_frog_return # jump to return
	
	draw_frog_facing_backwards:
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 256 # go down two rows
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -124 # go up one row and right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 4 # go right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 4 # go right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -384 # go up 3 rows
	sw $s0, 0($s1) # paint a pixel of frog's body
	j draw_frog_return # jump to return
	
	draw_frog_facing_left:
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 384 # go down three rows
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 4 # go right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 132 # go down one row and right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 128 # go down one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, 132 # go down one row and right one pixel
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	addi $s1, $s1, -128 # go up one row
	sw $s0, 0($s1) # paint a pixel of frog's body
	j draw_frog_return # jump to return
	
	draw_frog_return:
	jr $ra # return

# Function to update pixel values in memory for rows with objects moving
# Parameters: $a0 = start address of allocated memory, $a1 = background colour, $a2 = object colour,
#	      $a3 = row being updated (0 = road row 1, 1 = road row 2, 2 = water row 1, 3 = water row 2,
#		    4 = goal row)
update_pixel_vals:
	# Register values:
	# $a0 -> start address allocated memory, will be used as current address to write
	# 	 pixel colour to
	# $a1 -> background colour
	# $a2 -> object colour
	# $a3 -> row being updated (values specified above)
	# $t0 -> inner loop variable i
	# $t1 -> inner loop end condition
	# $t2 -> outer loop variable j
	# $t3 -> outer loop end condition
	# $t4 -> object 1 leftmost x position - 1 
	# $t5 -> object 2 leftmost x position - 1
	# $t6 -> object 1 rightmost x position + 1
	# $t7 -> object 2 rightmost x position + 1
	# $t8 -> if condition checker
	# $t9 -> if condition checker
	# $s0 -> if condition checker for $a3
	# $s1 -> if condition checker for wrapping right occurring
	# $s2 -> stores result of wrapping for object 1
	# $s3 -> stores result of wrapping for object 2
	# $s4 -> stores the value 31 (used for computing leftmost x position in left wrapping)
	# $s5 -> start address of allocated memory to boardNoFrog relative to section of board being
	# 	 updated, will be used as current address to write pixel colour to
	# $s6 -> value to colour boardNoFrog pixel
	la $s5, boardNoFrog # load boardNoFrog memory address into $s5
	xor $s0, $s0, $s0 # set $s0 to 0
	addi $s1, $zero, 24 # wrapping right happening if x_leftmost - 1 > 24, so set $s1 to 24
	addi $s4, $zero, 31 # set $s4 to 31
	beq $a3, $s0 load_road_row_one # branch to load values from road row one if $a3 == 0
	addi $s0, $s0, 1 # set $s0 to 1
	beq $a3, $s0 load_road_row_two # branch to load values from road row two if $a3 == 1
	addi $s0, $s0, 1 # set $s0 to 2
	beq $a3, $s0 load_water_row_one # branch to load values from water row one if $a3 == 2
	# If we make it here, we must have had $a0 == 3, so load values from water row 2 and check
	# for wrapping right
	lw $t4, log_1_r2_x
	lw $t5, log_2_r2_x
	lw $s6, log_2_colour_collisions
	addi $s5, $s5, 1536 # 1536 = 32 x 8 x 4 (goal area) + 32 x 4 x 4 (water row 1)
	j set_values_wrappping_right # jump to next instructions after loading values
	
	load_road_row_one:
	# Load values from road row one and check for wrapping left
	lw $t4, car_1_r1_x
	lw $t5, car_2_r1_x
	lw $s6, red
	addi $s5, $s5, 2560 # 2560 = 32 x 8 x 4 (goal area) + 32 x 8 x 4 (water area) + 32 x 4 x 4 (safe zone)
	j set_values_wrappping_left # jump to next instructions after loading values
	
	load_road_row_two:
	# Load values from road row two and check for wrapping right
	lw $t4, car_1_r2_x
	lw $t5, car_2_r2_x
	lw $s6, red
	addi $s5, $s5, 3072 # 3072 = 32 x 8 x 4 (goal area) + 32 x 8 x 4 (water area) + 32 x 4 x 4 (safe zone) 
			    #        + 32 x 4 x 4 (road row one)
	j set_values_wrappping_right # jump to next instructions after loading values
	
	load_water_row_one:
	# Load values from road row two and check for wrapping left
	lw $t4, log_1_r1_x
	lw $t5, log_2_r1_x
	lw $s6, log_1_colour_collisions
	addi $s5, $s5, 1024 # 1024 = 32 x 8 x 4 (goal area)
	j set_values_wrappping_left # jump to next instructions after loading values
	
	# Set values if wrappping right is a possibility
	set_values_wrappping_right:
	
	# Set object leftmost to object leftmost - 1
	addi $t4, $t4, -1 # set $t4 to obj_1_x_leftmost - 1
	addi $t5, $t5, -1 # set $t5 to obj_2_x_leftmost - 1
	
	# Set object rightmost values
	
	# Check if wrapping is happening with object 1
	# Wrapping is happening iff x_leftmost >= 25 <=> x_leftmost - 1 > 24
	slt $s2, $s1, $t4 # sets $s2 to 1 sets $s2 to 1 iff 23 < x_leftmost - 1 (iff wrapping is happening)
	addi $s2, $s2, -1 # sets $s2 to 0 iff wrapping is happening (-1 if it is not)
	beqz $s2, update_rightmost_x_obj1 # branch to update rightmost x pos of object 1 if wrapping is happening
	# If we make it here, no wrapping is happening, so set rightmost x position + 1 of object 1
	addi $t6, $t4, 9 # add leftmost x position of object 1 - 1 + width to $t6 (obj 1 rightmost x position) + 1
	# addi $t6, $t6, 1 # add 1 to object 1 rightmost x position 
	j end_set_rightmost_obj1 # jump to next set of instructions
	
	update_rightmost_x_obj1:
	# If wrapping is happening, the rightmost x position is leftmost_x_position - 24
	# So rightmost x position + 1 = leftmost_x_position - 23
	addi $t6, $t4, -23 # set $t6 to leftmost_x_position - 1 - 22
	j end_set_rightmost_obj1 # jump to next set of instructions (not necessary)
	
	end_set_rightmost_obj1:
	
	# Check if wrapping is happening with object 2
	slt $s3, $s1, $t5 # sets $s2 to 1 iff 23 < x_leftmost - 1 (iff wrapping is happening)
	addi $s3, $s3, -1 # sets $s2 to 0 iff wrapping is happening (-1 if it is not)
	beqz $s3, update_rightmost_x_obj2 # branch to update rightmost x pos of object 2 if wrapping is happening
	# If we make it here, no wrapping is happening, so set rightmost x position + 1 of object 1
	addi $t7, $t5, 9 # add leftmost x position of object 2 - 1 + width to $t7 (obj 2 rightmost x position) + 1
	# addi $t7, $t7, 1 # add 1 to object 2 rightmost x position 
	j end_set_rightmost_obj2 # jump to next set of instructions
	
	update_rightmost_x_obj2:
	# If wrapping is happening, the rightmost x position is leftmost_x_position - 24
	# So rightmost x position + 1 = leftmost_x_position - 23
	addi $t7, $t5, -23 # set $t6 to leftmost_x_position - 1 - 22
	j end_set_rightmost_obj2 # jump to next set of instructions (not necessary)
	
	end_set_rightmost_obj2:	
	j pixel_loop_setup # jump to pixel loop setup
	
	# Set values if wrapping left is a possibility
	# Wrapping left is occuring iff x_leftmost < 0 iff x_leftmost - 1 < -1
	
	set_values_wrappping_left:
	
	# Set object rightmost values + 1 to object leftmost + object width + 1
	addi $t6, $t4, 8 # set $t6 to obj_1_x_leftmost + 8 (object width) + 1
	addi $t7, $t5, 8 # set $t5 to obj_2_x_leftmost + 8 (object width) + 1
	
	# Set object leftmost values
	
	# Check if wrapping is happening with object 1
	# Wrapping is happening iff x_leftmost < 0
	slt $s2, $t4, $zero # sets $s2 to 1 iff x_leftmost < 0 (iff wrapping is happening)
	addi $s2, $s2, -1 # sets $s2 to 0 iff wrapping is happening (-1 if it is not)
	beqz $s2, update_leftmost_x_obj1 # branch to update leftmost x pos of object 1 if wrapping is happening
	# If we make it here, no wrapping is happening, so set leftmost x position - 1 normally
	addi $t4, $t4, -1 # leftmost position of x - 1 = leftmost position of x ($t4) - 1
	j end_set_leftmost_obj1 # jump to next set of instructions
	
	update_leftmost_x_obj1:
	# If wrapping is happening, the leftmost x position is 32 - |leftmost_x_position| = 32 + leftmost_x_position
	# So leftmost x position - 1 = 32 + leftmost_x_position - 1 = 31 + leftmost_x_position
	add $t4, $s4, $t4 # set $t4 to 31 + leftmost_x_position
	j end_set_leftmost_obj1 # jump to next set of instructions (not necessary)
	
	end_set_leftmost_obj1:
	
	# Check if wrapping is happening with object 2
	
	slt $s3, $t5, $zero # sets $s3 to 1 iff x_leftmost < 0 (iff wrapping is happening)
	addi $s3, $s3, -1 # sets $s3 to 0 iff wrapping is happening (-1 if it is not)
	beqz $s3, update_leftmost_x_obj2 # branch to update leftmost x pos of object 2 if wrapping is happening
	# If we make it here, no wrapping is happening, so set leftmost x position - 1 normally
	addi $t5, $t5, -1 # leftmost position of x - 1 = leftmost position of x ($t4) - 1
	j end_set_leftmost_obj2 # jump to next set of instructions
	
	update_leftmost_x_obj2:
	# If wrapping is happening, the leftmost x position is 32 - |leftmost_x_position| = 32 + leftmost_x_position
	# So leftmost x position - 1 = 32 + leftmost_x_position - 1 = 31 + leftmost_x_position
	add $t5, $s4, $t5 # set $t5 to 31 + leftmost_x_position
	j end_set_leftmost_obj2 # jump to next set of instructions (not necessary)
	
	end_set_leftmost_obj2:
	
	j pixel_loop_setup # jump to pixel loop setup (not necessary)
	
	pixel_loop_setup:
	
	# Set up loop variables
	xor $t0, $t0, $t0 # $i = 0
	addi $t1, $zero, 32 # $t1 = 32
	xor $t2, $t2, $t2 # j = 0
	addi $t3, $zero, 4 # $t3 = 4
	
	pixel_outer_loop: # for (int j = 0; j < 4 (# of rows of pixels); j++)
	beq $t2, $t3, pixel_outer_loop_end # branch to pixel_outer_loop_end if j == 4
	
	pixel_inner_loop: # for (int i = 0; i < 32 (# of pixels in each row); i++)
	beq $t0, $t1, pixel_inner_loop_end # branch to pixel_inner_loop_end if i == 32
	
	# If wrapping is happening:
	# Perform check: if x_leftmost <= curr_x OR curr_x <= x_rightmost (wrapped)
	# equivalent to: if x_leftmost - 1 < curr_x OR curr_x < x_rightmost + 1 (wrapped)
	
	# If no wrapping is happening:
	# Perform check: if x_leftmost <= curr_x <= x_leftmost + object_width
	# equivalent to: if x_leftmost - 1 < curr_x < x_leftmost + 1
	
	# Perform appropriate checks
	# Check if curr_x (i) is in the range of object 1
	slt $t8, $t4, $t0 # if x_leftmost <= curr_x, set $t8 to 1
	slt $t9, $t0, $t6 # if curr_x <= x_rightmost, set $t9 to 1
	beqz $s2 wrapping_obj_1 # handle using wrappping conditions if necessary
	# No wrapping conditions:
	and $t8, $t8, $t9 # sets $t8 to 1 iff both $t8 and $t9 were 1 (so both if conditions were true)
	j end_checks_obj_1 # jump to end of checks
	
	# Wrapping conditions:
	wrapping_obj_1:
	or $t8, $t8, $t9 # sets $t8 to 1 iff $t8 or $t9 were 1 (so either if condition was true)
	j end_checks_obj_1 # jump to end of checks (not necessary)
	
	end_checks_obj_1:
	addi $t8, $t8, -1 # sets $t8 to 0 if curr_x in correct range, -1 if it is not
	beqz $t8, set_obj_colour # branch to set object colour if curr_x in range of object 1
	
	# Check if curr_x (i) is in the range of object 2
	slt $t8, $t5, $t0 # if x_leftmost <= curr_x, set $t8 to 1
	slt $t9, $t0, $t7 # if curr_x <= x_rightmost, set $t9 to 1
	beqz $s3 wrapping_obj_2 # handle using wrapping conditions if necessary
	# No wrapping conditions
	and $t8, $t8, $t9 # sets $t8 to 1 iff both $t8 and $t9 were 1 (so both if conditions were true)
	j end_checks_obj_2 # jump to end of checks
	
	# Wrapping conditions:
	wrapping_obj_2:
	or $t8, $t8, $t9 # sets $t8 to 1 iff $t8 or $t9 were 1 (so either if condition was true)
	j end_checks_obj_2 # jump to end of checks (not necessary)
	
	end_checks_obj_2:
	addi $t8, $t8, -1 # sets $t8 to 0 if curr_x in correct range, -1 if it is not
	beqz $t8, set_obj_colour # branch to set object colour if curr_x in range of object 2
	
	# If we are still here, the pixel is not in range of either object, so draw background colour
	sw $a1, 0($a0) # colour current pixel the background colour (specified by $a1)
	sw $a1, 0($s5) # colour current pixel of boardNoFrog the background colour
	j colour_set # jump to colour_set so we don't overwrite colour value
	
	set_obj_colour: # colour of object and not background
	sw $a2, 0($a0) # colour current pixel the object colour (specified by $a2)
	sw $s6, 0($s5) # colour current pixel of boardNoFrog the object colour (specified by $s6)
	j colour_set # jump to colour_set (this instruction is not necessary, but nice to keep consistency)
	
	colour_set:
	addi $a0, $a0, 4 # current pixel to write to += 4
	addi $s5, $s5, 4 # current pixel to write to of boardNoFrog += 4
	addi $t0, $t0, 1 # i++
	j pixel_inner_loop # jump back to start of inner loop
	
	pixel_inner_loop_end:
	xor $t0, $t0, $t0 # set i back to 0 
	
	addi $t2, $t2, 1 # j++
	j pixel_outer_loop # jump back to start of outer loop
	pixel_outer_loop_end:
	
	jr $ra #return
	

# Rectangle drawing function
# Parameters: $a0 = x pixels to draw, $a1 = y pixels to draw, $a2 = top-left pixel
# of rectangle, $a3 = colour of rectangle
# Registers Used: $t4, $t5, $t6, $t7, $t8
draw_rect:
	# Register values
	# $a0 -> x pixels to draw
	# $a1 -> y pixels to draw
	# $a2 -> top-left pixel of rectangle, will be updated to be current location
	# 	 to draw at
	# $a3 -> colour of rectangle
	# $t5 -> loop variable i (inner loop variable)
	# $t6 -> loop variable j (outer loop variable)
	
	# Zero out potential values in registers
	xor $t5, $t5, $t5
	xor $t6, $t6, $t6
	xor $t7, $t7, $t7
	
	# Draw rectangle
	# $a2 stores location in memory that we start drawing at (writing to)
	draw_loop_outer: # for (int j = 0; j < # of y pixels to draw ($a1); j++)
	beq $t6, $a1, draw_loop_outer_end # branch if j == # of y pixels to draw
	xor $t5, $t5, $t5 # i = 0
	draw_loop_inner: # for (int i = 0; i < # of x pixels to draw; i++)
	beq $t5, $a0, draw_loop_inner_end # branch if i == # of x pixels to draw
	
	sw $a3, 0($a2) # draw the given colour ($a3) into the address stored in $a2
	
	addi $a2, $a2, 4 # current location to draw at += 4 (go to next pixel)
	addi $t7, $t7, -4 # $t7 -= 4
	addi $t5, $t5, 1 # i++
	j draw_loop_inner # jump back to start of inner loop
	
	draw_loop_inner_end:
	add $a2, $a2, $t7 # Reset current location to its original value 
	addi $a2, $a2, 128 # Move current location down a row
	xor $t7, $t7, $t7 # Reset $t7
	
	addi $t6, $t6, 1 # j++
	j draw_loop_outer # jump back to start of outer loop
	draw_loop_outer_end:
	
	jr $ra # return


# Rectangle drawing function where colour comes from memory
# Parameters: $a0 = x pixels to draw, $a1 = y pixels to draw, $a2 = top-left pixel
# of rectangle, $a3 = starting memory address of colour of pixels
draw_rect_mem:
	# Register values
	# $a0 -> x pixels to draw
	# $a1 -> y pixels to draw
	# $a2 -> top-left pixel of rectangle, will be updated to be current location
	# 	 to draw at
	# $a3 -> starting memory address of colour of pixels
	# $t5 -> loop variable i (inner loop variable)
	# $t6 -> loop variable j (outer loop variable)
	# $t7 -> value stored in address of $a3
	
	# Zero out potential values in registers
	xor $t5, $t5, $t5
	xor $t6, $t6, $t6 
	
	# Draw rectangle
	# $a2 stores location in memory that we start drawing at (writing to)
	draw_mem_loop_outer: # for (int j = 0; j < # of y pixels to draw ($a1); j++)
	beq $t6, $a1, draw_mem_loop_outer_end # branch if j == # of y pixels to draw
	xor $t5, $t5, $t5 # i = 0
	draw_mem_loop_inner: # for (int i = 0; i < # of x pixels to draw; i++)
	beq $t5, $a0, draw_mem_loop_inner_end # branch if i == # of x pixels to draw
	
	lw $t7, 0($a3) # load the colour stored in $a3 into $t7
	sw $t7, 0($a2) # draw the given colour ($t7) into the address stored in $a2
	
	addi $a2, $a2, 4 # current location to draw at += 4 (go to next pixel)
	addi $a3, $a3, 4 # current address of colour += 4 (go to next pixel colour)
	addi $t5, $t5, 1 # i++
	j draw_mem_loop_inner # jump back to start of inner loop
	draw_mem_loop_inner_end:
	
	addi $t6, $t6, 1 # j++
	j draw_mem_loop_outer # jump back to start of outer loop
	draw_mem_loop_outer_end:
	
	jr $ra # return

# Function to object positions by moving them 2 pixels forward (direction is relative to object)
# $a3 = update left-moving objects (0) or right-moving objects (1)
update_obj_positions:
	# Registers used
	# $a0 -> row being updated (0 = road row 1, 1 = road row 2, 2 = water row 1, 3 = water row 2)
	# $t0 -> object 1 x address
	# $t1 -> object 2 x address
	# $t2 -> used to update x addresses of object 1
	# $t3 -> used in if statement to check for resetting x left position(return value of slt)
	# $t4 -> used in if statement to check for resetting x left position in right-moving objects
	# $t5 -> used in if statement to check for resetting x left position in left-moving objects
	# $t6 -> stores the value of 24. used for resetting x left position on left-moving objects
	# $t7 -> used to update x address of object 2
	# $s0 -> used as an if condition checker for $a3
	
	# Bottom row objects move right
	# Top row objects move left
	
	# Set $t4 to 31 so we can check if we need to reset on right-moving objects
	addi $t4, $zero, 31
	# Set $t5 to -7 so we can check if we need to reset on left-moving objects
	addi $t5, $zero, -7
	# Set $t6 to 24 so we can reset the x position of left-moving objects if necessary
	addi $t6, $zero, 24
	
	# Determine which objects to update
	beq $a3, $zero, move_left # update left-moving objects if $a3 = 0
	# If we get here, $a3 = 1
	j move_right # update right-moving objects
	
	move_right:
	# Load log row 2 values into registers
	la $t0, log_1_r2_x
	la $t1, log_2_r2_x
	lw $t2, log_1_r2_x
	lw $t7, log_2_r2_x
	
	# Move objects right
	move $a0, $t2 # set $a0 = object 1 leftmost x position
	move $a1, $t0 # set $a1 = object 1 leftmost x position memory address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to update object 1 x position
	jal update_rightmoving
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	move $a0, $t7 # set $a0 = object 2 leftmost x position
	move $a1, $t1 # set $a1 = object 2 leftmost x position memory address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to update object 1 x position
	jal update_rightmoving
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	# Load car row 2 values into registers
	la $t0, car_1_r2_x
	la $t1, car_2_r2_x
	lw $t2, car_1_r2_x
	lw $t7, car_2_r2_x
	
	# Move objects right
	move $a0, $t2 # set $a0 = object 1 leftmost x position
	move $a1, $t0 # set $a1 = object 1 leftmost x position memory address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to update object 1 x position
	jal update_rightmoving
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	move $a0, $t7 # set $a0 = object 2 leftmost x position
	move $a1, $t1 # set $a1 = object 2 leftmost x position memory address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to update object 1 x position
	jal update_rightmoving
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	j end_moving # jump to instructions after moving is done
	
	# Update left-moving objects
	move_left:
	# Load values from log row one
	la $t0, log_1_r1_x
	la $t1, log_2_r1_x
	lw $t2, log_1_r1_x
	lw $t7, log_2_r1_x
	
	# Move objects left
	move $a0, $t2 # set $a0 = object 1 leftmost x position
	move $a1, $t0 # set $a1 = object 1 leftmost x position memory address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to update object 1 x position
	jal update_leftmoving
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	move $a0, $t7 # set $a0 = object 2 leftmost x position
	move $a1, $t1 # set $a1 = object 2 leftmost x position memory address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to update object 1 x position
	jal update_leftmoving
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	# Load values from car row one
	la $t0, car_1_r1_x
	la $t1, car_2_r1_x
	lw $t2, car_1_r1_x
	lw $t7, car_2_r1_x
	
	# Move objects left
	move $a0, $t2 # set $a0 = object 1 leftmost x position
	move $a1, $t0 # set $a1 = object 1 leftmost x position memory address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to update object 1 x position
	jal update_leftmoving
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	move $a0, $t7 # set $a0 = object 2 leftmost x position
	move $a1, $t1 # set $a1 = object 2 leftmost x position memory address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to update object 1 x position
	jal update_leftmoving
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	j end_moving # jump to instructions after moving is complete (not necessary)
	
	end_moving:
	jr $ra #return


# Function to handle updating values to move objects right. Handles wrapping.
# Parameters: $a0 = current leftmost x position of object, $a1 = memory address of leftmost x position
#	      of object
update_rightmoving:
	# Set $t4 to 31 so we can check if we need to reset on right-moving objects
	addi $t4, $zero, 31
	
	move $t2, $a0 # move current leftmost x position of object into $t2
	move $t0, $a1 # move memory address of object leftmost x position into $t0
	addi $t2, $t2, 2 # move object forward 2 pixels
	
	slt $t3, $t4, $t2 # if leftmost_x_value >= 32 <=> leftmost_x_value > 31
	addi $t3, $t3, -1 # $t3 = 0 iff leftmost_x_val >= 32 (so we need to reset), otherwise -1
	beqz $t3 reset_x_pos_rightmoving
	# If we get here, no need for resetting
	sw $t2, 0($t0) # store this new x value in car_1_r2_x
	j updated_x_pos_rightmoving # jump to next instructions
	
	reset_x_pos_rightmoving:
	sw $zero, 0($t0) # store 0 to reset its value
	j updated_x_pos_rightmoving # jump to next instructions (not necessary)
	
	updated_x_pos_rightmoving:
	jr $ra # return


# Function to handle updating values to move objects left. Handles wrapping.
# Parameters: $a0 = current leftmost x position of object, $a1 = memory address of leftmost x position
#	      of object
update_leftmoving:
	# Need to reset iff leftmost_x <= -8 <=> leftmost_x < -7
	addi $t6, $zero, 24 # set $t6 = 24 in case we need to reset on wrapping
	# Set $t5 to -6 so we can check if we need to reset on left-moving objects
	addi $t5, $zero, -6
	
	move $t2, $a0 # move current leftmost x position of object into $t2
	move $t0, $a1 # move memory address of object leftmost x position into $t0
	addi $t2, $t2, -2 # move it up 2 pixels

	slt $t3, $t2, $t5 # if leftmost_x <= -8
	addi $t3, $t3, -1 # $t3 = 0 iff leftmost_x <= 8 iff we need to reset x position
	beqz $t3, reset_x_pos_leftmoving
	# If we get here, no need to reset the x position
	sw $t2, 0($t0) # store this new value in memory
	j updated_x_pos_leftmoving # jump to next instructions
	
	reset_x_pos_leftmoving:
	# Reset value
	sw $t6, 0($t0) # reset x position to 24 (because we are wrapping left)
	j updated_x_pos_leftmoving # jump to next instructions (not necessary)
	
	updated_x_pos_leftmoving:
	jr $ra # return
	

# Function to handle keystrokes from player
handle_keystrokes:
	# Register values
	# $t0 -> initalliy stroes value in if key pressed address, then stores value of key prssed if a key
	# 	 was pressed
	# $t1 -> stores if key pressed address
	# $t2 -> if used, stores frog x address
	# $t3 -> if used, stores frog y address
	# $t4 -> if used, stores frog x value
	# $t5 -> if used, stores frog y value
	# $t6 -> if used, stores frog_facing address
	# $t7 -> if used, used to update frog_facing value
	lw $t0, 0xffff0000 # load the value storing if a key was just pressed into $t8
	la $t1, 0xffff0000 # load the value of the memory address into $t1
	beq $t0, 1, keyboard_input # handle keyboard input if one happened
	j end_handle_keystrokes # jump to end of function because there was no input if we reach here
	
	keyboard_input: # Handle keyboard input if it happened
	la $t2, frog_x # store frog_x address into $t2
	la $t3, frog_y # store frog_y address into $t3
	lw $t4, frog_x # store frog_x value into $t4
	lw $t5, frog_y # store frog_x value into $t5
	
	lw $t0, 0xffff0004 # load the value of the key pressed into $t0
	beq $t0, 0x61, respond_to_a # branch to respond to a if key pressed was a
	beq $t0, 0x64, respond_to_d # branch to respond to d if key pressed was d 
	beq $t0, 0x77, respond_to_w # branch to respond to w if key pressed was w
	beq $t0, 0x73, respond_to_s # branch to respond to s if key pressed was s
	# If we make it here, none of the keys we care about were pressed, so just
	# jump to the end response handler
	j end_response_handler # jump to the end of the keyboard response handler
	
	# Respond to s
	respond_to_s:
	# s being pressed moves frog down, so update frog_y -> frog_y + 2
	# frog also faces backwards now (even if it can't actually move in this direction)
	la $t6, frog_facing # load address for frog_facing into $t6
	addi $t7, $zero, 1 # set $t7 equal to frog_facing value for facing backwards
	sw $t7, 0($t6) # set frog_facing = 1
	# Frog can't move right if its bottommost y position is already 31, so check this first
	# Note: frog's bottommost y position is 31 iff upmost y position is 28
	beq $t5, 28, dont_update_frog_pos
	# If bottommost y position is not 31 (meaning it is < 31), perform updates
	addi $t5, $t5, 2 # frog_y_val+=2
	sw $t5, 0($t3) # store the new y value of the frog in frog_y
	# Note: frog is drawn on next iteration of game loop, so don't draw it here
	
	j end_response_handler # jump to the end of the keyboard response handler
	
	# Respond to w
	respond_to_w:
	# w being pressed moves frog up, so update frog_y -> frog_y - 2
	# frog also faces forwards now (even if it can't actually move in this direction)
	la $t6, frog_facing # load address for frog_facing into $t6
	addi $t7, $zero, 3 # set $t7 equal to frog_facing value for facing forwards
	sw $t7, 0($t6) # set frog_facing = 3
	# Frog can't move right if its upmost y position is already 0, so check this first
	beq $t5, 0, dont_update_frog_pos
	# If upmost y position is not 0 (meaning it is > 0), perform updates
	addi $t5, $t5, -2 # frog_y_val-=2
	sw $t5, 0($t3) # store the new y value of the frog in frog_y
	# Note: frog is drawn on next iteration of game loop, so don't draw it here
	
	j end_response_handler # jump to the end of the keyboard response handler
	
	# Respond to d 
	respond_to_d:
	# d being pressed moves frog right, so update frog_x -> frog_x + 1
	# frog also faces right now (even if it can't actually move in this direction)
	la $t6, frog_facing # load address for frog_facing into $t6
	addi $t7, $zero, 0 # set $t7 equal to frog_facing value for facing right
	sw $t7, 0($t6) # set frog_facing = 0
	# Frog can't move right if its right x position is already 31, so check this first
	# Note: rightmost x position is 31 iff leftmost x position is 28
	beq $t4, 28, dont_update_frog_pos
	# If rightmost x position is not 31 (meaning it is < 31), perform updates
	addi $t4, $t4, 1 # frog_x_val++
	sw $t4, 0($t2) # store the new x value of the frog in frog_x
	# Note: frog is drawn on next iteration of game loop, so don't draw it here
	
	j end_response_handler # jump to the end of the keyboard response handler
	
	
	# Respond to a
	respond_to_a:
	# a being pressed moves frog left, so update frog_x -> frog_x - 1
	# frog also faces left now (even if it can't actually move in this direction)
	la $t6, frog_facing # load address for frog_facing into $t6
	addi $t7, $zero, 2 # set $t7 equal to frog_facing value for facing left
	sw $t7, 0($t6) # set frog_facing = 2
	# Frog can't move left if its x position is already 0, so check this first
	beqz $t4, dont_update_frog_pos
	# If x position is not 0 (meaning it is > 0), perform updates
	addi $t4, $t4, -1 # frog_x_val--
	sw $t4, 0($t2) # store the new x value of the frog in frog_x
	# Note: frog is drawn on next iteration of game loop, so don't draw it here
	
	j end_response_handler # jump to the end of the keyboard response handler
	
	dont_update_frog_pos: # nothing to update, so go to the end response handler
	j end_response_handler
	
	end_response_handler: # Handle the resetting of values in memory after keystroke was handled
	sw $zero 0($t1) # reset keyboard input location in memory to 0 so that only new inputs are considered
	j end_handle_keystrokes # jump to end of function
	
	end_handle_keystrokes:
	jr $ra # return


# Function to detect collisions with objects
# Return values: $v0 -> 1 on collision, 0 otherwise
handle_collisions:
	# Register values:
	# $a3 -> colour of object to detect
	# $t0 -> inner loop variable i
	# $t1 -> outer loop variable j
	# $t2 -> index into boardNoFrog array based on frog position
	# $t3 -> inner and outer loop stopping condition
	# $t6 -> stores object colour
	# $t7 -> stores boardNoFrog[index]
	addi $t3, $zero, 4 # inner and outer loop stop value = 4
	move $t6, $a3 # set $t6 to be object colour
	
	# Set index into boardNoFrog array using frog_x and frog_y
	# index = frog_x * 4 + frog_y * 128 + starting address
	# So we can use convert_xy_pixel with starting address as boardNoFrog
	# to get index
	# Call function to calculate leftmost pixel of frog (starting index into boardNoFrog array)
	lw $a0, frog_x # load function argument for x position
	lw $a1, frog_y # load function argument for y position
	la $a2, boardNoFrog # load function argument for board address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function
	jal convert_xy_to_pixel
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Set boardNoFrog[index] to return value from function call
	move $t2, $v0
	
	# Set up loop variables
	xor $t0, $t0, $t0 # i = 0
	xor $t1, $t1 $t1 # j = 0
	
	# Loop through frog positions
	# Note: index will never be "out of bounds" because the frog's entire frame (4x4 square)
	# is always completely contained within the board
	check_collision_outer_loop: # for (int j = 0; j < 4; j++)
	beq $t1, $t3, check_collision_outer_loop_end # branch to outer loop end if j == 4
	xor $t0, $t0, $t0 # set i to 0 at each iteration of outer loop
	
	check_collision_inner_loop: # for (int i = 0; i < 4; i++)
	beq $t0, $t3, check_collision_inner_loop_end # branch to inner loop end if i == 4
	
	lw $t7, 0($t2) # load the colour stored in $t2 into $t7
	beq $t7, $t6, collision_success # branch to collision success if boardNoFrog[index] == red
	# If not, keep checking
	addi $t2, $t2, 4 # index += 4 (go to next array element)
	
	addi $t0, $t0, 1 # i++
	j check_collision_inner_loop # jump to start of inner loop
	check_collision_inner_loop_end:
	# Jump index to next row
	addi $t2, $t2, -16 # Reset to start of current row (go back 4 pixels)
	addi $t2, $t2, 128 # Add 32 pixels to get to next row
	
	addi $t1, $t1, 1 # j++
	j check_collision_outer_loop # jump to start of outer loop
	check_collision_outer_loop_end:
	
	# If we reach the end of the loop, we didn't find a collision, so there
	# were none
	j collision_failure # jump to collision_failure (not necessary)
	
	collision_failure:
	addi $v0, $zero, 0 # set $v0 = 0
	j collision_return # jump to return
	
	collision_success:
	addi $v0, $zero, 1 # set $v0 = 1
	j collision_return # jump to return (not necessary)
	
	collision_return:
	jr $ra # return


# Function to handle frog moving with log
# Parameters: $a3 -> 0 if handling left-moving logs, 1 if handling right-moving logs
# Return values: $v0 -> 0 if frog did not die, 1 if frog died (from being pushed off screen by log)
handle_frog_on_log:
	# Register values:
	# $a3 -> determine which row of logs we are checking
	# $t0 -> inner loop variable i
	# $t1 -> outer loop variable j
	# $t2 -> index into boardNoFrog array based on frog position
	# $t3 -> inner and outer loop stopping condition
	# $t4 -> stores frog_x address and frog_y address / value
	# $t5 -> stores frog_x and frog_y new value on collision
	# $t6 -> stores object colour
	# $t7 -> stores boardNoFrog[index]
	# $t8 -> stores comparison value for if statement
	# $s0 -> stores value of water_r1_y - 1
	# $s1 -> stores value of water_r2_y
	# $s2 -> stores comparison value for if statement
	# $s3 -> used to check if left-moving / right-moving logs were updated
	addi $t3, $zero, 4 # inner and outer loop stop value = 4
	
	beqz $a3, set_leftmoving_log_colour # branch to handle collisions with left-moving logs if $a3 = 0
	# If we make it here, we are handling collisions with right-moving logs
	lw $t6, log_2_colour_collisions # Load corresponding log colour on boardNoFrog
	j log_colour_set # jump to log_colour_set
	
	set_leftmoving_log_colour: 
	# If we make it here, we are handling collisions with left-moving logs
	lw $t6, log_1_colour_collisions # Load corresponding log colour on boardNoFrog
	j log_colour_set # jump to log_colour_set
	
	log_colour_set:
	# Set index into boardNoFrog array using frog_x and frog_y
	# index = frog_x * 4 + frog_y * 128 + starting address
	# So we can use convert_xy_pixel with starting address as boardNoFrog
	# to get index
	# Call function to calculate leftmost pixel of frog (starting index into boardNoFrog array)
	lw $a0, frog_x # load function argument for x position
	lw $a1, frog_y # load function argument for y position
	la $a2, boardNoFrog # load function argument for board address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function
	jal convert_xy_to_pixel
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Set boardNoFrog[index] to return value from function call
	move $t2, $v0
	
	# Set up loop variables
	xor $t0, $t0, $t0 # i = 0
	xor $t1, $t1 $t1 # j = 0
	
	# Loop through frog positions
	# Note: index will never be "out of bounds" because the frog's entire frame (4x4 square)
	# is always completely contained within the board
	log_collision_outer_loop: # for (int j = 0; j < 4; j++)
	beq $t1, $t3, log_collision_outer_loop_end # branch to outer loop end if j == 4
	xor $t0, $t0, $t0 # set i to 0 at each iteration of outer loop
	
	log_collision_inner_loop: # for (int i = 0; i < 4; i++)
	beq $t0, $t3, log_collision_inner_loop_end # branch to inner loop end if i == 4
	
	lw $t7, 0($t2) # load the colour stored in $t2 into $t7
	bne $t7, $t6, log_collision_failure # branch to collision failure  if boardNoFrog[index] != log colour
	# If not, keep checking
	addi $t2, $t2, 4 # index += 4 (go to next array element)
	
	addi $t0, $t0, 1 # i++
	j log_collision_inner_loop # jump to start of inner loop
	log_collision_inner_loop_end:
	# Jump index to next row
	addi $t2, $t2, -16 # Reset to start of current row (go back 4 pixels)
	addi $t2, $t2, 128 # Add 32 pixels to get to next row
	
	addi $t1, $t1, 1 # j++
	j log_collision_outer_loop # jump to start of outer loop
	log_collision_outer_loop_end:
	
	# If we reach the end of the loop, we didn't find a square where the frog wasn't on a log,
	# so the frog must've been entirely contained on a log
	j log_collision_success # jump to log_collision_success
	
	log_collision_failure:
	addi $v0, $zero, 0 # set return value to 0
	j log_collision_return # jump to return
	
	log_collision_success:
	# Update frog_x to move with the log
	# Note: logs move 2 pixels each time, so the frog's position will move
	# left/right 2 pixels as well (if the frog can move)
	# Implementation note: If the frog can't move left/right, it dies
	lw $t4, frog_y # load frog_y value into $t4
	# We know the frog is on a log. We need to check if it is on a left-moving log or
	# a right-moving log. To do this, check the range of frog_y. Frog is on a left-moving log
	# iff water_r1_y <= frog_y <= water_r2_y - 1 <=> water_r1_y - 1 < frog_y < water_r2_y
	lw $s0, water_r1_y # $s0 = water_r1_y
	addi $s0, $s0, -1 # $s0-- -> $s0 = water_r1_y - 1
	lw $s1, water_r2_y # $s1 = water_r2_y
	slt $t8, $t4, $s1 # set $t8 = 1 iff frog_y < water_r2_y
	slt $s2, $s0, $t4 # set $s2 = 1 iff water_r1_y - 1 < frog_y
	and $s2, $t8, $s2 # set $s2 = 1 iff water_r1_y - 1 < frog_y < water_r2_y
	beqz $s2, log_collision_move_frog_right # branch if frog not in water row 1 (must be in water row 2)
	# If we make it here, frog is in water row 1, so move frog left
	# Important: Only move frog left if left moving logs were updated
	lw $s3, board_updated_left # load board_updated_left value into $s3
	beqz, $s3, log_collision_return # don't update frog position if left-moving objects were not updated
	la $t4, frog_x # load frog_x address into $t4
	lw $t5, frog_x # load frog_x value into $t5
	addi $t5, $t5, -2 # set frog_x new value = frog_x - 2
	slt $t8, $t5, $zero # set $t8 = 1 iff frog_x < 0 (frog is out of bounds now)
	beq $t8, 1, log_collision_kill_frog # branch to kill the frog if frog out of bounds
	# If we make it here, the frog can move right
	addi $v0, $zero, 0 # set return value to 0
	sw $t5, 0($t4) # write this new value to frog_x
	j log_collision_return # jump to return
	
	log_collision_move_frog_right:
	# Move frog right because it is on a log in water row 2
	# Important: Only move frog right if right moving logs were updated
	lw $s3, board_updated_right # load board_updated_right value into $s3
	beqz, $s3, log_collision_return # don't update frog position if right-moving objects were not updated
	addi $s2, $zero, 28 # set $s2 to 28
	la $t4, frog_x # load frog_x address into $t4
	lw $t5, frog_x # load frog_x value into $t5
	addi $t5, $t5, 2 # set frog_x new value = frog_x + 2
	slt $t8, $s2, $t5 # set $t8 = 1 iff 28 < frog_x (frog is out of bounds now)
	beq $t8, 1, log_collision_kill_frog # branch to kill the frog if frog out of bounds
	# If we make it here, the frog can move right
	addi $v0, $zero, 0 # set return value to 0
	sw $t5, 0($t4) # write this new value to frog_x
	j log_collision_return # jump to return
	
	# Kill the frog because it is now out of bounds
	log_collision_kill_frog:
	addi $v0, $zero, 1 # set return value to 1
	# Update frog_x and frog_y to starting position
	la $t4, frog_x # load frog_x address into $t4
	addi $t5, $zero, 14 # set frog_x new value = 14 
	sw $t5, 0($t4) # write this new value to frog_x
	la $t4, frog_y # load frog_y address into $t4
	addi $t5, $zero, 28 # set frog_y new value = 28
	sw $t5, 0($t4) # write this new value to frog_y
	j log_collision_return # jump to return (not necessary)
	
	log_collision_return:
	jr $ra # return


# Function to frog made it to goal area
check_frog_win:
	# Register values:
	# $t0 -> inner loop variable i
	# $t1 -> outer loop variable j
	# $t2 -> index into boardNoFrog array based on frog position
	# $t3 -> inner and outer loop stopping condition
	# $t4 -> stores frog_x address and frog_y address / value
	# $t5 -> stores frog_x and frog_y new value on collision
	# $t6 -> stores object colour
	# $t7 -> stores boardNoFrog[index]
	# $t8 -> stores comparison value for if statement
	# $s0 -> stores value of water_r1_y - 1
	# $s1 -> stores value of water_r2_y
	# $s2 -> stores comparison value for if statement
	addi $t3, $zero, 4 # inner and outer loop stop value = 4
	lw $t6, goalColour # set $t6 to be goal colour
	
	# Set index into boardNoFrog array using frog_x and frog_y
	# index = frog_x * 4 + frog_y * 128 + starting address
	# So we can use convert_xy_pixel with starting address as boardNoFrog
	# to get index
	# Call function to calculate leftmost pixel of frog (starting index into boardNoFrog array)
	lw $a0, frog_x # load function argument for x position
	lw $a1, frog_y # load function argument for y position
	la $a2, boardNoFrog # load function argument for board address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function
	jal convert_xy_to_pixel
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Set boardNoFrog[index] to return value from function call
	move $t2, $v0
	
	# Set up loop variables
	xor $t0, $t0, $t0 # i = 0
	xor $t1, $t1 $t1 # j = 0
	
	# Loop through frog positions
	# Note: index will never be "out of bounds" because the frog's entire frame (4x4 square)
	# is always completely contained within the board
	goal_checker_outer_loop: # for (int j = 0; j < 4; j++)
	beq $t1, $t3, goal_checker_outer_loop_end # branch to outer loop end if j == 4
	xor $t0, $t0, $t0 # set i to 0 at each iteration of outer loop
	
	goal_checker_inner_loop: # for (int i = 0; i < 4; i++)
	beq $t0, $t3, goal_checker_inner_loop_end # branch to inner loop end if i == 4
	
	lw $t7, 0($t2) # load the colour stored in $t2 into $t7
	bne $t7, $t6, goal_checker_failure # branch to failure if boardNoFrog[index] != goal colour
	# If not, keep checking
	addi $t2, $t2, 4 # index += 4 (go to next array element)
	
	addi $t0, $t0, 1 # i++
	j goal_checker_inner_loop # jump to start of inner loop
	goal_checker_inner_loop_end:
	# Jump index to next row
	addi $t2, $t2, -16 # Reset to start of current row (go back 4 pixels)
	addi $t2, $t2, 128 # Add 32 pixels to get to next row
	
	addi $t1, $t1, 1 # j++
	j goal_checker_outer_loop # jump to start of outer loop
	goal_checker_outer_loop_end:
	
	# If we reach the end of the loop, we didn't find a square of the frog
	# that isn't in the goal, so the entire frog is contained in a goal region
	j goal_checker_success # jump to log_collision_failure (not necessary)
	
	goal_checker_failure: # nothing to do here besides jump to return
	j goal_checker_return # jump to return
	
	goal_checker_success:
	# Paint spot where frog landed yellow
	# Get memory address of upper-leftmost pixel of frog relative to display board
	lw $a0, frog_x # load function argument for x position
	lw $a1, frog_y # load function argument for y position
	lw $a2, displayAddress # load function argument for board address
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function
	jal convert_xy_to_pixel
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Set $t0 = memory address to draw at 
	move $t0, $v0
	
	# Load funciton arguments to draw yellow frog
	lw $a3, frogWinColour
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw player frog
	jal draw_player_frog
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Write buffer to screen
	jal write_buffer
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Jump to exit
	j Exit
	
	goal_checker_return:
	jr $ra # return



# Function to initialize static parts of the board without frog 
initialize_static_board_no_frog:
	la $t0, boardNoFrog # set $t0 to address of boardNoFrog
	##########################################
	# Initialize goal area
	##########################################
	# Load function arguments to draw goal area
	# Goal area map N = no goal, G = goal, (#) = pixel width
	# | N (8) | |G(4)| | N (8) | |G(4)| | N(8) |
	# Load function arguments to draw N_1(8)
	li $a0, 8
	li $a1, 8
	la $a2, boardNoFrog
	lw $a3, nonValidGoalColour
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	# Load function arguments to draw G_1(4)
	li $a0, 4
	li $a1, 8
	la $a2, boardNoFrog 
	addi $a2, $a2, 32 # move starting x by 8 pixles (8 x 4 = 32)
	lw $a3, goalColour
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	
	# Load function arguments to draw N_2(8)
	li $a0, 8
	li $a1, 8
	la $a2, boardNoFrog 
	addi $a2, $a2, 48 # move starting x by 12 pixles (12 x 4 = 48)
	lw $a3, nonValidGoalColour

	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	# Load function arguments to draw G_2(4)
	li $a0, 4
	li $a1, 8
	la $a2, boardNoFrog 
	addi $a2, $a2, 80 # move starting x by 20 pixles (20 x 4 = 80)
	lw $a3, goalColour
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	# Load function arguments to draw N_3(8)
	li $a0, 8
	li $a1, 8
	la $a2, boardNoFrog 
	addi $a2, $a2, 96 # move starting x by 20 pixles (24 x 4 = 96)
	lw $a3, nonValidGoalColour
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	##########################################
	# Initialize safe zone
	##########################################
	# Update $t0 to be the memory address of the safe zone relative to boardNoFrog
	addi $t0, $t0, 2048 # 2048 = 32 x 8 x 4 (goal area) + 32 x 8 x 4 (water area)
	# Load function arguments to draw safe zone
	li $a0, 32
	li $a1, 4
	move $a2, $t0
	lw $a3, white # colour white
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw safe area onto boardNoFrog
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	##########################################
	# Initialize start area
	##########################################
	# Update $t0 to be the memory address of the start area relative to safe area in boardNoFrog
	addi $t0, $t0, 1536 # 1536 = 32 x 4 x 4 (safe area) + 32 x 8 x 4 (road area)
	# Load function arguments to draw start area
	li $a0, 32
	li $a1, 4
	move $a2, $t0
	lw $a3, white # colour white
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw safe area onto boardNoFrog
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	jr $ra # return

	
# Function to draw number of frog lives remaining on the screen
draw_frog_lives:
	lw $t0, frog_lives # set $t0 = number of lives remaining
	xor $t1, $t1, $t1 # loop variable i
	la $t2, displayBuffer # load the starting address for the displayBuffer
	addi $t2, $t2, 132 # translate it by 132 to get to the start of the lives area
	
	# Loop through number of lives remaining
	draw_frog_lives_loop:
	beq $t1, $t0, draw_frog_lives_loop_end # branch to end of loop if i == # of lives to draw
	# Loop body
	# Load function arguments to draw 2x2 square that has colour frogColour
	addi $a0, $zero, 2 # draw 2 x pixels
	addi $a1, $zero, 2 # draw 2 y pixels
	move $a2, $t2 # start drawing at current memory address to draw at
	lw $a3, frogColour # colour the pixels frogColour
	
	# Push variables onto stack to save register values
	addi $sp, $sp, -4 # update stack pointer
	sw $t0, 0($sp) # push $t0 onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $t1, 0($sp) # push $t1 onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $t2, 0($sp) # push $t2 onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw the 2x2 pixel
	jal draw_rect
	
	# Pop values from from stack in reverse order w.r.t insertion order
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	lw $t2, 0($sp) # pop value from stack and store it in $t2
	addi $sp, $sp, 4 # update stack pointer
	lw $t1, 0($sp) # pop value from stack and store it in $t1
	addi $sp, $sp, 4 # update stack pointer
	lw $t0, 0($sp) # pop value from stack and store it in $t0
	addi $sp, $sp, 4 # update stack pointer
	
	addi $t2, $t2, 12 # move to next pixel to start drawing at (move 3 pixels right, 12 = 3 x 4)
	addi $t1, $t1, 1 # i++
	j draw_frog_lives_loop # jump to start of loop
	
	draw_frog_lives_loop_end:
	jr $ra # return


# Function to draw game over screen
draw_game_over_screen:
	# Remove last life from screen
	addi $a0, $zero, 32 # draw 32 x pixels
	addi $a1, $zero, 4 # draw 4 y pixels
	la $a2, displayBuffer # start drawing into displayBuffer
	lw $a3, green # draw green
	
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw over the old stats header
	jal draw_rect
	
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Start drawing retry y/n message

	la $t0, displayBuffer # load starting address into $t0
	addi $t0, $t0, 1292 # get starting pixel to draw at
	lw $t1, gameOverMsgColour # load correct pixel colour
	
	# Draw 'r'
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -512 # go back to start pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	
	# Draw 'e'
	addi $t0, $t0, 8 # move right 2 pixels
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -384 # go back to original pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 256 # go down 2 rows
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 256 # go down 2 rows
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -512 # go back to original pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 256 # go down 2 rows
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 256 # go down 2 rows
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -512 # go back to original pixel
	addi $t0, $t0, 4 # go right 1 pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 384 # go down 3 pixels
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -512 # go back to original pixel

	# Draw 't'
	addi $t0, $t0, 8 # move right 2 pixels
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -128 # go back to original pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -384 # go back up 3 rows
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -128 # go back to original row
	
	# Draw 'r'
	addi $t0, $t0, 8 # move right 2 pixels
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -512 # go back to start pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	
	# Draw 'y'
	addi $t0, $t0, 8 # move right 2 pixels
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 4 # move right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -256 # go up 3 rows
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -128 # go up 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -128 # go up 1 row
	sw $t1, 0($t0) # paint pixel
	
	# Draw '?'
	addi $t0, $t0, 8 # move right 2 pixels
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -128 # go up 1 row
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 256 # go down 2 rows
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 256 # go down 2 rows
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -384 # go up 3 rows
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	
	la $t0, displayBuffer # load starting address into $t0
	addi $t0, $t0, 1292 # get starting pixel to draw at
	addi $t0, $t0, 896 # go down 6 pixels
	addi $t0, $t0, 12 # go right 3 pixels
	
	# Draw 'y'
	addi $t0, $t0, 8 # move right 2 pixels
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 4 # move right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -256 # go up 3 rows
	addi $t0, $t0, 4 # go right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -128 # go up 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -128 # go up 1 row
	sw $t1, 0($t0) # paint pixel
	
	# Draw '/'
	addi $t0, $t0, 8 # move right 2 pixels
	addi $t0, $t0, 512 # go down 5 pixels
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -124 # go up 1 row and right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -124 # go up 1 row and right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -124 # go up 1 row and right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -124 # go up 1 row and right 1 pixel
	sw $t1, 0($t0) # paint pixel
	
	# Draw 'n'
	addi $t0, $t0, 12 # move right 3 pixels
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, -384 # go up 3 rows
	addi $t0, $t0, 4 # move right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 4 # move right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 4 # move right 1 pixel
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	addi $t0, $t0, 128 # go down 1 row
	sw $t1, 0($t0) # paint pixel
	
	# Write buffer to screen
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to write buffer to screen
	jal write_buffer
	
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	jr $ra # return
	

# Function to handle game over events
# Return value: $v0 = 1 if user chooses to quit game, 0 if they choose to retry
handle_game_over:
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw game over screen
	jal draw_game_over_screen
	
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer

	handle_game_over_loop: # infinite loop waiting for user to type y or n
	lw $t0, 0xffff0000 # load the value storing if a key was just pressed into $t0
	la $t1, 0xffff0000 # load the value of the memory address into $t1
	beq $t0, 1, game_over_input # handle keyboard input if one happened
	j game_over_no_process # jump to end of loop body because there was no input if we reach here
	
	game_over_input: # Handle keyboard input if it happened
	lw $t0, 0xffff0004 # load the value of the key pressed into $t0
	beq $t0, 0x79, respond_to_y # branch to respond to y if key pressed was y
	beq $t0, 0x6e, respond_to_n # branch to respond to n if key pressed was n
	# If we make it here, the user typed an invalid key, so don't process anything
	sw $zero 0($t1) # reset keyboard input location in memory to 0 so that only new inputs are considered
	j game_over_no_process
	
	respond_to_n: 
	# If the user chose to quit the game, set return value $v0 = 1 and jump to return
	addi $v0, $zero, 1 # set $v0 = 1
	j game_over_return # jump to return
	
	respond_to_y:
	# If the user chose to retry, reset all values to their startinv values, set the return value
	# $v0 = 0, and jump to retrun
	# Reset memory values
	la $t2, frog_x # load address of frog_x into $t2
	addi $t3, $zero, 14 # set $t3 = 14
	sw $t3, 0($t2) # set frog_x = 14
	la $t2, frog_y # load address of frog_y into $t2
	addi $t3, $zero, 28 # set $t3 = 28
	sw $t3, 0($t2) # set frog_y = 28
	la $t2, car_1_r1_x # load address of car_1_r1_x into $t2
	sw $zero, 0($t2)# set car_1_r1_x = 0
	la $t2, car_2_r1_x # load address of car_2_r1_x into $t2
	addi $t3, $zero, 16 # set $t3 = 16
	sw $t3, 0($t2) # set car_2_r1_x = 16
	la $t2, car_1_r2_x # load address of car_1_r2_x into $t2
	addi $t3, $zero, 2 # set $t3 = 2
	sw $t3, 0($t2) # set car_1_r2_x = 2
	la $t2, car_2_r2_x # load address of car_2_r2_x into $t2
	addi $t3, $zero, 18 # set $t3 = 18
	sw $t3, 0($t2) # set car_2_r2_x = 18
	la $t2, log_1_r1_x # load address of log_1_r1_x into $t2
	sw $zero, 0($t2)# set log_1_r1_x = 0
	la $t2, log_2_r1_x # load address of log_2_r1_x into $t2
	addi $t3, $zero, 16 # set $t3 = 16
	sw $t3, 0($t2) # set log_2_r1_x = 16
	la $t2, log_1_r2_x # load address of log_1_r2_x into $t2
	addi $t3, $zero, 2 # set $t3 = 2
	sw $t3, 0($t2) # set log_1_r2_x = 2
	la $t2, log_2_r2_x # load address of log_2_r2_x into $t2
	addi $t3, $zero, 18 # set $t3 = 18
	sw $t3, 0($t2) # set log_2_r2_x = 18
	la $t2, update_objects_r_timer # load address of update_objects_r_timer into $t2
	addi $t3, $zero, 23 # set $t3 = 23
	sw $t3, 0($t2) # set update_objects_r_timer = 23
	la $t2, update_objects_l_timer # load address of update_objects_l_timer into $t2
	addi $t3, $zero, 14 # set $t3 = 14
	sw $t3, 0($t2) # set update_objects_l_timer = 14
	la $t2, collision_occurred_log_right # load address of collision_occurred_log_right into $t2
	sw $zero, 0($t2) # set collision_occurred_log_right = 0
	la $t2, collision_occurred_log_left # load address of collision_occurred_log_left into $t2
	sw $zero, 0($t2) # set collision_occurred_log_left = 0
	la $t2, frog_lives # load address of frog_lives into $t2
	addi $t3, $zero, 5 # set $t3 = 5
	sw $t3, 0($t2) # set frog_lives = 5
	la $t2, alligator_x # load address of alligator_x into $t2
	sw $zero, 0($t2) # set alligator_x = 0
	la $t2, frog_facing # load address of frog_facing into $t2
	addi $t3, $zero, 3 # set $t3 = 3
	sw $t3, 0($t2) # set frog_facing = 3
	
	xor $v0, $v0, $v0 # set $v0 = 0
	
	j game_over_return # jump to return
	
	game_over_no_process: 
	j handle_game_over_loop # jump to handle_game_over_loop
	
	game_over_return:
	sw $zero 0($t1) # reset keyboard input location in memory to 0 so that only new inputs are considered
	jr $ra # return


# Function to initialize default goal area pixels
initialize_default_goal_area_pixels:
	##########################################
	# Draw goal area
	##########################################
	# Goal area map N = no goal, G = goal, (#) = pixel width
	# | N (8) | |G(4)| | N (8) | |G(4)| | N(8) |
	# Load function arguments to draw N_1(8)
	li $a0, 8
	li $a1, 4
	la $a2, goalRow
	lw $a3, green
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	# Load function arguments to draw G_1(4)
	li $a0, 4
	li $a1, 4
	la $a2, goalRow 
	addi $a2, $a2, 32 # move starting x by 8 pixles (8 x 4 = 32)
	lw $a3, waterColour
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	# Load function arguments to draw N_2(8)
	li $a0, 8
	li $a1, 4
	la $a2, goalRow 
	addi $a2, $a2, 48 # move starting x by 12 pixles (12 x 4 = 48)
	lw $a3, green
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	# Load function arguments to draw G_2(4)
	li $a0, 4
	li $a1, 4
	la $a2, goalRow 
	addi $a2, $a2, 80 # move starting x by 20 pixles (20 x 4 = 80)
	lw $a3, waterColour
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	# Load function arguments to draw N_3(8)
	li $a0, 8
	li $a1, 4
	la $a2, goalRow 
	addi $a2, $a2, 96 # move starting x by 20 pixles (24 x 4 = 96)
	lw $a3, green
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	jr $ra # return


# Function to update goal area pixel values
update_pixels_goal_area:
	lw $t0, alligator_x # load alligator leftmost x position into $t0
	beq $t0, 8, alligator_in_goal_one # branch to handle alligator being in goal 1 if alligator_x == 8
	beq $t0, 12, alligator_in_goal_one # branch to handle alligator being in goal 1 if alligator_x == 12
	beq $t0, 20, alligator_in_goal_two # branch to handle alligator being in goal 2 if alligator_x == 20
	beq $t0, 24, alligator_in_goal_two # branch to handle alligator being in goal 1 if alligator_x == 24
	# If we make it here, the alligator is in neither goal, so set goal areas to water colour pixels
	lw $t1, waterColour # goal 1 colour
	lw $t2, waterColour # goal 2 colour
	lw $t3, goalColour # goal 1 colour boardNoFrog
	lw $t4, goalColour # goal 2 colour boardNoFrog
	j update_pixels_goal_area_mem # jump to next set of instructions
	
	alligator_in_goal_one: # Handle alligator being in goal one
	lw $t1, alligatorColour # goal 1 colour
	lw $t2, waterColour # goal 2 colour
	lw $t3, alligatorColour # goal 1 colour boardNoFrog
	lw $t4, goalColour # goal 2 colour boardNoFrog
	j update_pixels_goal_area_mem # jump to next set of instructions
	
	alligator_in_goal_two: # Handle alligator being in goal two
	lw $t1, waterColour # goal 1 colour
	lw $t2, alligatorColour # goal 2 colour
	lw $t3, goalColour # goal 1 colour boardNoFrog
	lw $t4, alligatorColour # goal 2 colour boardNoFrog
	j update_pixels_goal_area_mem # jump to next set of instructions (not necessary)
	
	update_pixels_goal_area_mem:
	# Load function arguments to draw G_1(4) on regular board
	li $a0, 4
	li $a1, 4
	la $a2, goalRow 
	addi $a2, $a2, 32 # move starting x by 8 pixles (8 x 4 = 32)
	move $a3, $t1
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	
	# Load function arguments to draw G_1(4) on boardNoFrog
	li $a0, 4
	li $a1, 4
	la $a2, boardNoFrog
	addi $a2, $a2, 512 # move down 4 rows 
	addi $a2, $a2, 32 # move starting x by 8 pixles (8 x 4 = 32)
	move $a3, $t3
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	
	# Load function arguments to draw G_2(4) on regular board
	li $a0, 4
	li $a1, 4
	la $a2, goalRow 
	addi $a2, $a2, 80 # move starting x by 20 pixles (20 x 4 = 80)
	move $a3, $t2
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	
	# Load function arguments to draw G_2(4) on boardNoFrog
	li $a0, 4
	li $a1, 4
	la $a2, boardNoFrog
	addi $a2, $a2, 512 # move down 4 rows 
	addi $a2, $a2, 80 # move starting x by 20 pixles (20 x 4 = 80)
	move $a3, $t4
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw goal area
	jal draw_rect
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	
	jr $ra # return


# Function to update alligator position
update_alligator_pos:
	la $t0, alligator_x # load address of alligator_x into $t0
	lw $t1, alligator_x # load value of alligator_x into $t1
	addi $t1, $t1, 4 # $t1 = alligator_x + 4
	beq $t1, 32, set_alligator_x_zero # branch if alligator_x + 4 == 32
	# If we make it here, we don't need to reset alligator_x
	sw $t1, 0($t0) # set alligator_x = alligator_x + 4
	j update_alligator_pos_return # jump to return
	
	set_alligator_x_zero:
	sw $zero, 0($t0) # set alligator_x = 0
	j update_alligator_pos_return # jump to return
	
	update_alligator_pos_return:
	jr $ra # return


# Draw spider on log 2 row 2
draw_spider_log_2_r2:
	# Register values
	# Spider layout: x_1 x_2 x_3 x_4
	lw $t0, log_2_r2_x # load leftmost x position of log_2_r2 into $t0
	la $t1, displayBuffer # load address of displayBuffer
	addi $t1, $t1, 1536 # go down 12 rows to start of water row 2
	addi $t2, $zero, 4 # $t2 = 4
	mult $t0, $t2 # log_2_r2_x * 4
	mflo $t2 # $t2 = log_2_r2_x * 4
	add $t1, $t1, $t2 # $t1 = address of water 2 y position + (log_2_r2_x * 4)
	move $t9, $t2 # $t9 = log_2_r2_x * 4
	beq $t0, 30, spider_x1_log_2_r2_edge # branch to handle egde case: spider x_1 == 30
	# If we make it here, the spider will be fully on the screen (no wrapping),
	# so draw the spider
	# Set function parameters
	move $a0 $t1 # x_1
	addi $a1, $t1, 4 # 1 pixel right from x_1
	addi $a2, $t1, 8 # 2 pixels right from x_1
	addi $a3, $t1, 12 # 3 pixels right from x_1
	
	j draw_spider_log_2_r2_call # jump to function call to draw spider
	
	spider_x1_log_2_r2_edge:
	move $a0 $t1 # x_1
	addi $a1, $t1, 4 # 1 pixel right from x_1
	la $t1, displayBuffer # load address of displayBuffer
	addi $t1, $t1, 1536 # go down 12 rows to start of water row 2
	move $a2, $t1 # x = 0 at correct y pos
	addi $a3, $t1, 4 # 1 pixel right from x_3
	
	j draw_spider_log_2_r2_call # jump to function call to draw spider (not necessary)
	
	draw_spider_log_2_r2_call:
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw spider
	jal draw_spider
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Draw spider on boardNoFrog
	lw $t0, log_2_r2_x # load leftmost x position of log_2_r2 into $t0
	la $t1, boardNoFrog # load address of boardNoFrog
	addi $t1, $t1, 1536 # go down 12 rows to start of water row 2
	addi $t2, $zero, 4 # $t2 = 4
	mult $t0, $t2 # log_2_r2_x * 4
	mflo $t2 # $t2 = log_2_r2_x * 4
	add $t1, $t1, $t2 # $t1 = address of water 2 y position + (log_2_r2_x * 4)
	move $t9, $t2 # $t9 = log_2_r2_x * 4
	beq $t0, 30, spider_x1_edge_log_2_r2_bnf # branch to handle egde case: spider x_1 == 30
	# If we make it here, the spider will be fully on the screen (no wrapping),
	# so draw the spider
	# Set function parameters
	move $a0 $t1 # x_1
	addi $a1, $t1, 4 # 1 pixel right from x_1
	addi $a2, $t1, 8 # 2 pixels right from x_1
	addi $a3, $t1, 12 # 3 pixels right from x_1
	
	j draw_spider_call_log_2_r2_bnf # jump to function call to draw spider on boardNoFrog
	
	spider_x1_edge_log_2_r2_bnf:
	move $a0 $t1 # x_1
	addi $a1, $t1, 4 # 1 pixel right from x_1
	la $t1, boardNoFrog
	addi $t1, $t1, 1536 # load address of water 2 y position into $t1
	move $a2, $t1 # x = 0 at correct y pos
	addi $a3, $t1, 4 # 1 pixel right from x_3
	
	j draw_spider_call_log_2_r2_bnf # jump to function call to draw spider on boardNoFrog
	
	draw_spider_call_log_2_r2_bnf:
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw spider on boardNoFrog
	jal draw_spider
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	jr $ra # return


# Draw spider on log 1 row 1
draw_spider_log_1_r1:
	# Spider layout: x_1 x_2 x_3 x_4
	lw $t0, log_1_r1_x # load leftmost x position of log_1_r1 into $t0
	la $t1, displayBuffer
	addi $t1, $t1, 1024 # load value of water 1 y position
	addi $t2, $zero, 4 # $t2 = 4
	mult $t0, $t2 # log_1_r1_x * 4
	mflo $t2 # $t2 = log_1_r1_x * 4
	add $t1, $t1, $t2 # $t1 = address of water 1 y position + (log_1_r1_x * 4)
	beq $t0, -6, spider_x1_log_1_r1_edge_1 # branch to handle egde case: spider x_1 == -6
	# If we make it here, the spider will be fully on the screen (no wrapping),
	# so draw the spider
	# Set function parameters
	addi $a0, $t1, 16 # move x_1 4 pixels right
	addi $a1, $a0, 4 # 1 pixel right from x_1
	addi $a2, $a0, 8 # 2 pixels right from x_1
	addi $a3, $a0, 12 # 3 pixels right from x_1
	
	j draw_spider_log_1_r1_call # jump to function call to draw spider
	
	spider_x1_log_1_r1_edge_1:
	addi $a0, $t1, 144 # move x_1 to pixel 30_x
	addi $a1, $a0, 4 # 1 pixel right from x_1
	la $t1, displayBuffer
	addi $t1, $t1, 1024 # load value of water 1 y position
	move $a2, $t1 # x = 0 at correct y pos
	addi $a3, $a2, 4 # 1 pixel right from x_3
	
	j draw_spider_log_1_r1_call # jump to function call to draw spider (not necessary)
	
	
	draw_spider_log_1_r1_call:
	
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw spider
	jal draw_spider
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	# Draw spider on boardNoFrog
	lw $t0, log_1_r1_x # load leftmost x position of log_1_r1 into $t0
	la $t1, boardNoFrog # load address of boardNoFrog
	addi $t1, $t1, 1024 # go down 8 rows to start of water row 1
	addi $t2, $zero, 4 # $t2 = 4
	mult $t0, $t2 # log_1_r1_x * 4
	mflo $t2 # $t2 = log_1_r_x * 4
	add $t1, $t1, $t2 # $t1 = address of water 2 y position + (log_1_r1_x * 4)
	beq $t0, -6, spider_x1_edge_1_log_1_r1_bnf # branch to handle egde case: spider x_1 == -6
	# If we make it here, the spider will be fully on the screen (no wrapping),
	# so draw the spider
	# Set function parameters
	addi $a0, $t1, 16 # move x_1 4 pixels right
	addi $a1, $a0, 4 # 1 pixel right from x_1
	addi $a2, $a0, 8 # 2 pixels right from x_1
	addi $a3, $a0, 12 # 3 pixels right from x_1
	
	j draw_spider_call_log_1_r1_bnf # jump to function call to draw spider on boardNoFrog
	
	spider_x1_edge_1_log_1_r1_bnf:
	addi $a0, $t1, 144 # move x_1 to pixel 30_x
	addi $a1, $a0, 4 # 1 pixel right from x_1
	la $t1, boardNoFrog 
	addi $t1, $t1, 1024 # load address of water 1 y position on boardNoFrog into $t1
	move $a2, $t1 # x = 0 at correct y pos
	addi $a3, $a2, 4 # 1 pixel right from x_3
	j draw_spider_call_log_1_r1_bnf # jump to function call to draw spider on boardNoFrog
	
	
	draw_spider_call_log_1_r1_bnf:
	# Push $ra onto stack
	addi $sp, $sp, -4 # update stack pointer
	sw $ra, 0($sp) # push $ra onto stack
	
	# Call function to draw spider on boardNoFrog
	jal draw_spider
	
	# Pop $ra from stack
	lw $ra, 0($sp) # pop value from stack and store it in $ra
	addi $sp, $sp, 4 # update stack pointer
	
	jr $ra # return
	

# Function to draw spider of the form x_1 x_2 x_3 x_4
# Parameters: $a0 = x_1, $a1 = x_2, $a2 = x_3, $a3 = x_4
draw_spider:
	lw $t0, black # set $t0 to colour of spider
	# Draw first column
	sw $t0, 0($a0) # paint pixel
	addi $a0, $a0, 384 # go down 3 rows
	sw $t0, 0($a0) # paint pixel
	
	# Draw second column
	addi $a1, $a1, 128 # go down 1 row
	sw $t0, 0($a1) # paint pixel
	addi $a1, $a1, 128 # go down 1 row
	sw $t0, 0($a1) # paint pixel
	
	# Draw third column
	addi $a2, $a2, 128 # go down 1 row
	sw $t0, 0($a2) # paint pixel
	addi $a2, $a2, 128 # go down 1 row
	sw $t0, 0($a2) # paint pixel
	
	# Draw fourth column
	sw $t0, 0($a3) # paint pixel
	addi $a3, $a3, 384 # go down 3 rows
	sw $t0, 0($a3) # paint pixel
	
	jr $ra # return
	
# Function to convert x,y coordinate of object to the leftmost pixel of the object
# on the bitmap display
# Parameters: $a0 = x coordinate of object, $a1 = y coordinate of object, $a2 = address of board
# Return value: $v0 = leftmost pixel of the object on the bitmap display
# Registers Used: ...
convert_xy_to_pixel:
	# Register values
	# $v0 -> return value (leftmost pixel of object on display)
	# $a0 -> x coordinate of object
	# $a1 -> y coordinate of object
	# $a2 -> address of board
	# $t0 -> used to store x offset and y offset for pixels and displayAddress for adding
	xor $v0, $v0, $v0 # set $v0 = 0
	xor $t0, $t0, $t0 # $t0 = 0
	addi $t0, $t0, 4 # $t0 = 0 + 4 = 4 (horizontal offset)
	mult $a0, $t0 # store x_position * 4 in hi:lo. Only need bits in lo.
	mflo $a0 # sets $a0 to the horizontal pixel of the object
	addi $t0, $t0, 124 # $t0 = 4 + 124 = 128 (vertical offset)
	mult $a1, $t0 # store y_position * 128 in hi:lo. Only need bits in lo.
	mflo $a1 # sets $a1 to the vertical pixel of the object
	xor $v0, $v0, $v0 # set $v0 = 0
	add $v0, $a0, $a1 # pixel to draw object at = x_pos * 4 + y_pos * 128
	# lw $t0, displayAddress # set $t0 to the start pixel of the board
	add $v0, $v0, $a2 # translate pixel position onto board
	
	jr $ra # return


# Function to write displayBuffer to screen
write_buffer:
	la $t0, displayBuffer # load address of displayBuffer into $t0
	xor $t1, $t1, $t1 # inner loop variable i = 0
	xor $t2, $t2, $t2 # outer loop variable j = 0
	addi $t3, $zero, 32 # set loop variable end condition for both loops = 32
	lw $t5, displayAddress # load address of display
	write_buffer_outer_loop: # for (int j = 0; j < 32; j++)
	beq $t2, $t3, write_buffer_outer_loop_end # branch to end of outer loop if j == 32
	xor $t1, $t1, $t1 # set i = 0
	write_buffer_inner_loop: # for (int i = 0; i < 32; i++)
	beq $t1, $t3, write_buffer_inner_loop_end # branch to end of inner loop if i == 32
	lw $t4, 0($t0) # load pixel colour value into $t4
	sw $t4, 0($t5) # write pixel value to screen
	addi $t0, $t0, 4 # go to next pixel
	addi $t5, $t5, 4 # go to next pixel
	addi $t1, $t1, 1 # i++
	j write_buffer_inner_loop # jump to start of inner loop
	write_buffer_inner_loop_end:
	addi $t2, $t2, 1 # j++
	j write_buffer_outer_loop # jump to start of outer loop
	write_buffer_outer_loop_end:
	jr $ra # return
