#####################################################################
#
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
# 
#  Student: Name, Student Number, UTorID, official email
#  Zhitao Xu: 1006668697, xuzhitao, zhitao.xu@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed)
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1 - done
# - Milestone 2 - done
# - Milestone 3 - working on
# (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

.eqv base_address 0x10008000

# colours
.eqv BLACK 0x00000000
.eqv WHITE 0x00ffffff
.eqv ORANGE 0x00ff4800
.eqv RED 0x00ff0000
.eqv BLUE 0x000000ff
.eqv GREY 0x00808080
.eqv GOLDEN 0x00ffd700
.eqv PINK 0x00ff00c8
.eqv GREEN 0x0000ff00
.eqv WAITTIME 3
.eqv JUMP_COUNTER 5
# data need to store


.data
me_location: .word 6932
heart: .word 5
platform: .word 1692, 2240, 3908, 4924, 5976, 6836, 7564
offset: .word 512
jump_counter: .word 0
counter: .word 0
counter_for_floor: .word 150

.text 
.globl main

main: 
	
	# when start, clear the screen and draw the gamename
	jal clear_screen
	jal show_gamename
	# wait for 1.5s
	li $v0, 32
	li $a0, 2000
	syscall
	
start:
	# start of the game, press p come back here
	jal clear_screen
	# initialize the screen
	jal initialize_screen

	# get position of me and the floor in the map
	li $v0, 32
	li $a0, 500
	syscall


game_loop:
	la $t1, heart
	lw $t9, 0($t1)
	beqz $t9, gameover
	# load me_location to $t2

	la $t1, counter_for_floor
	lw $t2, 0($t1)
	# less than 0, do nothing
	bltz $t2, erase_floor_back
	# 0 - 150, 
	li $t3, 100
	beq $t2, $t3, erase_floor_pre_1
	li $t3, 50
	beq $t2, $t3, erase_floor_pre_2
	beq $t2, $zero, erase_floor_pre_3

erase_floor_back:
	la $t1, counter_for_floor
	lw $t2, 0($t1)
	bltz, $t2, less_than_0
	addi $t2, $t2, -1
	sw $t2, 0($t1)
less_than_0:

	la $t1, me_location
	lw $t2, 0($t1)
	# check the color under me (offset 512)
	addi $t4, $t2, 512
	
	# t2 is the position under me, compare t2 with white
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	
	bne $t3, BLACK, no_gravity # if color is not white, not falling
	
	# make sure the jump_count is 0 to fall
	la $t5, jump_counter
	lw $t6, 0($t5)
	bnez $t6, no_gravity
	
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, no_gravity # if color is not white, not falling
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, no_gravity # if color is not white, not falling
	# have gravity (in the space), falling
	
	move $a0, $t2
	jal erase_me
	li $a1, 128
	jal draw_me
	
no_gravity:

	# milestone 3
	# jal platform_update

	# able to control me
	jal me_update
	
update_done:

	# found if it wins
	# t2 is me
	la $t1, me_location
	lw $t2, 0($t1)
	addi $t4, $t2, -132
	# t4 is the current place 
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	# it touch the win item, end the game
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page

	addi $t0, $t0, -496
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page


	# heart conditions
	# if red die
	la $t1, me_location
	lw $t2, 0($t1)
	addi $t4, $t2, 512
	# t4 is the current place 
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	# it touch the win item, end the game
	beq $t3, RED, gameover

	# if blue, do nothing

	# if green or grey, heart - 1, continue
	# todo: grey
	# t2 is me
	la $t1, me_location
	lw $t2, 0($t1)
	addi $t4, $t2, -4
	# t4 is the current place 
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	# it touch the win item, end the game
	beq $t3, GREEN, touch_green_left
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_left
	addi $t0, $t0, 16
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_right
	addi $t0, $t0, -128
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_right

green_continue:

	# weight for 40ms for next loop
	li $v0, 32
	li $a0, 40
	syscall
	
	# la $t0, heart  # $t0 = address of SHIP_HEALTH
	# sw $t9, 0($t0)		# $t9 = ship health
	j game_loop


erase_floor_pre_1:
	li $a0, 7564
	jal erase_floor
	j erase_floor_back
erase_floor_pre_2:
	li $a0, 6960
	jal erase_floor
	j erase_floor_back
erase_floor_pre_3:
	li $a0, 6356
	jal erase_floor
	j erase_floor_back

touch_green_left:
	la $t1, me_location
	lw $t2, 0($t1)
	li $v0, 32
	li $a0, 200
	syscall
	move $a0, $t2
	jal erase_me
	li $a1, 4
	jal draw_me
	# heart -1
	jal erase_one_heart
	la $t1, heart
	lw $t2, 0($t1)
	addi $t2, $t2, -1
	sw $t2, 0($t1)
	j green_continue

touch_green_right:
	la $t1, me_location
	lw $t2, 0($t1)
	li $v0, 32
	li $a0, 200
	syscall
	move $a0, $t2
	jal erase_me
	li $a1, -4
	jal draw_me
	# heart -1
	jal erase_one_heart
	la $t1, heart
	lw $t2, 0($t1)
	addi $t2, $t2, -1
	sw $t2, 0($t1)

	j green_continue

erase_one_heart:
	la $t1, heart
	lw $t2, 0($t1)
	li $t3, 5
	beq $t2, $t3, have_5_heart
	li $t3, 4
	beq $t2, $t3, have_4_heart
	li $t3, 3
	beq $t2, $t3, have_3_heart
	li $t3, 2
	beq $t2, $t3, have_2_heart
	li $t3, 1
	beq $t2, $t3, have_1_heart
	jr $ra

have_5_heart:
	la $t0, base_address
	addi $t0, $t0, 196
	li $s0, BLACK
	sw $s0, 4($t0)
	sw $s0, 128($t0)
	sw $s0, 132($t0)
	sw $s0, 136($t0)
	sw $s0, 260($t0)
	jr $ra
have_4_heart:
	la $t0, base_address
	addi $t0, $t0, 180
	li $s0, BLACK
	sw $s0, 4($t0)
	sw $s0, 128($t0)
	sw $s0, 132($t0)
	sw $s0, 136($t0)
	sw $s0, 260($t0)
	jr $ra
have_3_heart:
	la $t0, base_address
	addi $t0, $t0, 164
	li $s0, BLACK
	sw $s0, 4($t0)
	sw $s0, 128($t0)
	sw $s0, 132($t0)
	sw $s0, 136($t0)
	sw $s0, 260($t0)
	jr $ra
have_2_heart:
	la $t0, base_address
	addi $t0, $t0, 148
	li $s0, BLACK
	sw $s0, 4($t0)
	sw $s0, 128($t0)
	sw $s0, 132($t0)
	sw $s0, 136($t0)
	sw $s0, 260($t0)
	jr $ra
have_1_heart:
	la $t0, base_address
	addi $t0, $t0, 132
	li $s0, BLACK
	sw $s0, 4($t0)
	sw $s0, 128($t0)
	sw $s0, 132($t0)
	sw $s0, 136($t0)
	sw $s0, 260($t0)
	jr $ra

me_update:
	# if the object is jumping, it need to jump and do the corresponding job (update the value)
	la $t5, jump_counter
	lw $t6, 0($t5)
	# if it's 0, then nothing, regular update
	# if it's not 0, updating and back
	bnez $t6, two_job


determine: 
	# get what from keyboard
	li $t8, 0xffff0000
	lw $t7, ($t8)
	
	bne $t7, 1, donothing1	# no input, go back to what caller
	lw $t7, 4($t8)				# have input, put input to t7
	
	# restart will be faster than anycase
	beq $t7, 112, A_RESTART		# if P was pressed
	# DETERMINE WHICH DIRECTION IT IS GOING
	beq $t7, 119, A_JUMP		# if w was pressed
	beq $t7, 97, A_LEFT			# if a was pressed
	beq $t7, 100, A_RIGHT		# if d was pressed
	beq $t7, 32, A_JUMP			# if space was pressed

	j update_done				# if not them, back to before
	
two_job:
	# count 5 time to proceed one jump, time to reflect
	la $s4, counter
	lw $s3, 0($s4)
	beqz $s3, t_JUMP
	addi $s3, $s3, -1
	sw $s3, 0($s4)
	
	# it's not 0, need to jump
	j determine

