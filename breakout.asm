################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Yasamin Nouri Jelyani, 1005152718
# Student 2: Fariha tasnim oishi, 1007319812
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
    
# colours used:

WHITE:
    .word 0xffffff # colour white

GRAY:
    .word 0x808080 # colour gray
    
YELLOW:
    .word 0xffff00 # colour gray
    
BLACK:
    .word 0x000000  # colour black 

ALL_BRICK_COLORS_BASIC:
    .word 0xff0000 # colour red
    .word 0x0000ff # colour blue
    .word 0x00ff00 #colour green
    
# ball locations and coordinates

BALL: 
   .word 16  # x coordinate 
   .word 16  # y coordinate 
   .word 1   # x direction (right is 1, left is -1) 
   .word -1  # y direction (down is 1, up is -1)
   

##############################################################################
# Mutable Data
##############################################################################
# paddle data is saved under .text section in $s registers
##############################################################################
# Code
##############################################################################
# $t0 = Display base address
# $t1 = 
# $t2 = next display address
# $t3 = offset register
# $t4 = offset storage for right wall
# $t5 = 
# $t6 = 
# $t7 = green colour
# $t8 = COlor white
# $t9 = Colour black

	.text
	.globl main

# paddle data

addi $s0, $s0, 12	# paddle x location
addi $s1, $s1, 24	#paddle y location
addi $s2, $s2, 1	# paddle x movement




main:
    # Initialize the game, wait for 1 second before beginning
    li $a0, 1000				#Stores 1000 in first argument
    li $v0, 32				# wait for 1 second so the ball does not start too quick
    syscall
    #draw walls
    lw $a0, ADDR_DSPL   #Put starting address 
    la $a1, GRAY
    li $a2, 31			# 32 units of height for the walls
    jal draw_TWO_walls               # Draw the white wall
    # draw top row
    jal draw_ROW_ceiling         # draw the ceiling of the wall 
    
    # draw the bricks
    lw $a0, ADDR_DSPL   #Put starting address as the address
    la $a1, ALL_BRICK_COLORS_BASIC
    li $a2, 30
    jal draw_THREE_ROW_bricks             # Draws 3 rows of bricks at $a0
    
    # draw the ball
    lw $a3,WHITE
    jal draw_ball
    jal draw_rect	# call function
    
    #draw the paddle
    lw $a3,WHITE
    jal draw_paddle
    jal draw_rect	# call function
    
    jal game_loop
    
    
    
   

    
  
    
    #----------walls draw--
    ## draw_walls function which draws wall on either side of the wall and it will draw 2 walls with lengths verically down
