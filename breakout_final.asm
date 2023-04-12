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

BRICKCOLOURS:
    .word 0xff0000 # colour red
    .word 0x0000ff # colour blue
    .word 0x00ff00 #colour green
    
# ball locations and coordinates

BALL: 
   .word 16  # x coordinate 
   .word 16  # y coordinate 
   .word 1   # x direction (right is 1, left is -1) 
   .word -1  # y direction (down is 1, up is -1)
   
 NUM_LIVES:
 	.word 3 # number of lives we have
   
GAME_OVER_location:
	.word 12 # xlocation
	.word 12 #y location
	

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################


	.text
	.globl main

# paddle data 
addi $s0, $zero, 12	# paddle x location
addi $s1, $zero, 24	#paddle y location
addi $s2, $zero, 1	# paddle x movement



main:
    # Initialize the game
    
    #draw walls make them gray
    # play game after 1 sec
    li $a0, 1000				#Stores 1 second in first argument
    li $v0, 32				# pause for 1 sec to make sure the ball doesnt go too fast
    syscall
    
    lw $a0, ADDR_DSPL   #Put starting address as the address argument for painting walls
    la $a1, GRAY	# load the grey color 
    li $a2, 31			# 31 units of height for the walls
    jal static_walls               # Draw the grey wall
    
    jal static_ceiling         # draw the ceiling of the wall has same parameters as wall
    
    la $a1, BRICKCOLOURS
    #li $a2, 30
    jal static_bricks             # Draws 3 rows of bricks at $a0
    la $a1, GRAY 
    jal static_unbreakable_bricks
    
    lw $a3,WHITE
    jal static_ball
    jal draw_rect	# call function
    
    
    # remove paddle
	lw $a3, BLACK
	jal static_paddle
	jal draw_rect	# call function
	#reset paddle
	# paddle data 
	addi $s0, $zero, 12	# paddle x location
	addi $s1, $zero, 24	#paddle y location
	addi $s2, $zero, 1	# paddle x movement

    #redraw paddle
    lw $a3, YELLOW
    jal static_paddle
    jal draw_rect	# call function
    
    jal game_loop
    
    

    
   

 
    
# -----------------PLAY------------------------------------------------


game_loop:


    
    	li 		$v0, 32
	li 		$a0, 1
	syscall 	#syscall to read key board input

    lw $t0, ADDR_KBRD              # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    jal collision_check     # is checking for collision

    lw $a3, BLACK            # making previous ball position black
    jal static_ball            # drawing the ball 
    jal draw_rect      
    
    jal dynamic_ball            # change the ball's location (x and y value at BALL[0] and BALL[1])
    
    la $t2, BALL	# load all  ball properties to $t2
    addi $t1, $zero, 31	# store 31 - max y location - in $t1
    lw $t2, 4($t2)	# store y location of ball in $t2
    bgt $t2, $t1, reached_bottom_of_screen	# if the ball reaches the bottom of the display, retart the game.
    
    
    

    # draw new ball location
    lw $a3, WHITE           # makes the ball's new position white 
    jal static_ball
    jal draw_rect
    
    
    li $a0, 100				# we are storing 100 in register $a0
    li $v0, 32				# inorder to mkae the ball move slowly pause the game(sleep)
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
    beq $a0, 0x70, respond_to_p     # Check if the key p was pressed
        
    li $v0, 1                       # ask system to print $a0
    syscall

    b game_loop
    
respond_to_d:#what to do if d is pressed




	# check if the x location is at the right wall
	beq $s0, 26, game_loop
	# invariant: we are not at a wall here
	# paint current paddle location black
	lw $a3, BLACK
	jal static_paddle
	jal draw_rect
	
	# move the paddle right by 1
	
	
       add $t1, $s0, $zero   # load paddle's x coordinate 
       add $t2, $s1, $zero   # load paddle's y coordinate 
       add $t3, $s2, $zero   # load paddle's x direction
       
       add $t1, $t1, $t3  # adding x direction to x coordinate 
       
	add $s0, $zero, $t1	# update $s0
       
       lw $a3, YELLOW
	jal static_paddle
	jal draw_rect
	j game_loop
	