t_JUMP:
	# load me_location to $t2
	la $t1, me_location
	lw $t2, 0($t1)
	
	la $s4, counter
	li $s3, WAITTIME
	sw $s3, 0($s4)
	# make sure the jump_count is not 0 to indicate it's jumping
	la $t5, jump_counter
	lw $t6, 0($t5)
	# set the jump to current -1
	addi $t6, $t6, -1
	sw $t6, 0($t5)
	j t_actual_jump
	
t_actual_jump:
	addi $t4, $t2, -128
	# check if it's black
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	bne $t3, BLACK, t_donothing1 # if color is not white, not falling
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, t_donothing1 # if color is not white, not falling
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, t_donothing1 # if color is not white, not falling
	move $a0, $t2
	jal erase_me
	li $a1, -128
	jal draw_me

t_donothing1: 
	j determine

A_JUMP:
	# load me_location to $t2
	la $t1, me_location
	lw $t2, 0($t1)
	
	# make sure the jump_count is not 0 to indicate it's jumping
	la $t5, jump_counter
	li $s7, JUMP_COUNTER
	sw $s7, 0($t5)
	
	# set the counter to be 5
	la $t6, counter
	li $s6, WAITTIME
	sw $s6, 0($t6)

	j actual_jump
jump_twice:
	la $t1, me_location
	lw $t2, 0($t1)
	j actual_jump_2
	
actual_jump:
	addi $t4, $t2, -128
	# check if it's black
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing1 # if color is not white, not falling
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing1 # if color is not white, not falling
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing1 # if color is not white, not falling
	move $a0, $t2
	jal erase_me
	li $a1, -128
	jal draw_me

next_jump: 
	j jump_twice

actual_jump_2:
	addi $t4, $t2, -128
	# check if it's black
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing1 # if color is not white, not falling
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing1 # if color is not white, not falling
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing1 # if color is not white, not falling
	move $a0, $t2
	jal erase_me
	li $a1, -128
	jal draw_me
donothing1: 
	j update_done

A_LEFT:
	# load me_location to $t2
	la $t1, me_location
	lw $t2, 0($t1)
	addi $t4, $t2, -4
	# check if it's black
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing2 # if color is not white, not falling
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing2 # if color is not white, not falling
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing2 # if color is not white, not falling
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing2 # if color is not white, not falling
	move $a0, $t2
	jal erase_me
	li $a1, -4
	jal draw_me

donothing2: 
	j update_done

A_RIGHT:
	# load me_location to $t2
	la $t1, me_location
	lw $t2, 0($t1)
	addi $t4, $t2, 12
	# check if it's black
	la $t0, base_address
	add $t0, $t0, $t4
	lw $t3, 0($t0)
	bne $t3, BLACK, donothing3 # if color is not white, not falling
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing3 # if color is not white, not falling
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing3 # if color is not white, not falling
	addi $t0, $t0, 128
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing3 # if color is not white, not falling
	move $a0, $t2
	jal erase_me
	li $a1, 4
	jal draw_me

donothing3: 
	j update_done

A_RESTART:
	# set everything back
	la $t1, me_location
	li $s1, 6932
	sw $s1, 0($t1)

	la $t1, heart
	li $s1, 5
	sw $s1, 0($t1)

	la $t1, jump_counter
	li $s1, 0
	sw $s1, 0($t1)

	la $t1, counter
	li $s1, 0
	sw $s1, 0($t1)

	la $t1, counter_for_floor
	li $s1, 150
	sw $s1, 0($t1)

	j start
# platform_update:
	# update all the plateforms 
	# make them move left or right

draw_me:
	la $t0, base_address
	# load the position to me_location
	add $s0, $a0, $a1
	la $s1, me_location
	sw $s0, 0($s1)
	# draw correspond me
	add $t0, $t0, $s0
	
	li $s0, ORANGE
	sw $s0, 4($t0)
	sw $s0, 128($t0)
	sw $s0, 136($t0)
	sw $s0, 260($t0)
	sw $s0, 384($t0)
	sw $s0, 388($t0)
	sw $s0, 392($t0)
	jr $ra

gameover:
	li $v0, 32
	li $a0, 200
	syscall
	jal clear_screen
	jal draw_loss
	li $v0, 32
	li $a0, 2000
	syscall
	j A_RESTART

win_page:
	li $v0, 32
	li $a0, 200
	syscall
	jal clear_screen
	jal draw_win
	j restart_game


restart_game:
	la $t1, me_location
	li $s1, 6932
	sw $s1, 0($t1)

	la $t1, heart
	li $s1, 5
	sw $s1, 0($t1)

	la $t1, jump_counter
	li $s1, 0
	sw $s1, 0($t1)

	la $t1, counter
	li $s1, 0
	sw $s1, 0($t1)

	la $t1, counter_for_floor
	li $s1, 150
	sw $s1, 0($t1)

	# wait 3 second to end
	li $v0, 32
	li $a0, 3000
	syscall
	j main
erase_me:
	# a0 will have the address of me
	# make me black
	la $t0, base_address
	add $t0, $t0, $a0
	li $s0, BLACK
	sw $s0, 4($t0)
	sw $s0, 128($t0)
	sw $s0, 136($t0)
	sw $s0, 260($t0)
	sw $s0, 384($t0)
	sw $s0, 388($t0)
	sw $s0, 392($t0)
	jr $ra

erase_floor:
	la $t0, base_address
	add $t0, $t0, $a0
	li $s0, BLACK
	sw $s0, 0($t0)
	sw $s0, 4($t0)
	sw $s0, 8($t0)
	sw $s0, 12($t0)
	sw $s0, 16($t0)
	sw $s0, 20($t0)
	sw $s0, 24($t0)
	sw $s0, 28($t0)
	jr $ra

clear_screen:
	# t0 is the start address, t1 is black color, t2 is the counter
	la $t0, base_address
	li $t1, BLACK
	li $t2, 0 

clear_loop:
	bge $t2, 2048, clear_end # if counter is greater than or equal to 32*32 (256/8), it's end
	sw $t1, 0($t0)  # set current pixel to black
	addi $t0, $t0, 4 # move to next pixel
	addi $t2, $t2, 1 # counter = counter + 1
	j clear_loop

clear_end:
	jr $ra