`   draw_TWO_walls:
    lw $t0, 0($a1)              # loads the initial display address

    li $t1, 0                   # load the value 0 to $t1 (for loop i = 0)
    lw $t2, 0($a2)		# load the end of y position in $t2

    outer_draw_walls:
    beq $t1, $t4, end_draw_walls  # if $t1 is 32 end the loop 
inner_draw_walls: 
        sw $t0, ($t3)            # draw a pixel at the current location of the memory (color stored in $t0)     
        sw $t0, 124($t3)         # draw a pixel at the current location of the memory (color stored in $t0) on the opp side

        addi $t3, $t3, 128      # Go to the next line ($t3 = $t3 + 128)
        addi $t1, $t1, 1        # increment $t1 ($t1 = $t1 + 1)
        b loop_draw_walls       #  run the loop again

end_draw_walls:
    jr $ra                     # return the function



    # ---------walls end draw
    
  #----ceiling draw
  # the function for drawing ceiling 
draw_ceiling:
    lw $t0, 0($a1)              # loads the 32 bit value from $a1 to $t0 basically getting the colour white, colour = colour_address

    # Initialize loop variables
    li $t1, 0                   # load immidiately in $t1 the value 0, (for loop i = 0)
    la $t3, ($a0)               # loads in memory address of $a0 (t3 starting address of the array of wall units.
    li $t4, 32
loop_draw_ceiling:
    beq $t1, $t4, end_draw_ceiling  # if $t1 is 32 end the loop 
inner_draw_ceiling:
        sw $t0, ($t3)          # Paint unit with colour
        addi $t3, $t3, 4      # Go to next unit
    addi $t1, $t1, 1          # increment $t1 ($t1 = $t1 + 1)
    b loop_draw_ceiling       #  run the loop again

end_draw_ceiling:
    jr $ra                    # return the function

#----ciling draw---
    
    
    
# function for drawing black   
draw_ball:
    lw $a0, ADDR_DSPL  # load starting address as the address
    la $t1, BALL       # Storing ball's refernece address 
    lw $t2, 0($t1)     # loading ball's intial x coodinate 
    sll $t2, $t2, 2
    lw $t3, 4($t1)     # loading ball's intial y coodinate 
    li $t4, 128        # loading value 128 in register t4
    mult $t4, $t3      # multiply 128 and y coordinate to get the required pixel ( turning 2d to 1D 128*y plus x *4)
    mflo $t4           # storing the multiplied value in t4
    add $t4, $t4, $t2  # storing t4 plus t2 into register t4
    add $a0, $a0, $t4	# put drawing location into $a0
    addi $a1, $zero, 1	# put the heigth into $a1
    addi $a2, $zero, 1	# put the width into $a2,
    # lw $a3, WHITE	# put the colour white into $a3
    
    jr $ra   
    
    # ------------Paddle-------------

# function for drawing black   
draw_paddle:

    lw $a0, ADDR_DSPL  # load starting address as the address
    add $t1, $zero, $s0	# load paddle's x location
    sll $t1, $t1, 2	# multiply 4
    add $t2, $zero, $s1     # loading ball's intial y coodinate 
    li $t3, 128        # loading value 128 in register t4
    mult $t3, $t2      # multiply 128 and y coordinate to get the required pixel ( turning 2d to 1D 128*y plus x *4)
    mflo $t3           # storing the multiplied value in t4
    add $t3, $t3, $t1  # storing t4 plus t2 into register t4
    add $a0, $a0, $t3	# put drawing location into $a0
    
    addi $a1, $zero, 1	# put the heigth into $a1
    addi $a2, $zero, 5	# put the width into $a2,
    # lw $a3, WHITE	# put the colour white into $a3
    
    jr $ra   
    
    
draw_bricks:
    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # load immidiately in $t1 the value 0, (for loop i = 0)
    li $t5, 384
    la $t3, 0($a0)              # loads in memory address of $a0 (t3 starting address of the array of wall units.
    add $t3, $t3, $t5          # initial position of the t3 starting address of the array of wall units.
draw_bricks_loop:
    lw $t0, 0($a1)              # colour = red

    slt $t2, $t1, $a2           # i < width of the display 
    beq $t2, $zero, draw_bricks_epi  # if not, then done

        sw $t0, 4($t3)          # Paint unit below with colour
        lw $t0, 4($a1)          # colour = blue
        
        sw $t0, 132($t3)          # Paint unit below with colour
        lw $t0, 8($a1)              # colour = green
        
        sw $t0, 260($t3)          # Paint unit with colour
        addi $t3, $t3, 4       # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    b draw_bricks_loop

draw_bricks_epi:
    jr $ra
        
        
MOVE_BALL: 
       la $t0, BALL    # store ball's reference
       lw $t1, ($t0)   # load ball's x coordinate 
       lw $t2, 4($t0)  # load ball's y coordinate 
       lw $t3, 8($t0)  # load ball's x direction
       lw $t4, 12($t0) #  load ball's y direction
       add $t1, $t1, $t3  # adding x direction to x coordinate 
       add $t2, $t2, $t4  # adding y direction to y coordinate
       sw $t1, ($t0)     # updating ball's x coordinate
       sw $t2, 4($t0)    # updating ball's y coordinate      
       jr $ra


collision_check: 
       la $t0, BALL    # store ball's reference
       lw $t1, ($t0)   # load ball's x coordinate 
       lw $t2, 4($t0)  # load ball's y coordinate 
       sll $t1, $t1, 2    # x coordinate times 4  in t1
       li $t4, 128        # loading value 128 in register t4
       mult $t4, $t2      # multiply 128 and y coordinate to get the required pixel ( turning 2d to 1D 128*y plus x *4)
       mflo $t4           # storing the multiplied value in t4
       add $t4, $t4, $t1  # storing t4 plus t2 into register t4
       lw $a0, ADDR_DSPL  # load starting address as the address
       add $t4, $a0, $t4	# put drawing location into $a0
       li $t3,1           # stores value 1 in t3 
       li $t5,30          # stores value 30 in t3
       lw $t1, ($t0)      # loading balls reference in t1
       beq $t1,$t3,side   # check if its in the left most coordinate 
       beq $t1,$t5,side   # check if its in the right most coordinate  
       lw $t4, ($t4)      # finds the colour in the pixel
       lw $t5, BLACK      # loads the colour black 
       beq $t4, $t5, fail # checking if this pixel has nothing
       lw $t5, YELLOW      # loading white in t5
       beq $t4, $t5, fail # checking iff the pixel is the ball itself
       lw $t5  12($t0)    # load the y direction 
       neg $t5, $t5       # changing the direction of y direction (making it oppposite)
       sw $t5, 12($t0)    # updating ball's y direction
       jr $ra         
       side:
       lw $t4, 8($t0)     # loading the value of x direction 
       neg $t4, $t4       # changing the direction of x direction (making it oppposite)
       sw $t4, 8($t0)     # updating ball's x direction
       jr $ra    
       fail: 
          jr $ra 
    

    
    
# -----------------PLAY------------------------------------------------

# $t0 keyboard address
# $t1 display address
# $s0 is the left side of paddle location
# $t5 colour white
# $t6 is colour black
# $t8 first keyboard address
game_loop:

# $s0 is the paddle current location of paddle's left most pixel


	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    
    	li 		$v0, 32
	li 		$a0, 1
	syscall 	#syscall to read key board input

    lw $t0, ADDR_KBRD              # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    
    lw $a3, BLACK            # making previous ball position black
    jal draw_ball            # drawing the ball 
    jal draw_rect      
    #5. Go back to 1
    jal MOVE_BALL            # moving the ball
    jal collision_check     # is checking for collision
    lw $a3, YELLOW           # makes the ball's new position white 
    jal draw_ball
    jal draw_rect
    li $a0, 100				#Stores 100 in first argument
    li $v0, 32				# pause for 100 milisec to make sure the ball doesnt go too fast
    syscall
    
    b game_loop


keyboard_input:                     # A key is pressed

    lw $a0, 4($t0)                  # Load second word from keyboard
    #ASCII q=0x71
    #ASCII a=0x61
    #ASCII d=0x64
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x61, respond_to_a     # Check if the key a was pressed
    beq $a0, 0x64, respond_to_d     # Check if the key d was pressed
        
    li $v0, 1                       # ask system to print $a0
    syscall

    b game_loop
    
respond_to_d:#what to do if d is pressed




	# check if the x location is at the right wall
	beq $s0, 26, game_loop
	# invariant: we are not at a wall here
	# paint current paddle location black
	lw $a3, BLACK
	jal draw_paddle
	jal draw_rect
	
	# move the paddle right by 1
	
	
       add $t1, $s0, $zero   # load paddle's x coordinate 
       add $t2, $s1, $zero   # load paddle's y coordinate 
       add $t3, $s2, $zero   # load paddle's x direction
       
       add $t1, $t1, $t3  # adding x direction to x coordinate 
       
	add $s0, $zero, $t1	# update $s0
       
       lw $a3, WHITE
	jal draw_paddle
	jal draw_rect
	j game_loop



respond_to_a:

	# get the right most ide of paddle location
	# will be in $a0
	# check paddle's x location if 4, then it is at the wall
	
	# if the location of left most pizel of paddle, -4 is divisible by 128, then we have hit a wall
	
	beq $s0, 1, game_loop
	# invariant: we are not at a wall here
	# paint current paddle location black
	lw $a3, BLACK
	jal draw_paddle
	jal draw_rect
	
	# move the paddle right by 1
	

       neg $t3, $s2 # make the x direction negative
       add $t1, $s0, $t3  # adding x direction to x coordinate 
       
       add $s0, $zero, $t1     # updating paddle's x coordinate
       
       lw $a3, WHITE
	jal draw_paddle
	jal draw_rect
	
	j game_loop

	

respond_to_Q:

	li $v0, 10                      # Quit gracefully
	syscall
	

	

    #----------------------------------------------
    
    
    
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    
    b game_loop








#-------------- helper Function to draw scene--------------------------

# code from lecture 

# the rectangle draeing function takes in the following:
# $a0 pass values to a function: starting location for drawing the rectangle
#  $a1: width of rectangle
# $s2: heaight of rectangle
# $a3: the colour of the rectangle

draw_rect: #function
# put what is in $a's and put them in temproary registers so we don't change the calue of the arguments
add $t5, $zero, $a0# put drawing location into $t5
add $t6, $zero, $a1# put the heigth into $t6
add $t7, $zero, $a2# put the width into $t7,
add $t8, $zero, $a3# put the colour into $t8

outer_loop:
# if the height variable is 0, then jump to end
beq $t6, $zero, end_outer_loop # if the height variable is 0, then jump to the end of the outer loop
# drawing a line - start from $t0

inner_loop:
beq $t7, $zero, end_inner_loop # if the width variable is 0, then jump to the end of the inner loop
sw $t8, 0($t5)# draw a pixel at the current location 
addi $t5, $t5, 4# move the vurrent drawing location to the right (pixel)
addi $t7, $t7, -1 # decrement the width variable
j inner_loop# repeat the inner loop


end_inner_loop:
addi $t6, $t6, -1	# decrement the height variable
add $t7, $zero, $a2	# reset the width variable to $a2 (initial)
# housekeeping: reset the current drawing location to the first pixel of the next line
addi $t5, $t5, 128 # move $t0 to the next line
sll $t1, $t7, 2		# convert t2  (num pixels to draw)to bytes - multiply by 4 
sub $t5, $t5, $t1	# move t0 to the fist pixel to draw in this like
j outer_loop	# jump to the beginning of the outer loop


end_outer_loop:		# the end of the rectangle drawing 
jr	$ra	# return to the calling program


# give dimension, call multiple times and make the boxes


#------------------------------Helper Function to draw scene-----------------------------------------------------
   
   #done