respond_to_p:	
	lw $t0, ADDR_KBRD              # $t0 = base address for keyboard
    	lw $t8, 0($t0)                  # Load first word from keyboard
    	beq $t8, 1, unpause      	# If first word 1, key is pressed
	b respond_to_p
	unpause:
	lw $a0, 4($t0)                  # Load second word from keyboard
	beq $a0, 0x70, execute_unpause     # Check if the key p was pressed
	b respond_to_p
	execute_unpause:
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
	jal static_paddle
	jal draw_rect
	
	# move the paddle right by 1
	

       neg $t3, $s2 # make the x direction negative
       add $t1, $s0, $t3  # adding x direction to x coordinate 
       
       add $s0, $zero, $t1     # updating paddle's x coordinate
       
       lw $a3, YELLOW
	jal static_paddle
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





####### HELPER FUNCTIONS###########


reached_bottom_of_screen:

la $t8, NUM_LIVES	# load the number of lives we have
lw $t7, 0($t8)
addi $t7, $t7, -1 # decrement the num lives

# reset initial ball location because ball is at bottom of screen right now
la $t0, BALL    # store ball's reference
lw $t1, ($t0)   # load ball's x coordinate 
lw $t2, 4($t0)  # load ball's y coordinate 
lw $t3, 8($t0)  # adding x direction to x coordinate 
lw $t4, 12($t0)  # adding y direction to y coordinate

addi $t1, $zero, 16  # adding x direction to x coordinate 
addi $t2, $zero, 16  # adding y direction to y coordinate
addi $t3, $zero, 1  # adding x direction to x coordinate 
addi $t4, $zero, -1  # adding y direction to y coordinate
sw $t1, ($t0)     # updating ball's x coordinate
sw $t2, 4($t0)    # updating ball's y coordinate    
sw $t3, 8($t0)  # adding x direction to x coordinate 
sw $t4, 12($t0)  # adding y direction to y coordinate




beq $t7, $zero, GAME_OVER
sw $t7, 0($t8)# put numlives back
b main
# is num lives is greater than 0, replay.





###### HELPER
GAME_OVER:

# reset screen
li $t0, 0xffffff # white
li $t1, 0x000000 # black

la $t2, ADDR_DSPL
lw $t3, 0($t2)# $t3 is the current pixel location


# First row all black pixels
addi $t4, $zero, 32	# counter for first row
first_row:
beq $t4, $zero, second_row
sw $t1, 0($t3)
addi $t3, $t3, 4
addi $t4, $t4, -1	# go to next pixel
j first_row


second_row:

# for 6 pixels, draw black
addi $t4, $zero, 6	# counter for first row
black_space_row:
beq $t4, $zero, done
sw $t1, 0($t3)
addi $t3, $t3, 4
addi $t4, $t4, -1	# go to next pixel
j black_space_row

done:
# start white pixels

sw $t0, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)

#B
addi $t3, $t3, 4
sw $t1, 0($t3)

addi $t3, $t3, 4
sw $t1, 0($t3)

addi $t3, $t3, 4
sw $t1, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)

addi $t3, $t3, 4
sw $t1, 0($t3)

addi $t3, $t3, 4
sw $t1, 0($t3)

addi $t3, $t3, 4
sw $t1, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)


addi $t3, $t3, 4
sw $t0, 0($t3)

addi $t3, $t3, 4
sw $t1, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)

addi $t3, $t3, 4
sw $t1, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)

addi $t3, $t3, 4
sw $t0, 0($t3)

addi $t3, $t3, 4
# for 6 pixels, draw black
addi $t4, $zero, 6	# counter for first row
black_space_row2:
beq $t4, $zero, done2
sw $t1, 0($t3)
addi $t3, $t3, 4
addi $t4, $t4, -1	# go to next pixel
j black_space_row2

done2:


sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4


sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4



addi $t4, $zero, 64	# counter for first row
empty_row:
beq $t4, $zero, full_second_row
sw $t1, 0($t3)
addi $t3, $t3, 4
addi $t4, $t4, -1	# go to next pixel
j empty_row


full_second_row:

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4


sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4


sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4
sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4

sw $t1, 0($t3)
addi $t3, $t3, 4

sw $t0, 0($t3)
addi $t3, $t3, 4
sw $t0, 0($t3)
addi $t3, $t3, 4

# First row all black pixels
addi $t4, $zero, 608	# counter for first row
last_row:
beq $t4, $zero, final_row
sw $t1, 0($t3)
addi $t3, $t3, 4
addi $t4, $t4, -1	# go to next pixel
j last_row


final_row:

# wait for restart signal 
	li 		$v0, 32
	li 		$a0, 1
	syscall 	#syscall to read key board input

    lw $t0, ADDR_KBRD              # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input_end      # If first word 1, key is pressed
    