show_gamename:
	# show the start page of the game
	la $t0, base_address
	# use two color, t1 and t2
	li $t1, WHITE
	li $t4, ORANGE
	li $t2, GOLDEN
	li $t3, RED
	sw $t1, 400($t0)
	sw $t1, 404($t0)
	sw $t1, 408($t0)
	sw $t1, 412($t0)
	sw $t1, 416($t0)
	sw $t1, 420($t0)
	sw $t1, 424($t0)
	sw $t1, 428($t0)
	sw $t1, 432($t0)
	sw $t1, 436($t0)
	sw $t1, 528($t0)
	sw $t1, 532($t0)
	sw $t1, 536($t0)
	sw $t1, 540($t0)
	sw $t1, 544($t0)
	sw $t1, 548($t0)
	sw $t1, 552($t0)
	sw $t1, 556($t0)
	sw $t1, 560($t0)
	sw $t1, 564($t0)
	sw $t1, 656($t0)
	sw $t1, 660($t0)
	sw $t1, 784($t0)
	sw $t1, 788($t0)
	sw $t1, 912($t0)
	sw $t1, 916($t0)
	sw $t1, 1040($t0)
	sw $t1, 1044($t0)
	sw $t1, 1048($t0)
	sw $t1, 1052($t0)
	sw $t1, 1056($t0)
	sw $t1, 1060($t0)
	sw $t1, 1064($t0)
	sw $t1, 1068($t0)
	sw $t1, 1168($t0)
	sw $t1, 1172($t0)
	sw $t1, 1176($t0)
	sw $t1, 1180($t0)
	sw $t1, 1184($t0)
	sw $t1, 1188($t0)
	sw $t1, 1192($t0)
	sw $t1, 1196($t0)
	sw $t1, 1296($t0)
	sw $t1, 1300($t0)
	sw $t1, 1424($t0)
	sw $t1, 1428($t0)
	sw $t2, 1492($t0)
	sw $t2, 1500($t0)
	sw $t2, 1508($t0)
	sw $t1, 1552($t0)
	sw $t1, 1556($t0)
	sw $t2, 1620($t0)
	sw $t2, 1624($t0)
	sw $t2, 1628($t0)
	sw $t2, 1632($t0)
	sw $t2, 1636($t0)
	sw $t1, 1680($t0)
	sw $t1, 1684($t0)
	sw $t1, 1688($t0)
	sw $t1, 1692($t0)
	sw $t1, 1696($t0)
	sw $t1, 1700($t0)
	sw $t1, 1704($t0)
	sw $t1, 1708($t0)
	sw $t1, 1712($t0)
	sw $t1, 1716($t0)
	sw $t2, 1752($t0)
	sw $t2, 1760($t0)
	sw $t1, 1808($t0)
	sw $t1, 1812($t0)
	sw $t1, 1816($t0)
	sw $t1, 1820($t0)
	sw $t1, 1824($t0)
	sw $t1, 1828($t0)
	sw $t1, 1832($t0)
	sw $t1, 1836($t0)
	sw $t1, 1840($t0)
	sw $t1, 1844($t0)
	sw $t1, 1864($t0)
	sw $t1, 1868($t0)
	sw $t1, 1872($t0)
	sw $t1, 1876($t0)
	sw $t1, 1880($t0)
	sw $t1, 1884($t0)
	sw $t1, 1888($t0)
	sw $t1, 1892($t0)
	sw $t1, 1896($t0)
	sw $t1, 1992($t0)
	sw $t1, 1996($t0)
	sw $t1, 2000($t0)
	sw $t1, 2004($t0)
	sw $t1, 2008($t0)
	sw $t1, 2012($t0)
	sw $t1, 2016($t0)
	sw $t1, 2020($t0)
	sw $t1, 2024($t0)
	sw $t1, 2120($t0)
	sw $t1, 2124($t0)
	sw $t1, 2248($t0)
	sw $t1, 2252($t0)
	sw $t1, 2376($t0)
	sw $t1, 2380($t0)
	sw $t1, 2504($t0)
	sw $t1, 2508($t0)
	sw $t1, 2512($t0)
	sw $t1, 2516($t0)
	sw $t1, 2520($t0)
	sw $t1, 2524($t0)
	sw $t1, 2528($t0)
	sw $t1, 2532($t0)
	sw $t1, 2632($t0)
	sw $t1, 2636($t0)
	sw $t1, 2640($t0)
	sw $t1, 2644($t0)
	sw $t1, 2648($t0)
	sw $t1, 2652($t0)
	sw $t1, 2656($t0)
	sw $t1, 2660($t0)
	sw $t1, 2704($t0)
	sw $t1, 2708($t0)
	sw $t1, 2712($t0)
	sw $t1, 2716($t0)
	sw $t1, 2720($t0)
	sw $t1, 2724($t0)
	sw $t1, 2728($t0)
	sw $t1, 2732($t0)
	sw $t1, 2784($t0)
	sw $t1, 2788($t0)
	sw $t1, 2832($t0)
	sw $t1, 2836($t0)
	sw $t1, 2840($t0)
	sw $t1, 2844($t0)
	sw $t1, 2848($t0)
	sw $t1, 2852($t0)
	sw $t1, 2856($t0)
	sw $t1, 2860($t0)
	sw $t1, 2912($t0)
	sw $t1, 2916($t0)
	sw $t1, 2960($t0)
	sw $t1, 2964($t0)
	sw $t1, 3040($t0)
	sw $t1, 3044($t0)
	sw $t1, 3088($t0)
	sw $t1, 3092($t0)
	sw $t1, 3140($t0)
	sw $t1, 3144($t0)
	sw $t1, 3148($t0)
	sw $t1, 3152($t0)
	sw $t1, 3156($t0)
	sw $t1, 3160($t0)
	sw $t1, 3164($t0)
	sw $t1, 3168($t0)
	sw $t1, 3172($t0)
	sw $t1, 3216($t0)
	sw $t1, 3220($t0)
	sw $t1, 3268($t0)
	sw $t1, 3272($t0)
	sw $t1, 3276($t0)
	sw $t1, 3280($t0)
	sw $t1, 3284($t0)
	sw $t1, 3288($t0)
	sw $t1, 3292($t0)
	sw $t1, 3296($t0)
	sw $t1, 3300($t0)
	sw $t1, 3344($t0)
	sw $t1, 3348($t0)
	sw $t1, 3472($t0)
	sw $t1, 3476($t0)
	sw $t1, 3600($t0)
	sw $t1, 3604($t0)
	sw $t1, 3728($t0)
	sw $t1, 3732($t0)
	sw $t1, 3856($t0)
	sw $t1, 3860($t0)
	sw $t1, 3864($t0)
	sw $t1, 3868($t0)
	sw $t1, 3872($t0)
	sw $t1, 3876($t0)
	sw $t1, 3880($t0)
	sw $t1, 3884($t0)
	sw $t1, 3888($t0)
	sw $t1, 3928($t0)
	sw $t1, 3984($t0)
	sw $t1, 3988($t0)
	sw $t1, 3992($t0)
	sw $t1, 3996($t0)
	sw $t1, 4000($t0)
	sw $t1, 4004($t0)
	sw $t1, 4008($t0)
	sw $t1, 4012($t0)
	sw $t1, 4016($t0)
	sw $t1, 4052($t0)
	sw $t1, 4056($t0)
	sw $t1, 4060($t0)
	sw $t1, 4176($t0)
	sw $t1, 4180($t0)
	sw $t3, 4184($t0)
	sw $t1, 4188($t0)
	sw $t1, 4192($t0)
	sw $t1, 4304($t0)
	sw $t3, 4308($t0)
	sw $t3, 4312($t0)
	sw $t3, 4316($t0)
	sw $t1, 4320($t0)
	sw $t1, 4428($t0)
	sw $t1, 4432($t0)
	sw $t3, 4436($t0)
	sw $t3, 4440($t0)
	sw $t3, 4444($t0)
	sw $t1, 4448($t0)
	sw $t1, 4452($t0)
	sw $t1, 4556($t0)
	sw $t1, 4560($t0)
	sw $t1, 4564($t0)
	sw $t1, 4568($t0)
	sw $t1, 4572($t0)
	sw $t1, 4576($t0)
	sw $t1, 4580($t0)
	sw $t1, 4680($t0)
	sw $t1, 4684($t0)
	sw $t1, 4708($t0)
	sw $t1, 4712($t0)
	sw $t1, 4804($t0)
	sw $t1, 4808($t0)
	sw $t1, 4840($t0)
	sw $t1, 4844($t0)
	sw $t1, 4880($t0)
	sw $t1, 4884($t0)
	sw $t1, 4888($t0)
	sw $t1, 4892($t0)
	sw $t1, 4896($t0)
	sw $t1, 4900($t0)
	sw $t1, 4904($t0)
	sw $t1, 4908($t0)
	sw $t1, 4912($t0)
	sw $t1, 4916($t0)
	sw $t1, 4932($t0)
	sw $t1, 4972($t0)
	sw $t1, 5008($t0)
	sw $t1, 5012($t0)
	sw $t1, 5016($t0)
	sw $t1, 5020($t0)
	sw $t1, 5024($t0)
	sw $t1, 5028($t0)
	sw $t1, 5032($t0)
	sw $t1, 5036($t0)
	sw $t1, 5040($t0)
	sw $t1, 5044($t0)
	sw $t1, 5060($t0)
	sw $t1, 5100($t0)
	sw $t1, 5136($t0)
	sw $t1, 5140($t0)
	sw $t1, 5168($t0)
	sw $t1, 5172($t0)
	sw $t1, 5264($t0)
	sw $t1, 5268($t0)
	sw $t1, 5296($t0)
	sw $t1, 5300($t0)
	sw $t1, 5392($t0)
	sw $t1, 5396($t0)
	sw $t1, 5424($t0)
	sw $t1, 5428($t0)
	sw $t1, 5520($t0)
	sw $t1, 5524($t0)
	sw $t1, 5552($t0)
	sw $t1, 5556($t0)
	sw $t1, 5648($t0)
	sw $t1, 5652($t0)
	sw $t1, 5656($t0)
	sw $t1, 5660($t0)
	sw $t1, 5664($t0)
	sw $t1, 5668($t0)
	sw $t1, 5672($t0)
	sw $t1, 5676($t0)
	sw $t1, 5680($t0)
	sw $t1, 5776($t0)
	sw $t1, 5780($t0)
	sw $t1, 5784($t0)
	sw $t1, 5788($t0)
	sw $t1, 5792($t0)
	sw $t1, 5796($t0)
	sw $t1, 5800($t0)
	sw $t1, 5804($t0)
	sw $t1, 5828($t0)
	sw $t1, 5832($t0)
	sw $t1, 5836($t0)
	sw $t1, 5840($t0)
	sw $t1, 5844($t0)
	sw $t1, 5848($t0)
	sw $t1, 5852($t0)
	sw $t1, 5856($t0)
	sw $t1, 5860($t0)
	sw $t1, 5864($t0)
	sw $t1, 5904($t0)
	sw $t1, 5908($t0)
	sw $t1, 5956($t0)
	sw $t1, 5960($t0)
	sw $t1, 5964($t0)
	sw $t1, 5968($t0)
	sw $t1, 5972($t0)
	sw $t1, 5976($t0)
	sw $t1, 5980($t0)
	sw $t1, 5984($t0)
	sw $t1, 5988($t0)
	sw $t1, 5992($t0)
	sw $t1, 6032($t0)
	sw $t1, 6036($t0)
	sw $t1, 6084($t0)
	sw $t1, 6088($t0)
	sw $t1, 6160($t0)
	sw $t1, 6164($t0)
	sw $t1, 6212($t0)
	sw $t1, 6216($t0)
	sw $t1, 6288($t0)
	sw $t1, 6292($t0)
	sw $t1, 6340($t0)
	sw $t1, 6344($t0)
	sw $t1, 6416($t0)
	sw $t1, 6420($t0)
	sw $t1, 6468($t0)
	sw $t1, 6472($t0)
	sw $t1, 6476($t0)
	sw $t1, 6480($t0)
	sw $t1, 6484($t0)
	sw $t1, 6488($t0)
	sw $t1, 6492($t0)
	sw $t1, 6496($t0)
	sw $t1, 6500($t0)
	sw $t1, 6544($t0)
	sw $t1, 6548($t0)
	sw $t1, 6596($t0)
	sw $t1, 6600($t0)
	sw $t1, 6604($t0)
	sw $t1, 6608($t0)
	sw $t1, 6612($t0)
	sw $t1, 6616($t0)
	sw $t1, 6620($t0)
	sw $t1, 6624($t0)
	sw $t1, 6628($t0)
	sw $t1, 6724($t0)
	sw $t1, 6728($t0)
	sw $t1, 6852($t0)
	sw $t1, 6856($t0)
	sw $t1, 6980($t0)
	sw $t1, 6984($t0)
	sw $t1, 7108($t0)
	sw $t1, 7112($t0)
	sw $t1, 7116($t0)
	sw $t1, 7120($t0)
	sw $t1, 7124($t0)
	sw $t1, 7128($t0)
	sw $t1, 7132($t0)
	sw $t1, 7136($t0)
	sw $t1, 7140($t0)
	sw $t1, 7144($t0)
	sw $t4, 7072($t0)
	sw $t1, 7236($t0)
	sw $t1, 7240($t0)
	sw $t1, 7244($t0)
	sw $t1, 7248($t0)
	sw $t1, 7252($t0)
	sw $t1, 7256($t0)
	sw $t1, 7260($t0)
	sw $t1, 7264($t0)
	sw $t1, 7268($t0)
	sw $t1, 7272($t0)
	sw $t4, 7196($t0)
	sw $t4, 7204($t0)
	sw $t4, 7328($t0)
	sw $t4, 7452($t0)
	sw $t4, 7456($t0)
	sw $t4, 7460($t0)
	sw $t1, 7700($t0)
	sw $t1, 7704($t0)
	sw $t1, 7708($t0)
	sw $t1, 7712($t0)
	sw $t1, 7716($t0)
	sw $t1, 7720($t0)
	sw $t1, 7724($t0)
	sw $t3, 7936($t0)
	sw $t3, 7940($t0)
	sw $t3, 7944($t0)
	sw $t3, 7948($t0)
	sw $t3, 7952($t0)
	sw $t3, 7956($t0)
	sw $t3, 7960($t0)
	sw $t3, 7964($t0)
	sw $t3, 7968($t0)
	sw $t3, 7972($t0)
	sw $t3, 7976($t0)
	sw $t3, 7980($t0)
	sw $t3, 7984($t0)
	sw $t3, 7988($t0)
	sw $t3, 7992($t0)
	sw $t3, 7996($t0)
	sw $t3, 8000($t0)
	sw $t3, 8004($t0)
	sw $t3, 8008($t0)
	sw $t3, 8012($t0)
	sw $t3, 8016($t0)
	sw $t3, 8020($t0)
	sw $t3, 8024($t0)
	sw $t3, 8028($t0)
	sw $t3, 8032($t0)
	sw $t3, 8036($t0)
	sw $t3, 8040($t0)
	sw $t3, 8044($t0)
	sw $t3, 8048($t0)
	sw $t3, 8052($t0)
	sw $t3, 8056($t0)
	sw $t3, 8060($t0)
	sw $t3, 8064($t0)
	sw $t3, 8068($t0)
	sw $t3, 8072($t0)
	sw $t3, 8076($t0)
	sw $t3, 8080($t0)
	sw $t3, 8084($t0)
	sw $t3, 8088($t0)
	sw $t3, 8092($t0)
	sw $t3, 8096($t0)
	sw $t3, 8100($t0)
	sw $t3, 8104($t0)
	sw $t3, 8108($t0)
	sw $t3, 8112($t0)
	sw $t3, 8116($t0)
	sw $t3, 8120($t0)
	sw $t3, 8124($t0)
	sw $t3, 8128($t0)
	sw $t3, 8132($t0)
	sw $t3, 8136($t0)
	sw $t3, 8140($t0)
	sw $t3, 8144($t0)
	sw $t3, 8148($t0)
	sw $t3, 8152($t0)
	sw $t3, 8156($t0)
	sw $t3, 8160($t0)
	sw $t3, 8164($t0)
	sw $t3, 8168($t0)
	sw $t3, 8172($t0)
	sw $t3, 8176($t0)
	sw $t3, 8180($t0)
	sw $t3, 8184($t0)
	sw $t3, 8188($t0)
	jr $ra