keyboard_input_end:                     # A key is pressed

    lw $a0, 4($t0)                  # Load second word from keyboard
    #ASCII r = 0x72
    beq $a0, 0x72, respond_to_r     # Check if the key q was pressed
    
        
    li $v0, 1                       # ask system to print $a0
    syscall

    b GAME_OVER
    
respond_to_r:#what to do if r is pressed
	# reset the screen
	# First row all black pixels
	li $t1, 0x000000 # black

	la $t2, ADDR_DSPL
	lw $t3, 0($t2)# $t3 is the current pixel location

	
	addi $t4, $zero, 1024	# counter for first row
	empty_it:
	beq $t4, $zero, empty_it_done
	sw $t1, 0($t3)
	addi $t3, $t3, 4
	addi $t4, $t4, -1	# go to next pixel
	j empty_it
	
	empty_it_done:
	#restore lives,
	# restart main
	b main




	

#-------------- helper Function to draw scene--------------------------

# citation:code from lecture reused for function calls

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
   
      
  
    #----------walls draw function -------
    ## draw_walls function which draws wall on either side of the ceiling and it will draw 2 walls with lengths verically down
static_walls:
    lw $t0, 0($a1)              # loads the 32 bit value from $a1 to $t0 basically getting the colour grey, colour = colour_address from the argument

    li $t1, 0                   # load value 0 into in $t1 for starting loop
    la $t3, ($a0)             # loads in memory address of $a0 (t3 starting address of the array of wall units.
    la $t4, ($a2)

loop_draw_walls:
    # checking if the loop counter $t1 has reached max width for walls, which is stored in $a2 
    beq $t1, $t4, end_draw_walls  # if $t1 is 31 end the loop 
inner_draw_walls: 
        sw $t0, ($t3)            # draw a pixel at the current location of the memory (color stored in $t0)     
        sw $t0, 124($t3)         # draw a pixel at the current location of the memory (color stored in $t0) on the opp side

        addi $t1, $t1, 1        # increment $t1 ($t1 = $t1 + 1)
        addi $t3, $t3, 128      # Go to the next line ($t3 = $t3 + 128)
        b loop_draw_walls       #  run the loop again

end_draw_walls:
    jr $ra                     # return the function



    # ---------function walls end draw ---------------
    
  #----ceiling draw----
  # the function for drawing ceiling 
static_ceiling:
    lw $t0, 0($a1)              # loads the 32 bit value from $a1 to $t0 basically getting the colour grey, colour = colour_address

    # Initialize loop variables
    li $t1, 0                   # load immidiately in $t1 the value 0, (for loop i = 0)
    la $t3, ($a0)               # loads in memory address of $a0 (t3 starting address of the array of wall units.
    li $t4, 32
loop_draw_ceiling:
    beq $t1, $t4, end_draw_ceiling  # if $t1 is 32 end the loop 
inner_draw_ceiling:
        sw $t0, ($t3)          # draw a pixel at the current location of the memory (color stored in $t0) 
        addi $t3, $t3, 4      # increment by 4 in order to go the next pixel 
    addi $t1, $t1, 1          # increment $t1 ($t1 = $t1 + 1)
    b loop_draw_ceiling       #  run the loop again

end_draw_ceiling:
    jr $ra                    # return the function

#----ciling draw end ---
    
static_bricks:
    
    li $t1, 0                   # load immidiately in $t1 the value 0, (for loop i = 0)
    li $t5, 384                 # store the value 384 in t5 for the drawing the bricks somewhat in the middle location of 1st row of bricks
    la $t3, 0($a0)              # loads in memory address of $a0 (t3 starting address of the array of wall units.
    add $t3, $t3, $t5          # initial position of the t3 starting address of the array of wall units.
    li $t4, 30                 # load value 30 for comparing with the loop counter
loop_draw_bricks:
    lw $t0, 0($a1)              # colour stored in the first item in the array in a1 = red
    beq $t1, $t4, end_bricks    # if the counter is equal to the width mentioned in t4 then end the loop
    
inner_brick_loop:
        sw $t0, 4($t3)          # draw a pixel at the current location of the memory (color stored in $t0 red) 
        lw $t0, 4($a1)          # colour stored in the second item in the array in a1= blue
        
        sw $t0, 132($t3)         # draw a pixel in the next row in the memory (color stored in $t0 blue) 
        
        lw $t0, 8($a1)            # colour stored in the second item in the array in a1= green
        sw $t0, 260($t3)         # draw a pixel in the next row in the memory (color stored in $t0 green) 
        
        addi $t3, $t3, 4       # increment by 4 in order to go the next pixel

    addi $t1, $t1, 1            # increment $t1 ($t1 = $t1 + 1)
    b loop_draw_bricks