initialize_screen:
	la $t0, base_address
	li $t1, PINK
	li $t2, BLUE
	li $t3, GREEN
	li $t4, GOLDEN
	li $t5, WHITE
	li $t6, GREY
	li $t7, ORANGE
	li $t8, RED
	sw $t1, 136($t0)
	sw $t1, 152($t0)
	sw $t1, 168($t0)
	sw $t1, 184($t0)
	sw $t1, 200($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 268($t0)
	sw $t1, 276($t0)
	sw $t1, 280($t0)
	sw $t1, 284($t0)
	sw $t1, 292($t0)
	sw $t1, 296($t0)
	sw $t1, 300($t0)
	sw $t1, 308($t0)
	sw $t1, 312($t0)
	sw $t1, 316($t0)
	sw $t1, 324($t0)
	sw $t1, 328($t0)
	sw $t1, 332($t0)
	sw $t1, 392($t0)
	sw $t1, 408($t0)
	sw $t1, 424($t0)
	sw $t1, 440($t0)
	sw $t1, 456($t0)
	sw $t2, 640($t0)
	sw $t2, 644($t0)
	sw $t2, 648($t0)
	sw $t2, 652($t0)
	sw $t2, 656($t0)
	sw $t2, 660($t0)
	sw $t2, 664($t0)
	sw $t2, 668($t0)
	sw $t2, 672($t0)
	sw $t2, 676($t0)
	sw $t2, 680($t0)
	sw $t2, 684($t0)
	sw $t2, 688($t0)
	sw $t2, 692($t0)
	sw $t2, 696($t0)
	sw $t2, 700($t0)
	sw $t2, 704($t0)
	sw $t2, 708($t0)
	sw $t2, 712($t0)
	sw $t2, 716($t0)
	sw $t2, 720($t0)
	sw $t2, 724($t0)
	sw $t2, 728($t0)
	sw $t2, 732($t0)
	sw $t2, 736($t0)
	sw $t2, 740($t0)
	sw $t2, 744($t0)
	sw $t2, 748($t0)
	sw $t2, 752($t0)
	sw $t2, 756($t0)
	sw $t2, 760($t0)
	sw $t2, 764($t0)
	sw $t2, 768($t0)
	sw $t2, 772($t0)
	sw $t2, 776($t0)
	sw $t2, 780($t0)
	sw $t2, 784($t0)
	sw $t2, 788($t0)
	sw $t2, 792($t0)
	sw $t2, 796($t0)
	sw $t2, 800($t0)
	sw $t2, 804($t0)
	sw $t2, 808($t0)
	sw $t2, 812($t0)
	sw $t2, 816($t0)
	sw $t2, 820($t0)
	sw $t2, 824($t0)
	sw $t2, 828($t0)
	sw $t2, 832($t0)
	sw $t2, 836($t0)
	sw $t2, 840($t0)
	sw $t2, 844($t0)
	sw $t2, 848($t0)
	sw $t2, 852($t0)
	sw $t2, 856($t0)
	sw $t2, 860($t0)
	sw $t2, 864($t0)
	sw $t2, 868($t0)
	sw $t2, 872($t0)
	sw $t2, 876($t0)
	sw $t2, 880($t0)
	sw $t2, 884($t0)
	sw $t2, 888($t0)
	sw $t2, 892($t0)
	sw $t3, 896($t0)
	sw $t3, 900($t0)
	sw $t3, 1016($t0)
	sw $t3, 1020($t0)
	sw $t3, 1024($t0)
	sw $t3, 1148($t0)
	sw $t3, 1152($t0)
	sw $t3, 1156($t0)
	sw $t4, 1208($t0)
	sw $t4, 1216($t0)
	sw $t4, 1224($t0)
	sw $t3, 1272($t0)
	sw $t3, 1276($t0)
	sw $t3, 1280($t0)
	sw $t4, 1336($t0)
	sw $t4, 1340($t0)
	sw $t4, 1344($t0)
	sw $t4, 1348($t0)
	sw $t4, 1352($t0)
	sw $t3, 1404($t0)
	sw $t3, 1408($t0)
	sw $t3, 1412($t0)
	sw $t4, 1468($t0)
	sw $t4, 1476($t0)
	sw $t3, 1528($t0)
	sw $t3, 1532($t0)
	sw $t3, 1536($t0)
	sw $t5, 1588($t0)
	sw $t5, 1592($t0)
	sw $t5, 1596($t0)
	sw $t5, 1600($t0)
	sw $t5, 1604($t0)
	sw $t5, 1608($t0)
	sw $t5, 1612($t0)
	sw $t3, 1660($t0)
	sw $t3, 1664($t0)
	sw $t3, 1668($t0)
	sw $t5, 1712($t0)
	sw $t5, 1716($t0)
	sw $t5, 1740($t0)
	sw $t5, 1744($t0)
	sw $t3, 1784($t0)
	sw $t3, 1788($t0)
	sw $t3, 1792($t0)
	sw $t3, 1916($t0)
	sw $t3, 1920($t0)
	sw $t3, 1924($t0)
	sw $t3, 2040($t0)
	sw $t3, 2044($t0)
	sw $t3, 2048($t0)
	sw $t3, 2172($t0)
	sw $t3, 2176($t0)
	sw $t3, 2180($t0)
	sw $t3, 2296($t0)
	sw $t3, 2300($t0)
	sw $t3, 2304($t0)
	sw $t3, 2428($t0)
	sw $t3, 2432($t0)
	sw $t3, 2436($t0)
	sw $t5, 2456($t0)
	sw $t5, 2460($t0)
	sw $t5, 2464($t0)
	sw $t5, 2468($t0)
	sw $t5, 2472($t0)
	sw $t5, 2476($t0)
	sw $t5, 2480($t0)
	sw $t5, 2484($t0)
	sw $t3, 2552($t0)
	sw $t3, 2556($t0)
	sw $t3, 2560($t0)
	sw $t3, 2684($t0)
	sw $t3, 2688($t0)
	sw $t3, 2692($t0)
	sw $t3, 2808($t0)
	sw $t3, 2812($t0)
	sw $t3, 2816($t0)
	sw $t3, 2940($t0)
	sw $t3, 2944($t0)
	sw $t3, 2948($t0)
	sw $t6, 3000($t0)
	sw $t3, 3064($t0)
	sw $t3, 3068($t0)
	sw $t3, 3072($t0)
	sw $t6, 3124($t0)
	sw $t6, 3128($t0)
	sw $t6, 3132($t0)
	sw $t3, 3196($t0)
	sw $t3, 3200($t0)
	sw $t3, 3204($t0)
	sw $t5, 3248($t0)
	sw $t5, 3252($t0)
	sw $t5, 3256($t0)
	sw $t5, 3260($t0)
	sw $t5, 3264($t0)
	sw $t5, 3268($t0)
	sw $t5, 3272($t0)
	sw $t5, 3276($t0)
	sw $t3, 3320($t0)
	sw $t3, 3324($t0)
	sw $t3, 3328($t0)
	sw $t3, 3452($t0)
	sw $t3, 3456($t0)
	sw $t3, 3460($t0)
	sw $t3, 3576($t0)
	sw $t3, 3580($t0)
	sw $t3, 3584($t0)
	sw $t3, 3708($t0)
	sw $t3, 3712($t0)
	sw $t3, 3716($t0)
	sw $t3, 3832($t0)
	sw $t3, 3836($t0)
	sw $t3, 3840($t0)
	sw $t3, 3964($t0)
	sw $t3, 3968($t0)
	sw $t3, 3972($t0)
	sw $t5, 3996($t0)
	sw $t5, 4000($t0)
	sw $t5, 4004($t0)
	sw $t5, 4008($t0)
	sw $t5, 4012($t0)
	sw $t5, 4016($t0)
	sw $t5, 4020($t0)
	sw $t5, 4024($t0)
	sw $t3, 4088($t0)
	sw $t3, 4092($t0)
	sw $t3, 4096($t0)
	sw $t3, 4220($t0)
	sw $t3, 4224($t0)
	sw $t3, 4228($t0)
	sw $t3, 4344($t0)
	sw $t3, 4348($t0)
	sw $t3, 4352($t0)
	sw $t3, 4476($t0)
	sw $t3, 4480($t0)
	sw $t3, 4484($t0)
	sw $t3, 4600($t0)
	sw $t3, 4604($t0)
	sw $t3, 4608($t0)
	sw $t6, 4572($t0)
	sw $t3, 4732($t0)
	sw $t3, 4736($t0)
	sw $t3, 4740($t0)
	sw $t6, 4696($t0)
	sw $t6, 4700($t0)
	sw $t6, 4704($t0)
	sw $t3, 4856($t0)
	sw $t3, 4860($t0)
	sw $t3, 4864($t0)
	sw $t5, 4808($t0)
	sw $t5, 4812($t0)
	sw $t5, 4816($t0)
	sw $t5, 4820($t0)
	sw $t5, 4824($t0)
	sw $t5, 4828($t0)
	sw $t5, 4832($t0)
	sw $t5, 4836($t0)
	sw $t3, 4988($t0)
	sw $t3, 4992($t0)
	sw $t3, 4996($t0)
	sw $t3, 5112($t0)
	sw $t3, 5116($t0)
	sw $t3, 5120($t0)
	sw $t3, 5244($t0)
	sw $t3, 5248($t0)
	sw $t3, 5252($t0)
	sw $t3, 5368($t0)
	sw $t3, 5372($t0)
	sw $t3, 5376($t0)
	sw $t3, 5500($t0)
	sw $t3, 5504($t0)
	sw $t3, 5508($t0)
	sw $t3, 5624($t0)
	sw $t3, 5628($t0)
	sw $t3, 5632($t0)
	sw $t5, 5552($t0)
	sw $t5, 5556($t0)
	sw $t5, 5560($t0)
	sw $t5, 5564($t0)
	sw $t5, 5568($t0)
	sw $t5, 5572($t0)
	sw $t5, 5576($t0)
	sw $t5, 5580($t0)
	sw $t3, 5756($t0)
	sw $t3, 5760($t0)
	sw $t3, 5764($t0)
	sw $t3, 5880($t0)
	sw $t3, 5884($t0)
	sw $t3, 5888($t0)
	sw $t3, 6012($t0)
	sw $t3, 6016($t0)
	sw $t3, 6020($t0)
	sw $t3, 6136($t0)
	sw $t3, 6140($t0)
	sw $t3, 6144($t0)
	sw $t3, 6268($t0)
	sw $t3, 6272($t0)
	sw $t3, 6276($t0)
	sw $t5, 6356($t0)
	sw $t5, 6360($t0)
	sw $t5, 6364($t0)
	sw $t5, 6368($t0)
	sw $t5, 6372($t0)
	sw $t5, 6376($t0)
	sw $t5, 6380($t0)
	sw $t5, 6384($t0)
	sw $t3, 6392($t0)
	sw $t3, 6396($t0)
	sw $t3, 6400($t0)
	sw $t3, 6524($t0)
	sw $t3, 6528($t0)
	sw $t3, 6532($t0)
	sw $t3, 6648($t0)
	sw $t3, 6652($t0)
	sw $t3, 6656($t0)
	sw $t3, 6780($t0)
	sw $t3, 6784($t0)
	sw $t3, 6788($t0)
	sw $t3, 6904($t0)
	sw $t3, 6908($t0)
	sw $t3, 6912($t0)
	sw $t7, 6936($t0)
	sw $t5, 6960($t0)
	sw $t5, 6964($t0)
	sw $t5, 6968($t0)
	sw $t5, 6972($t0)
	sw $t5, 6976($t0)
	sw $t5, 6980($t0)
	sw $t5, 6984($t0)
	sw $t5, 6988($t0)
	sw $t3, 7036($t0)
	sw $t3, 7040($t0)
	sw $t3, 7044($t0)
	sw $t7, 7060($t0)
	sw $t7, 7068($t0)
	sw $t3, 7160($t0)
	sw $t3, 7164($t0)
	sw $t3, 7168($t0)
	sw $t7, 7192($t0)
	sw $t3, 7292($t0)
	sw $t3, 7296($t0)
	sw $t3, 7300($t0)
	sw $t7, 7316($t0)
	sw $t7, 7320($t0)
	sw $t7, 7324($t0)
	sw $t3, 7416($t0)
	sw $t3, 7420($t0)
	sw $t3, 7424($t0)
	sw $t3, 7548($t0)
	sw $t3, 7552($t0)
	sw $t3, 7556($t0)
	sw $t5, 7564($t0)
	sw $t5, 7568($t0)
	sw $t5, 7572($t0)
	sw $t5, 7576($t0)
	sw $t5, 7580($t0)
	sw $t5, 7584($t0)
	sw $t5, 7588($t0)
	sw $t5, 7592($t0)
	sw $t3, 7672($t0)
	sw $t3, 7676($t0)
	sw $t3, 7680($t0)
	sw $t3, 7804($t0)
	sw $t3, 7808($t0)
	sw $t3, 7812($t0)
	sw $t3, 7928($t0)
	sw $t3, 7932($t0)
	sw $t8, 7936($t0)
	sw $t8, 7940($t0)
	sw $t8, 7944($t0)
	sw $t8, 7948($t0)
	sw $t8, 7952($t0)
	sw $t8, 7956($t0)
	sw $t8, 7960($t0)
	sw $t8, 7964($t0)
	sw $t8, 7968($t0)
	sw $t8, 7972($t0)
	sw $t8, 7976($t0)
	sw $t8, 7980($t0)
	sw $t8, 7984($t0)
	sw $t8, 7988($t0)
	sw $t8, 7992($t0)
	sw $t8, 7996($t0)
	sw $t8, 8000($t0)
	sw $t8, 8004($t0)
	sw $t8, 8008($t0)
	sw $t8, 8012($t0)
	sw $t8, 8016($t0)
	sw $t8, 8020($t0)
	sw $t8, 8024($t0)
	sw $t8, 8028($t0)
	sw $t8, 8032($t0)
	sw $t8, 8036($t0)
	sw $t8, 8040($t0)
	sw $t8, 8044($t0)
	sw $t8, 8048($t0)
	sw $t8, 8052($t0)
	sw $t8, 8056($t0)
	sw $t8, 8060($t0)
	sw $t8, 8064($t0)
	sw $t8, 8068($t0)
	sw $t8, 8072($t0)
	sw $t8, 8076($t0)
	sw $t8, 8080($t0)
	sw $t8, 8084($t0)
	sw $t8, 8088($t0)
	sw $t8, 8092($t0)
	sw $t8, 8096($t0)
	sw $t8, 8100($t0)
	sw $t8, 8104($t0)
	sw $t8, 8108($t0)
	sw $t8, 8112($t0)
	sw $t8, 8116($t0)
	sw $t8, 8120($t0)
	sw $t8, 8124($t0)
	sw $t8, 8128($t0)
	sw $t8, 8132($t0)
	sw $t8, 8136($t0)
	sw $t8, 8140($t0)
	sw $t8, 8144($t0)
	sw $t8, 8148($t0)
	sw $t8, 8152($t0)
	sw $t8, 8156($t0)
	sw $t8, 8160($t0)
	sw $t8, 8164($t0)
	sw $t8, 8168($t0)
	sw $t8, 8172($t0)
	sw $t8, 8176($t0)
	sw $t8, 8180($t0)
	sw $t8, 8184($t0)
	sw $t8, 8188($t0)
	jr $ra

draw_win:
	la $t0, base_address
	li $t1, ORANGE
	li $t2, GOLDEN
	li $t3, GOLDEN
	li $t4, RED
	sw $t1, 704($t0)
	sw $t1, 828($t0)
	sw $t1, 836($t0)
	sw $t1, 960($t0)
	sw $t1, 1084($t0)
	sw $t1, 1088($t0)
	sw $t1, 1092($t0)
	sw $t2, 1184($t0)
	sw $t3, 1216($t0)
	sw $t2, 1248($t0)
	sw $t2, 1312($t0)
	sw $t3, 1344($t0)
	sw $t2, 1376($t0)
	sw $t2, 1440($t0)
	sw $t3, 1472($t0)
	sw $t2, 1504($t0)
	sw $t2, 1568($t0)
	sw $t3, 1600($t0)
	sw $t2, 1632($t0)
	sw $t2, 1696($t0)
	sw $t2, 1700($t0)
	sw $t2, 1704($t0)
	sw $t2, 1708($t0)
	sw $t3, 1728($t0)
	sw $t2, 1748($t0)
	sw $t2, 1752($t0)
	sw $t2, 1756($t0)
	sw $t2, 1760($t0)
	sw $t2, 1836($t0)
	sw $t3, 1856($t0)
	sw $t2, 1876($t0)
	sw $t2, 1964($t0)
	sw $t3, 1984($t0)
	sw $t2, 2004($t0)
	sw $t2, 2092($t0)
	sw $t3, 2112($t0)
	sw $t2, 2132($t0)
	sw $t2, 2220($t0)
	sw $t3, 2240($t0)
	sw $t2, 2260($t0)
	sw $t2, 2348($t0)
	sw $t2, 2352($t0)
	sw $t2, 2356($t0)
	sw $t2, 2360($t0)
	sw $t2, 2364($t0)
	sw $t2, 2368($t0)
	sw $t2, 2372($t0)
	sw $t2, 2376($t0)
	sw $t2, 2380($t0)
	sw $t2, 2384($t0)
	sw $t2, 2388($t0)
	sw $t2, 3244($t0)
	sw $t2, 3248($t0)
	sw $t2, 3252($t0)
	sw $t2, 3256($t0)
	sw $t2, 3260($t0)
	sw $t2, 3264($t0)
	sw $t2, 3268($t0)
	sw $t2, 3272($t0)
	sw $t2, 3276($t0)
	sw $t2, 3280($t0)
	sw $t2, 3284($t0)
	sw $t2, 3392($t0)
	sw $t2, 3520($t0)
	sw $t2, 3648($t0)
	sw $t2, 3776($t0)
	sw $t2, 3904($t0)
	sw $t2, 4032($t0)
	sw $t2, 4160($t0)
	sw $t2, 4288($t0)
	sw $t2, 4416($t0)
	sw $t2, 4544($t0)
	sw $t2, 4672($t0)
	sw $t2, 4780($t0)
	sw $t2, 4784($t0)
	sw $t2, 4788($t0)
	sw $t2, 4792($t0)
	sw $t2, 4796($t0)
	sw $t2, 4800($t0)
	sw $t2, 4804($t0)
	sw $t2, 4808($t0)
	sw $t2, 4812($t0)
	sw $t2, 4816($t0)
	sw $t2, 4820($t0)
	sw $t2, 5548($t0)
	sw $t2, 5584($t0)
	sw $t2, 5676($t0)
	sw $t2, 5712($t0)
	sw $t2, 5804($t0)
	sw $t2, 5808($t0)
	sw $t2, 5840($t0)
	sw $t2, 5932($t0)
	sw $t2, 5936($t0)
	sw $t2, 5940($t0)
	sw $t2, 5968($t0)
	sw $t2, 6060($t0)
	sw $t2, 6068($t0)
	sw $t2, 6072($t0)
	sw $t2, 6096($t0)
	sw $t2, 6188($t0)
	sw $t2, 6200($t0)
	sw $t2, 6204($t0)
	sw $t2, 6224($t0)
	sw $t2, 6316($t0)
	sw $t2, 6332($t0)
	sw $t2, 6336($t0)
	sw $t2, 6352($t0)
	sw $t2, 6444($t0)
	sw $t2, 6464($t0)
	sw $t2, 6468($t0)
	sw $t2, 6480($t0)
	sw $t2, 6572($t0)
	sw $t2, 6596($t0)
	sw $t2, 6600($t0)
	sw $t2, 6608($t0)
	sw $t2, 6700($t0)
	sw $t2, 6728($t0)
	sw $t2, 6732($t0)
	sw $t2, 6736($t0)
	sw $t2, 6828($t0)
	sw $t2, 6860($t0)
	sw $t2, 6864($t0)
	sw $t2, 6956($t0)
	sw $t2, 6992($t0)
	sw $t2, 7084($t0)
	sw $t2, 7120($t0)
	sw $t4, 7936($t0)
	sw $t4, 7940($t0)
	sw $t4, 7944($t0)
	sw $t4, 7948($t0)
	sw $t4, 7952($t0)
	sw $t4, 7956($t0)
	sw $t4, 7960($t0)
	sw $t4, 7964($t0)
	sw $t4, 7968($t0)
	sw $t4, 7972($t0)
	sw $t4, 7976($t0)
	sw $t4, 7980($t0)
	sw $t4, 7984($t0)
	sw $t4, 7988($t0)
	sw $t4, 7992($t0)
	sw $t4, 7996($t0)
	sw $t4, 8000($t0)
	sw $t4, 8004($t0)
	sw $t4, 8008($t0)
	sw $t4, 8012($t0)
	sw $t4, 8016($t0)
	sw $t4, 8020($t0)
	sw $t4, 8024($t0)
	sw $t4, 8028($t0)
	sw $t4, 8032($t0)
	sw $t4, 8036($t0)
	sw $t4, 8040($t0)
	sw $t4, 8044($t0)
	sw $t4, 8048($t0)
	sw $t4, 8052($t0)
	sw $t4, 8056($t0)
	sw $t4, 8060($t0)
	sw $t4, 8064($t0)
	sw $t4, 8068($t0)
	sw $t4, 8072($t0)
	sw $t4, 8076($t0)
	sw $t4, 8080($t0)
	sw $t4, 8084($t0)
	sw $t4, 8088($t0)
	sw $t4, 8092($t0)
	sw $t4, 8096($t0)
	sw $t4, 8100($t0)
	sw $t4, 8104($t0)
	sw $t4, 8108($t0)
	sw $t4, 8112($t0)
	sw $t4, 8116($t0)
	sw $t4, 8120($t0)
	sw $t4, 8124($t0)
	sw $t4, 8128($t0)
	sw $t4, 8132($t0)
	sw $t4, 8136($t0)
	sw $t4, 8140($t0)
	sw $t4, 8144($t0)
	sw $t4, 8148($t0)
	sw $t4, 8152($t0)
	sw $t4, 8156($t0)
	sw $t4, 8160($t0)
	sw $t4, 8164($t0)
	sw $t4, 8168($t0)
	sw $t4, 8172($t0)
	sw $t4, 8176($t0)
	sw $t4, 8180($t0)
	sw $t4, 8184($t0)
	sw $t4, 8188($t0)
	jr $ra


draw_loss:
	la $t0, base_address
	li $t1, WHITE
	li $t2, ORANGE
	li $t3, RED
	sw $t1, 904($t0)
	sw $t1, 928($t0)
	sw $t1, 944($t0)
	sw $t1, 948($t0)
	sw $t1, 952($t0)
	sw $t1, 956($t0)
	sw $t1, 960($t0)
	sw $t1, 964($t0)
	sw $t1, 988($t0)
	sw $t1, 1008($t0)
	sw $t1, 1036($t0)
	sw $t1, 1052($t0)
	sw $t1, 1072($t0)
	sw $t1, 1092($t0)
	sw $t1, 1116($t0)
	sw $t1, 1136($t0)
	sw $t1, 1168($t0)
	sw $t1, 1176($t0)
	sw $t1, 1200($t0)
	sw $t1, 1220($t0)
	sw $t1, 1244($t0)
	sw $t1, 1264($t0)
	sw $t1, 1300($t0)
	sw $t1, 1328($t0)
	sw $t1, 1348($t0)
	sw $t1, 1372($t0)
	sw $t1, 1392($t0)
	sw $t1, 1428($t0)
	sw $t1, 1456($t0)
	sw $t1, 1476($t0)
	sw $t1, 1500($t0)
	sw $t1, 1520($t0)
	sw $t1, 1556($t0)
	sw $t1, 1584($t0)
	sw $t1, 1604($t0)
	sw $t1, 1628($t0)
	sw $t1, 1648($t0)
	sw $t1, 1684($t0)
	sw $t1, 1712($t0)
	sw $t1, 1732($t0)
	sw $t1, 1756($t0)
	sw $t1, 1776($t0)
	sw $t1, 1812($t0)
	sw $t1, 1840($t0)
	sw $t1, 1860($t0)
	sw $t1, 1884($t0)
	sw $t1, 1904($t0)
	sw $t1, 1940($t0)
	sw $t1, 1968($t0)
	sw $t1, 1972($t0)
	sw $t1, 1976($t0)
	sw $t1, 1980($t0)
	sw $t1, 1984($t0)
	sw $t1, 1988($t0)
	sw $t1, 2012($t0)
	sw $t1, 2016($t0)
	sw $t1, 2020($t0)
	sw $t1, 2024($t0)
	sw $t1, 2028($t0)
	sw $t1, 2032($t0)
	sw $t1, 2708($t0)
	sw $t1, 2760($t0)
	sw $t1, 2764($t0)
	sw $t1, 2768($t0)
	sw $t1, 2772($t0)
	sw $t1, 2776($t0)
	sw $t1, 2780($t0)
	sw $t1, 2784($t0)
	sw $t1, 2788($t0)
	sw $t1, 2792($t0)
	sw $t1, 2796($t0)
	sw $t1, 2836($t0)
	sw $t1, 2888($t0)
	sw $t1, 2924($t0)
	sw $t1, 2964($t0)
	sw $t1, 3016($t0)
	sw $t1, 3052($t0)
	sw $t1, 3092($t0)
	sw $t1, 3144($t0)
	sw $t1, 3180($t0)
	sw $t1, 3220($t0)
	sw $t1, 3272($t0)
	sw $t1, 3308($t0)
	sw $t1, 3348($t0)
	sw $t1, 3400($t0)
	sw $t1, 3436($t0)
	sw $t1, 3476($t0)
	sw $t1, 3528($t0)
	sw $t1, 3564($t0)
	sw $t1, 3604($t0)
	sw $t1, 3656($t0)
	sw $t1, 3692($t0)
	sw $t1, 3732($t0)
	sw $t1, 3784($t0)
	sw $t1, 3820($t0)
	sw $t1, 3860($t0)
	sw $t1, 3912($t0)
	sw $t1, 3948($t0)
	sw $t1, 3988($t0)
	sw $t1, 4040($t0)
	sw $t1, 4076($t0)
	sw $t1, 4116($t0)
	sw $t1, 4168($t0)
	sw $t1, 4204($t0)
	sw $t1, 4244($t0)
	sw $t1, 4248($t0)
	sw $t1, 4252($t0)
	sw $t1, 4256($t0)
	sw $t1, 4260($t0)
	sw $t1, 4264($t0)
	sw $t1, 4268($t0)
	sw $t1, 4272($t0)
	sw $t1, 4296($t0)
	sw $t1, 4300($t0)
	sw $t1, 4304($t0)
	sw $t1, 4308($t0)
	sw $t1, 4312($t0)
	sw $t1, 4316($t0)
	sw $t1, 4320($t0)
	sw $t1, 4324($t0)
	sw $t1, 4328($t0)
	sw $t1, 4332($t0)
	sw $t1, 4884($t0)
	sw $t1, 4888($t0)
	sw $t1, 4892($t0)
	sw $t1, 4896($t0)
	sw $t1, 4900($t0)
	sw $t1, 4904($t0)
	sw $t1, 4908($t0)
	sw $t1, 4912($t0)
	sw $t1, 4916($t0)
	sw $t1, 4940($t0)
	sw $t1, 4944($t0)
	sw $t1, 4948($t0)
	sw $t1, 4952($t0)
	sw $t1, 4956($t0)
	sw $t1, 4960($t0)
	sw $t1, 4964($t0)
	sw $t1, 4968($t0)
	sw $t1, 4972($t0)
	sw $t1, 5012($t0)
	sw $t1, 5068($t0)
	sw $t1, 5140($t0)
	sw $t1, 5196($t0)
	sw $t1, 5268($t0)
	sw $t1, 5324($t0)
	sw $t1, 5396($t0)
	sw $t1, 5452($t0)
	sw $t1, 5524($t0)
	sw $t1, 5580($t0)
	sw $t1, 5652($t0)
	sw $t1, 5656($t0)
	sw $t1, 5660($t0)
	sw $t1, 5664($t0)
	sw $t1, 5668($t0)
	sw $t1, 5672($t0)
	sw $t1, 5676($t0)
	sw $t1, 5680($t0)
	sw $t1, 5708($t0)
	sw $t1, 5712($t0)
	sw $t1, 5716($t0)
	sw $t1, 5720($t0)
	sw $t1, 5724($t0)
	sw $t1, 5728($t0)
	sw $t1, 5732($t0)
	sw $t1, 5736($t0)
	sw $t1, 5808($t0)
	sw $t1, 5864($t0)
	sw $t1, 5936($t0)
	sw $t1, 5992($t0)
	sw $t1, 6064($t0)
	sw $t1, 6120($t0)
	sw $t1, 6192($t0)
	sw $t2, 6200($t0)
	sw $t2, 6204($t0)
	sw $t2, 6208($t0)
	sw $t1, 6248($t0)
	sw $t1, 6320($t0)
	sw $t2, 6332($t0)
	sw $t1, 6376($t0)
	sw $t1, 6416($t0)
	sw $t1, 6420($t0)
	sw $t1, 6424($t0)
	sw $t1, 6428($t0)
	sw $t1, 6432($t0)
	sw $t1, 6436($t0)
	sw $t1, 6440($t0)
	sw $t1, 6444($t0)
	sw $t1, 6448($t0)
	sw $t2, 6456($t0)
	sw $t2, 6464($t0)
	sw $t1, 6472($t0)
	sw $t1, 6476($t0)
	sw $t1, 6480($t0)
	sw $t1, 6484($t0)
	sw $t1, 6488($t0)
	sw $t1, 6492($t0)
	sw $t1, 6496($t0)
	sw $t1, 6500($t0)
	sw $t1, 6504($t0)
	sw $t2, 6588($t0)
	sw $t2, 7052($t0)
	sw $t2, 7068($t0)
	sw $t2, 7076($t0)
	sw $t2, 7096($t0)
	sw $t2, 7104($t0)
	sw $t2, 7120($t0)
	sw $t2, 7152($t0)
	sw $t2, 7160($t0)
	sw $t2, 7176($t0)
	sw $t2, 7184($t0)
	sw $t2, 7196($t0)
	sw $t2, 7200($t0)
	sw $t2, 7208($t0)
	sw $t2, 7224($t0)
	sw $t2, 7228($t0)
	sw $t2, 7236($t0)
	sw $t2, 7244($t0)
	sw $t2, 7252($t0)
	sw $t2, 7264($t0)
	sw $t2, 7272($t0)
	sw $t2, 7280($t0)
	sw $t2, 7284($t0)
	sw $t2, 7292($t0)
	sw $t2, 7308($t0)
	sw $t2, 7324($t0)
	sw $t2, 7332($t0)
	sw $t2, 7352($t0)
	sw $t2, 7360($t0)
	sw $t2, 7376($t0)
	sw $t2, 7388($t0)
	sw $t2, 7396($t0)
	sw $t2, 7400($t0)
	sw $t2, 7408($t0)
	sw $t2, 7416($t0)
	sw $t2, 7432($t0)
	sw $t2, 7436($t0)
	sw $t2, 7440($t0)
	sw $t2, 7452($t0)
	sw $t2, 7472($t0)
	sw $t2, 7476($t0)
	sw $t2, 7480($t0)
	sw $t2, 7500($t0)
	sw $t2, 7504($t0)
	sw $t2, 7508($t0)
	sw $t2, 7520($t0)
	sw $t2, 7528($t0)
	sw $t2, 7540($t0)
	sw $t2, 7544($t0)
	sw $t2, 7548($t0)
	sw $t2, 7552($t0)
	sw $t2, 7560($t0)
	sw $t2, 7576($t0)
	sw $t2, 7584($t0)
	sw $t2, 7604($t0)
	sw $t2, 7624($t0)
	sw $t2, 7632($t0)
	sw $t2, 7648($t0)
	sw $t2, 7656($t0)
	sw $t2, 7672($t0)
	sw $t2, 7680($t0)
	sw $t2, 7684($t0)
	sw $t2, 7692($t0)
	sw $t2, 7708($t0)
	sw $t2, 7728($t0)
	sw $t2, 7736($t0)
	sw $t2, 7748($t0)
	sw $t2, 7756($t0)
	sw $t2, 7760($t0)
	sw $t2, 7776($t0)
	sw $t2, 7780($t0)
	sw $t2, 7788($t0)
	sw $t2, 7796($t0)
	sw $t2, 7804($t0)
	sw $t2, 7808($t0)
	sw $t2, 7816($t0)
	sw $t2, 7832($t0)
	sw $t2, 7836($t0)
	sw $t2, 7840($t0)
	sw $t2, 7860($t0)
	sw $t2, 7880($t0)
	sw $t2, 7888($t0)
	sw $t2, 7904($t0)
	sw $t2, 7912($t0)
	sw $t2, 7928($t0)
	sw $t3, 7936($t0)
	sw $t3, 7940($t0)
	sw $t3, 7944($t0)
	sw $t3, 7948($t0)
	sw $t3, 7952($t0)
	sw $t3, 7956($t0)
	sw $t3, 7960($t0)
	sw $t3, 7964($t0)
	sw $t3, 7968($t0)
	sw $t3, 7972($t0)
	sw $t3, 7976($t0)
	sw $t3, 7980($t0)
	sw $t3, 7984($t0)
	sw $t3, 7988($t0)
	sw $t3, 7992($t0)
	sw $t3, 7996($t0)
	sw $t3, 8000($t0)
	sw $t3, 8004($t0)
	sw $t3, 8008($t0)
	sw $t3, 8012($t0)
	sw $t3, 8016($t0)
	sw $t3, 8020($t0)
	sw $t3, 8024($t0)
	sw $t3, 8028($t0)
	sw $t3, 8032($t0)
	sw $t3, 8036($t0)
	sw $t3, 8040($t0)
	sw $t3, 8044($t0)
	sw $t3, 8048($t0)
	sw $t3, 8052($t0)
	sw $t3, 8056($t0)
	sw $t3, 8060($t0)
	sw $t3, 8064($t0)
	sw $t3, 8068($t0)
	sw $t3, 8072($t0)
	sw $t3, 8076($t0)
	sw $t3, 8080($t0)
	sw $t3, 8084($t0)
	sw $t3, 8088($t0)
	sw $t3, 8092($t0)
	sw $t3, 8096($t0)
	sw $t3, 8100($t0)
	sw $t3, 8104($t0)
	sw $t3, 8108($t0)
	sw $t3, 8112($t0)
	sw $t3, 8116($t0)
	sw $t3, 8120($t0)
	sw $t3, 8124($t0)
	sw $t3, 8128($t0)
	sw $t3, 8132($t0)
	sw $t3, 8136($t0)
	sw $t3, 8140($t0)
	sw $t3, 8144($t0)
	sw $t3, 8148($t0)
	sw $t3, 8152($t0)
	sw $t3, 8156($t0)
	sw $t3, 8160($t0)
	sw $t3, 8164($t0)
	sw $t3, 8168($t0)
	sw $t3, 8172($t0)
	sw $t3, 8176($t0)
	sw $t3, 8180($t0)
	sw $t3, 8184($t0)
	sw $t3, 8188($t0)
	jr $ra