end_bricks:
    jr $ra   
    
# function for drawing black   
static_ball:
    lw $a0, ADDR_DSPL  # load starting address as the address
    la $t1, BALL       # Storing ball's refernece address 
    lw $t2, 0($t1)     # loading ball's intial x coodinate 
    sll $t2, $t2, 2	# 1 pixel is 4 units so I'm going to multiply the x location by 4
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
    
    
game_over_pix:
	lw $a0, ADDR_DSPL  # load starting address as the address
    la $t1, GAME_OVER_location       # Storing ball's refernece address 
    lw $t2, 0($t1)     # loading ball's intial x coodinate 
    sll $t2, $t2, 2	# 1 pixel is 4 units so I'm going to multiply the x location by 4
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
static_paddle:

    lw $a0, ADDR_DSPL  # load starting address as the address
    add $t1, $zero, $s0	# load paddle's x location
    sll $t1, $t1, 2	# multiply 4 for x location in pixel
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
    
    

        
        
dynamic_ball: 
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
	# check ball location 
       la $t0, BALL    # store ball's reference
       
       #check walls
       li $t3,1           # stores value 1 in t3 
       li $t5,30          # stores value 30 in t3
       lw $t1, ($t0)      # loading balls x loc reference from .data in t1 
       # check if ball is at the left wall
       beq $t1,$t3,side   # check if its in the left most coordinate 
       # check if ball is at rigth wall
       beq $t1,$t5,side   # check if its in the right most coordinate  
       # chekc if ball is at the ceiling
       lw $t5, 4($t0)
       beq $t3, $t5, top
       
       # invariant: we are not at ceiling or walls
       
       
       #check top of the ball
       lw $t1, ($t0)   # load ball's x coordinate 
       lw $t2, 4($t0)  # load ball's y coordinate 
       addi $t2,$t2,-1
       
       #t1,t2 top of ball
       
       # convert2dto1d, assume t1 is x, t2 is y, $t4 is the converted value
       sll $t1, $t1, 2    # x coordinate times 4  in t1 so that I get the x value in pixels (1 pixel is 4 units)
       li $t4, 128        # loading value 128 in register t4
       mult $t4, $t2      # multiply 128 and y coordinate to get the required pixel ( turning 2d to 1D 128*y plus x *4)
       mflo $t4           # storing the multiplied value in t4
       add $t4, $t4, $t1  # storing t4 plus t1 into register t4
       lw $a0, ADDR_DSPL  # load starting address as the address
       add $t4, $a0, $t4	# put drawing location into $a0
       # ended
       
       # ball's top loc (1d) is in $t4
       
       #check what color is in ball's top
       move $t6,$t4
    
       lw $t4, ($t4)      # finds the colour in the pixel that is stored at the painted location of the ball location 
       lw $t5, BLACK      # loads the colour black 
       
       beq $t4, $t5, check_bottom # checking if this pixel has nothing (is black)
       
       lw $t9, GRAY
       beq $t4, $t9, grey_brick
       
       lw $t9, YELLOW
       beq $t4, $t9, yellow_brick	# will now break
       
       # invariant - we know that we must be at a colored brick that is not yet yellow
       lw $t5  12($t0)    # load the y direction 
       neg $t5, $t5       # changing the direction of y direction (making it oppposite)
       sw $t5, 12($t0)    # updating ball's y direction
       lw $a3, YELLOW
	sw $a3, ($t6)
	sw $a3, ($t6)
	#make osund
        li $v0, 31
       li $a0, 70
       li $a1, 105
       li $a2, 126
       li $a3, 120
       syscall
       jr $ra
         
        yellow_brick:# now, we can make the brick black
        # invariant - we know that we must be at a colored brick that is not yet yellow
       lw $t5  12($t0)    # load the y direction 
       neg $t5, $t5       # changing the direction of y direction (making it oppposite)
       sw $t5, 12($t0)    # updating ball's y direction
       lw $a3, BLACK
	sw $a3, ($t6)
	sw $a3, ($t6)
	#make osund
        li $v0, 31
       li $a0, 70
       li $a1, 105
       li $a2, 126
       li $a3, 120
       syscall
       jr $ra
         
        
       
 	check_bottom:
 	
 	lw $t1, ($t0)   # load ball's x coordinate 
       	lw $t2, 4($t0)  # load ball's y coordinate 
       	addi $t2,$t2,1
       
       #t1,t2 bottom of ball
       
       # convert2dto1d, assume t1 is x, t2 is y, $t4 is the converted value
       sll $t1, $t1, 2    # x coordinate times 4  in t1 so that I get the x value in pixels (1 pixel is 4 units)
       li $t4, 128        # loading value 128 in register t4
       mult $t4, $t2      # multiply 128 and y coordinate to get the required pixel ( turning 2d to 1D 128*y plus x *4)
       mflo $t4           # storing the multiplied value in t4
       add $t4, $t4, $t1  # storing t4 plus t1 into register t4
       lw $a0, ADDR_DSPL  # load starting address as the address
       add $t4, $a0, $t4	# put drawing location into $a0
       # ended
       
       #t4 is now bottom of ball in 1d
       addi $t7,$t4,4     # load the balls right location to t7
       lw $t7,($t7)       # store value inside (t7)
       addi $t9,$t4,-4    # load the balls left location to t9
        lw $t9,($t9)      # store value inside (t9)
       lw $t4, ($t4)      # finds the colour in the pixel that is stored at the painted location of the ball location 
       lw $t5, BLACK      # loads the colour black
       lw  $t6, YELLOW    # load the color yellow
       
       beq $t4, $t6, hit_paddle # checking if the ball hit the paddle
       beq $t7, $t6, hit_paddle # checking if the ball's left side hit the paddle
       beq $t9, $t6, hit_paddle # checking if the ball's right side hit the paddle
       
       
       beq $t4, $t5, fail # checking if this pixel has nothing (is black)
       
       lw $t5, YELLOW     # loading white in t5 check if the pixel is yellow
       beq $t4, $t5, fail # checking iff the pixel is the ball itself?
       
       
 	       
       # invariant - we are not at the wall, ceiling
       # don't worry about collisions anymore
       

       
            # if it collides, goes here     
       side:
       lw $t4, 8($t0)     # loading the value of x direction 
       neg $t4, $t4       # changing the direction of x direction (making it oppposite)
       sw $t4, 8($t0)     # updating ball's x direction
       li $v0, 33
       li $a0, 50
       li $a1, 100
       li $a2, 120
       li $a3, 125
       syscall
       jr $ra    
       top: 
       lw $t4, 12($t0)     # loading the value of x direction 
       neg $t4, $t4       # changing the direction of x direction (making it oppposite)
       sw $t4, 12($t0)     # updating ball's x direction
       li $v0, 33
       li $a0, 50
       li $a1, 100
       li $a2, 120
       li $a3, 125
       syscall
       jr $ra    
       fail: # update ball location
          jr $ra 
          
       grey_brick:
       lw $t5  12($t0)    # load the y direction 
       neg $t5, $t5       # changing the direction of y direction (making it oppposite)
       sw $t5, 12($t0)    # updating ball's y direction
       li $v0, 33
       li $a0, 50
       li $a1, 100
       li $a2, 5
       li $a3, 70
       #li $v0, 33
       syscall
       jr $ra   
       
       hit_paddle:
       lw $t5  12($t0)    # load the y direction 
       neg $t5, $t5       # changing the direction of y direction (making it oppposite)
       sw $t5, 12($t0)    # updating ball's y direction
       li $v0, 33
       li $a0, 50
       li $a1, 100
       li $a2, 5
       li $a3, 70
       #li $v0, 33
       syscall
       jr $ra   
       	
          
   

static_unbreakable_bricks:
lw $t0, ($a1)              # loads the 32 bit value from $a1 to $t0 basically getting the colour grey, colour = colour_address
la $t3, ($a0)               # loads in memory address of $a0 (t3 starting address of the array of wall units.
sw $t0, 400($t3)          # draw a pixel at the current location of the memory (color stored in $t0)        
sw $t0, 404($t3)          # draw a pixel at the current location of the memory (color stored in $t0) 
sw $t0, 572($t3)          # draw a pixel at the current location of the memory (color stored in $t0) 
sw $t0, 576($t3)          # draw a pixel at the current location of the memory (color stored in $t0) 
sw $t0, 744($t3)          # draw a pixel at the current location of the memory (color stored in $t0) 
sw $t0, 748($t3)          # draw a pixel at the current location of the memory (color stored in $t0) 
jr $ra 
    

    
   
   
   #done
   # final version 2
