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
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1 - done
# - Milestone 2 - done
# - Milestone 3 - done
# (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Health -  track and show the player's health, every round a player have 6 heart
# 2. Fail condition - if the player loss all the heart or fall to the fire at the ground
# 3. Win condition - if the player touch the win object
# 4. Moving objects - the last four platform will disappear when time passed. 
#                            - The win object will hovering gently up and down. 
#                            - The obstacles will move left and right make the game harder.
# 5. Moving platforms - there are three platform will move around, make the game harder
# 6. double jump - allow the player do double jump but no triple jump, the second jump
# 		will reload the jump system so the best way to jump is to wait the first jump reach the top
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
# YouTube: https://www.youtube.com/watch?v=ly8lvvxuI_I
# Github: https://github.com/Neverland1973556/cscb58project
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - In the midway check, I didn't know the least frame need to be 64*64 and I did one with 32*64 and get one mark deduced
#    - I fiexed it now and this version have a 64*64 frame (512/8) * (512/8)
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
.eqv platform_counter 7
.eqv ob_counter 16
# data need to store


.data
double_jump_counter: 1
me_location: .word 13860
heart: .word 6
platforms: .word 3468, 6500, 10108
# four later 11448, 12676, 13904, 15132
obs: .word 4432, 7564
direction_for_platforms: 1, 0, 1
direction_for_obs: 0, 1
counter_for_platforms: platform_counter
counter_for_obstacles: ob_counter
offset: .word 512
jump_counter: .word 0
counter: .word 0
counter_for_floor: .word 500

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

	li $v0, 32
	li $a0, 500
	syscall


game_loop:
	la $t1, heart
	lw $t9, 0($t1)
	beqz $t9, gameover
	# this is for the erase floor stuff
	la $t1, counter_for_floor
	lw $t2, 0($t1)
	# less than 0, do nothing
	bltz $t2, erase_floor_back
	# 0 - 150, 
	li $t3, 300
	beq $t2, $t3, erase_floor_pre_1
	li $t3, 200
	beq $t2, $t3, erase_floor_pre_2
	li $t3, 100
	beq $t2, $t3, erase_floor_pre_3
	beq $t2, $zero, erase_floor_pre_4 

erase_floor_back:
	la $t1, counter_for_floor
	lw $t2, 0($t1)
	bltz, $t2, less_than_0
	addi $t2, $t2, -1
	sw $t2, 0($t1)
less_than_0:
	# if the counter count to 0, platform changes
	la $t1, counter_for_platforms
	lw $t2, 0($t1)
	beqz $t2, platform_change
	# start update floor_location
	# need to update three floors
	addi $t2, $t2, -1
	sw $t2, 0($t1)

floor_location_back:

	la $t1, counter_for_obstacles
	lw $t2, 0($t1)
	beqz $t2, ob_change
	# start update floor_location
	# need to update three floors
	addi $t2, $t2, -1
	sw $t2, 0($t1)

ob_location_back:


	# start update me_location
	la $t1, me_location
	lw $t2, 0($t1)
	# check the color under me (offset 512)
	addi $t4, $t2, 1024
	
	# t2 is the position under me, compare t2 with white
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)

	bne $t3, BLACK, no_gravity # if color is not white, not falling
	# make sure the jump_count is 0 to fall
	la $t5, jump_counter
	lw $t6, 0($t5)
	bnez $t6, gravity_done
	
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, no_gravity # if color is not white, not falling
	addi $t0, $t0, 4
	lw  $t3, 0($t0)
	bne $t3, BLACK, no_gravity # if color is not white, not falling
	# have gravity (in the space), falling
	# black under it

	move $a0, $t2
	jal erase_me
	li $a1, 256
	jal draw_me
	j gravity_done
no_gravity:
	la $s5, double_jump_counter
	li $s6, 1
	sw $s6, 0($s5)
gravity_done:
	# milestone 3
	# jal platform_update

	# able to control me
	jal me_update
	
update_done:

	# found if it wins
	# t2 is me
	la $t1, me_location
	lw $t2, 0($t1)
	addi $t4, $t2, -260 
	# t4 is the current place 
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	# it touch the win item, end the game
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page

	addi $t0, $t0, -1008
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GOLDEN, win_page


	# heart conditions
	# if red die
	la $t1, me_location
	lw $t2, 0($t1)
	addi $t4, $t2, 1024
	# t4 is the current place 
	la $t0, base_address
	add $t0, $t0, $t4
	lw  $t3, 0($t0)
	# it touch the win item, end the game
	beq $t3, RED, gameover

	# if blue, do nothing

	# if green or grey, heart - 1, continue
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
	beq $t3, GREY, touch_green_left
	beq $t3, WHITE, touch_white_left
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_left
	beq $t3, GREY, touch_green_left
	#beq $t3, WHITE, touch_white_left
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_left
	beq $t3, GREY, touch_green_left
	#beq $t3, WHITE, touch_white_left
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_left
	beq $t3, GREY, touch_green_left
	#beq $t3, WHITE, touch_white_left
	addi $t0, $t0, 16
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_right
	beq $t3, GREY, touch_green_right
	#beq $t3, WHITE, touch_white_right
	addi $t0, $t0, -256
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_right
	beq $t3, GREY, touch_green_right
	#beq $t3, WHITE, touch_white_right
	addi $t0, $t0, -256
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_right
	beq $t3, GREY, touch_green_right
	#beq $t3, WHITE, touch_white_right
	addi $t0, $t0, -256
	lw  $t3, 0($t0)
	beq $t3, GREEN, touch_green_right
	beq $t3, GREY, touch_green_right
	beq $t3, WHITE, touch_white_right

green_continue:

	# weight for 40ms for next loop
	li $v0, 32
	li $a0, 40
	syscall

	j game_loop

move_up_win:
	# move the object up
	li $a0, 1144 
	jal erase_win_object
	addi $a0, $a0, -256
	jal draw_win_object
	j win_back
move_down_win:
	# move the object up
	li $a0, 888 
	jal erase_win_object
	addi $a0, $a0, 256
	jal draw_win_object
	j win_back

ob_change:
	# make the counter restart
	la $t1, counter_for_obstacles
	li $t2, ob_counter
	sw $t2, 0($t1)

	# move the win object
	la $t0, base_address
	addi $t0, $t0, 888
	lw $t1, 0($t0)
	# if the color is black, move the object up
	beq $t1, BLACK, move_up_win
	j move_down_win

win_back:
	# move the platform
	la $t1, obs
	lw $t2, 0($t1)
	lw $t3, 4($t1)
	la $t1, direction_for_obs
	lw $t5, 0($t1)
	lw $t6, 4($t1)

	li $s1, 4424
	li $s2, 4436
	beq $s1, $t2, bounce_right1_ob
	beq $s2, $t2, bounce_left1_ob
	# do the current thing

bounce_1_ob:
	li $s1, 7564
	li $s2, 7576
	beq $s1, $t3, bounce_right2_ob
	beq $s2, $t3, bounce_left2_ob

bounce_2_ob:
	# 0 go right
	la $t1, obs
	move $a0, $t2
	beq $t5, $zero, go_right_platform1_ob
	j go_left_platform1_ob
second_platform_ob: 
	move $a0, $t3
	beq $t6, $zero, go_right_platform2_ob
	j go_left_platform2_ob

bounce_right1_ob:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_obs
	li $s7, 0
	sw $s7, 0($t1)
	j bounce_1_ob

bounce_left1_ob:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_obs
	li $s7, 1
	sw $s7, 0($t1)
	j bounce_1_ob
bounce_right2_ob:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_obs
	li $s7, 0
	sw $s7, 4($t1)
	j bounce_2_ob

bounce_left2_ob:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_obs
	li $s7, 1
	sw $s7, 4($t1)
	j bounce_2_ob

go_right_platform1_ob: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_ob
	addi $a0, $a0, 4
	jal draw_ob
	sw $a0, 0($t1)
	j second_platform_ob

go_left_platform1_ob: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_ob
	addi $a0, $a0, -4
	jal draw_ob
	sw $a0, 0($t1)
	j second_platform_ob
go_right_platform2_ob: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_ob
	addi $a0, $a0, 4
	jal draw_ob
	sw $a0, 4($t1)
	j ob_location_back

go_left_platform2_ob: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_ob
	addi $a0, $a0, -4
	jal draw_ob
	sw $a0, 4($t1)
	j ob_location_back

platform_change:
	# make the counter restart
	la $t1, counter_for_platforms
	li $t2, platform_counter
	sw $t2, 0($t1)
	# move the platform
	la $t1, platforms
	lw $t2, 0($t1)
	lw $t3, 4($t1)
	lw $t4, 8($t1)
	la $t1, direction_for_platforms
	lw $t5, 0($t1)
	lw $t6, 4($t1)
	lw $t7, 8($t1)
	# if t5 is 0, t2 go right
	# if not touch the boundary, normal case
	# count the boundary value to decide
	# boundary of platform 1 / 2 / 3 
	# 
	li $s1, 3388
	li $s2, 3492
	beq $s1, $t2, bounce_right1
	beq $s2, $t2, bounce_left1
	# do the current thing
bounce_1:
	li $s1, 6460
	li $s2, 6564
	beq $s1, $t3, bounce_right2
	beq $s2, $t3, bounce_left2

bounce_2:
	li $s1, 10040
	li $s2, 10160
	beq $s1, $t4, bounce_right3
	beq $s2, $t4, bounce_left3

bounce_3:
	# 0 go right
	la $t1, platforms
	move $a0, $t2
	beq $t5, $zero, go_right_platform1
	j go_left_platform1
second_platform: 
	move $a0, $t3
	beq $t6, $zero, go_right_platform2
	j go_left_platform2
third_platform:
	move $a0, $t4
	beq $t7, $zero, go_right_platform3
	j go_left_platform3

bounce_right1:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_platforms
	li $s7, 0
	sw $s7, 0($t1)
	j bounce_1

bounce_left1:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_platforms
	li $s7, 1
	sw $s7, 0($t1)
	j bounce_1
bounce_right2:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_platforms
	li $s7, 0
	sw $s7, 4($t1)
	j bounce_2

bounce_left2:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_platforms
	li $s7, 1
	sw $s7, 4($t1)
	j bounce_2
bounce_right3:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_platforms
	li $s7, 0
	sw $s7, 8($t1)
	j bounce_3

bounce_left3:
	# the platform reach the left most, change direction to right
	la $t1, direction_for_platforms
	li $s7, 1
	sw $s7, 8($t1)
	j bounce_3

go_right_platform1: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_floor
	addi $a0, $a0, 4
	jal draw_floor
	sw $a0, 0($t1)
	j second_platform

go_left_platform1: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_floor
	addi $a0, $a0, -4
	jal draw_floor
	sw $a0, 0($t1)
	j second_platform
go_right_platform2: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_floor
	addi $a0, $a0, 4
	jal draw_floor
	sw $a0, 4($t1)
	j third_platform

go_left_platform2: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_floor
	addi $a0, $a0, -4
	jal draw_floor
	sw $a0, 4($t1)
	j third_platform
go_right_platform3: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_floor
	addi $a0, $a0, 4
	jal draw_floor
	sw $a0, 8($t1)
	j floor_location_back

go_left_platform3: 
	# make the platform go right
	# $a0 is the platform location
	jal erase_floor
	addi $a0, $a0, -4
	jal draw_floor
	sw $a0, 8($t1)
	j floor_location_back

erase_floor_pre_1:
	li $a0, 15132
	jal erase_floor_long
	j erase_floor_back
erase_floor_pre_2:
	li $a0, 13904
	jal erase_floor_long
	j erase_floor_back
erase_floor_pre_3: 
	li $a0, 12676
	jal erase_floor_long
	j erase_floor_back
erase_floor_pre_4:
	li $a0, 11448
	jal erase_floor_long
	j erase_floor_back

touch_white_left:
	la $t1, me_location
	lw $t2, 0($t1)
	li $v0, 32
	li $a0, 200
	syscall
	move $a0, $t2
	jal erase_me
	li $a1, 4
	jal draw_me
	j green_continue

touch_white_right:
	la $t1, me_location
	lw $t2, 0($t1)
	li $v0, 32
	li $a0, 200
	syscall
	move $a0, $t2
	jal erase_me
	li $a1, -4
	jal draw_me
	j green_continue


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
	li $t3, 6
	beq $t2, $t3, have_6_heart
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

have_6_heart:
	la $t0, base_address
	addi $t0, $t0, 7136
	li $s0, GREY
	sw $s0, 4($t0)
	sw $s0, 12($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	sw $s0, 268($t0)
	sw $s0, 272($t0)
	sw $s0, 516($t0)
	sw $s0, 520($t0)
	sw $s0, 524($t0)
	sw $s0, 776($t0)
	jr $ra

have_5_heart:
	la $t0, base_address
	addi $t0, $t0, 6924
	li $s0, GREY
	sw $s0, 4($t0)
	sw $s0, 12($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	sw $s0, 268($t0)
	sw $s0, 272($t0)
	sw $s0, 516($t0)
	sw $s0, 520($t0)
	sw $s0, 524($t0)
	sw $s0, 776($t0)
	jr $ra
have_4_heart:
	la $t0, base_address
	addi $t0, $t0, 4320
	li $s0, GREY
	sw $s0, 4($t0)
	sw $s0, 12($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	sw $s0, 268($t0)
	sw $s0, 272($t0)
	sw $s0, 516($t0)
	sw $s0, 520($t0)
	sw $s0, 524($t0)
	sw $s0, 776($t0)
	jr $ra
have_3_heart:
	la $t0, base_address
	addi $t0, $t0, 4108
	li $s0, GREY
	sw $s0, 4($t0)
	sw $s0, 12($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	sw $s0, 268($t0)
	sw $s0, 272($t0)
	sw $s0, 516($t0)
	sw $s0, 520($t0)
	sw $s0, 524($t0)
	sw $s0, 776($t0)
	jr $ra
have_2_heart:
	la $t0, base_address
	addi $t0, $t0, 1504
	li $s0, GREY
	sw $s0, 4($t0)
	sw $s0, 12($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	sw $s0, 268($t0)
	sw $s0, 272($t0)
	sw $s0, 516($t0)
	sw $s0, 520($t0)
	sw $s0, 524($t0)
	sw $s0, 776($t0)
	jr $ra
have_1_heart:
	la $t0, base_address
	addi $t0, $t0, 1292
	li $s0, GREY
	sw $s0, 4($t0)
	sw $s0, 12($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	sw $s0, 268($t0)
	sw $s0, 272($t0)
	sw $s0, 516($t0)
	sw $s0, 520($t0)
	sw $s0, 524($t0)
	sw $s0, 776($t0)
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
	lw $t7, 4($t8)		# have input, put input to t7
	
	# restart will be faster than anycase
	beq $t7, 112, A_RESTART	# if P was pressed
	# DETERMINE WHICH DIRECTION IT IS GOING

	beq $t7, 97, A_LEFT		# if a was pressed
	beq $t7, 100, A_RIGHT	# if d was pressed

	# if under is black and double jump counter is 0
	la $t1, me_location
	lw $t2, 0($t1)
	addi $t2, $t2, 1024
	# me is at t2
	la $t0, base_address
	add $t0, $t0, $t2
	lw $t3, 0($t0)
	bne $t3, WHITE, another
	# if the color is white, doesn't care
can_jump:
	beq $t7, 119, A_JUMP
	j update_done	
another:
	# color is not white
	la $t1, double_jump_counter
	lw $t2, 0($t1)
	beq $t2, $zero, no_jump
	# it's 1, can jump, and you are in the sky
	beq $t7, 119, jumped
no_jump:
	j update_done		# if not them, back to before
	
jumped:
	# it jumped, make the double jump counter 0
	sw $zero, 0($t1)
	j can_jump

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
	addi $t4, $t2, -256
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
	li $a1, -256
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
	addi $t4, $t2, -256
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
	li $a1, -256
	jal draw_me

next_jump: 
	j jump_twice

actual_jump_2:
	addi $t4, $t2, -256
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
	li $a1, -256
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
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing2 # if color is not white, not falling
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing2 # if color is not white, not falling
	addi $t0, $t0, 256
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
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing3 # if color is not white, not falling
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing3 # if color is not white, not falling
	addi $t0, $t0, 256
	lw  $t3, 0($t0)
	bne $t3, BLACK, donothing3 # if color is not white, not falling
	move $a0, $t2
	jal erase_me
	li $a1, 4
	jal draw_me

donothing3: 
	j update_done

A_RESTART:
	la $t1, me_location
	li $s1, 13860
	sw $s1, 0($t1)

	la $t1, heart
	li $s1, 6
	sw $s1, 0($t1)

	la $t1, jump_counter
	li $s1, 0
	sw $s1, 0($t1)

	la $t1, counter
	li $s1, 0
	sw $s1, 0($t1)

	la $t1, counter_for_floor
	li $s1, 500
	sw $s1, 0($t1)

	la $t1, platforms
	li $s1, 3468
	li $s2, 6500
	li $s3, 10108
	sw $s1, 0($t1)
	sw $s2, 4($t1)
	sw $s3, 8($t1)

	la $t1, counter_for_platforms
	li $s1, platform_counter
	sw $s1, 0($t1)

	la $t1, double_jump_counter
	li $s1, 1
	sw $s1, 0($t1)

	la $t1, direction_for_platforms
	li $s1, 1
	li $s2, 0
	li $s3, 1
	sw $s1, 0($t1)
	sw $s2, 4($t1)
	sw $s3, 8($t1)

	la $t1, obs
	li $s1, 4432
	li $s2, 7564
	sw $s1, 0($t1)
	sw $s2, 4($t1)

	la $t1, counter_for_obstacles
	li $s1, ob_counter
	sw $s1, 0($t1)

	la $t1, direction_for_obs
	li $s1, 0
	li $s2, 1
	sw $s1, 0($t1)
	sw $s2, 4($t1)

	j start



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
	sw $s0, 256($t0)
	sw $s0, 264($t0)
	sw $s0, 516($t0)
	sw $s0, 768($t0)
	sw $s0, 772($t0)
	sw $s0, 776($t0)
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
	li $s1, 13860
	sw $s1, 0($t1)

	la $t1, heart
	li $s1, 6
	sw $s1, 0($t1)

	la $t1, jump_counter
	li $s1, 0
	sw $s1, 0($t1)

	la $t1, counter
	li $s1, 0
	sw $s1, 0($t1)

	la $t1, counter_for_floor
	li $s1, 500
	sw $s1, 0($t1)

	la $t1, platforms
	li $s1, 3468
	li $s2, 6500
	li $s3, 10108
	sw $s1, 0($t1)
	sw $s2, 4($t1)
	sw $s3, 8($t1)

	la $t1, counter_for_platforms
	li $s1, platform_counter
	sw $s1, 0($t1)

	la $t1, double_jump_counter
	li $s1, 1
	sw $s1, 0($t1)

	la $t1, direction_for_platforms
	li $s1, 1
	li $s2, 0
	li $s3, 1
	sw $s1, 0($t1)
	sw $s2, 4($t1)
	sw $s3, 8($t1)

	la $t1, obs
	li $s1, 4432
	li $s2, 7564
	sw $s1, 0($t1)
	sw $s2, 4($t1)

	la $t1, counter_for_obstacles
	li $s1, ob_counter
	sw $s1, 0($t1)

	la $t1, direction_for_obs
	li $s1, 0
	li $s2, 1
	sw $s1, 0($t1)
	sw $s2, 4($t1)

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
	sw $s0, 256($t0)
	sw $s0, 264($t0)
	sw $s0, 516($t0)
	sw $s0, 768($t0)
	sw $s0, 772($t0)
	sw $s0, 776($t0)
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

draw_floor:
	la $t0, base_address
	add $t0, $t0, $a0
	li $s0, WHITE
	sw $s0, 0($t0)
	sw $s0, 4($t0)
	sw $s0, 8($t0)
	sw $s0, 12($t0)
	sw $s0, 16($t0)
	sw $s0, 20($t0)
	sw $s0, 24($t0)
	sw $s0, 28($t0)
	jr $ra

erase_floor_long:
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
	sw $s0, 32($t0)
	sw $s0, 36($t0)
	jr $ra

draw_floor_long:
	la $t0, base_address
	add $t0, $t0, $a0
	li $s0, WHITE
	sw $s0, 0($t0)
	sw $s0, 4($t0)
	sw $s0, 8($t0)
	sw $s0, 12($t0)
	sw $s0, 16($t0)
	sw $s0, 20($t0)
	sw $s0, 24($t0)
	sw $s0, 28($t0)
	sw $s0, 32($t0)
	sw $s0, 36($t0)
	jr $ra

erase_ob:
	la $t0, base_address
	add $t0, $t0, $a0
	li $s0, BLACK
	sw $s0, 4($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	jr $ra

draw_ob:
	la $t0, base_address
	add $t0, $t0, $a0
	li $s0, GREY
	sw $s0, 4($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	jr $ra

erase_win_object:
	la $t0, base_address
	add $t0, $t0, $a0
	li $s0, BLACK
	sw $s0, 0($t0)
	sw $s0, 8($t0)
	sw $s0, 16($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	sw $s0, 268($t0)
	sw $s0, 272($t0)
	sw $s0, 516($t0)
	sw $s0, 524($t0)
	jr $ra

draw_win_object:
	la $t0, base_address
	add $t0, $t0, $a0
	li $s0, GOLDEN
	sw $s0, 0($t0)
	sw $s0, 8($t0)
	sw $s0, 16($t0)
	sw $s0, 256($t0)
	sw $s0, 260($t0)
	sw $s0, 264($t0)
	sw $s0, 268($t0)
	sw $s0, 272($t0)
	sw $s0, 516($t0)
	sw $s0, 524($t0)
	jr $ra

clear_screen:
	# t0 is the start address, t1 is black color, t2 is the counter
	la $t0, base_address
	li $t1, BLACK
	li $t2, 0 

clear_loop:
	bge $t2, 4096, clear_end # if counter is greater than or equal to 64*64, it's end
	sw $t1, 0($t0)  # set current pixel to black
	addi $t0, $t0, 4 # move to next pixel
	addi $t2, $t2, 1 # counter = counter + 1
	j clear_loop

clear_end:
	jr $ra

show_gamename:
	# show the start page of the game
	la $t0, base_address
	li $t1, BLUE
	li $t2, GREEN
	li $t3, GOLDEN
	li $t4, WHITE
	li $t5, ORANGE
	li $t6, GREY
	li $t7, RED
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	sw $t1, 84($t0)
	sw $t1, 88($t0)
	sw $t1, 92($t0)
	sw $t1, 96($t0)
	sw $t1, 100($t0)
	sw $t1, 104($t0)
	sw $t1, 108($t0)
	sw $t1, 112($t0)
	sw $t1, 116($t0)
	sw $t1, 120($t0)
	sw $t1, 124($t0)
	sw $t1, 128($t0)
	sw $t1, 132($t0)
	sw $t1, 136($t0)
	sw $t1, 140($t0)
	sw $t1, 144($t0)
	sw $t1, 148($t0)
	sw $t1, 152($t0)
	sw $t1, 156($t0)
	sw $t1, 160($t0)
	sw $t1, 164($t0)
	sw $t1, 168($t0)
	sw $t1, 172($t0)
	sw $t1, 176($t0)
	sw $t1, 180($t0)
	sw $t1, 184($t0)
	sw $t1, 188($t0)
	sw $t1, 192($t0)
	sw $t1, 196($t0)
	sw $t1, 200($t0)
	sw $t1, 204($t0)
	sw $t1, 208($t0)
	sw $t1, 212($t0)
	sw $t1, 216($t0)
	sw $t1, 220($t0)
	sw $t1, 224($t0)
	sw $t1, 228($t0)
	sw $t1, 232($t0)
	sw $t1, 236($t0)
	sw $t1, 240($t0)
	sw $t1, 244($t0)
	sw $t1, 248($t0)
	sw $t1, 252($t0)
	sw $t1, 256($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 268($t0)
	sw $t1, 272($t0)
	sw $t1, 276($t0)
	sw $t1, 280($t0)
	sw $t1, 284($t0)
	sw $t1, 288($t0)
	sw $t1, 292($t0)
	sw $t1, 296($t0)
	sw $t1, 300($t0)
	sw $t1, 304($t0)
	sw $t1, 308($t0)
	sw $t1, 312($t0)
	sw $t1, 316($t0)
	sw $t1, 320($t0)
	sw $t1, 324($t0)
	sw $t1, 328($t0)
	sw $t1, 332($t0)
	sw $t1, 336($t0)
	sw $t1, 340($t0)
	sw $t1, 344($t0)
	sw $t1, 348($t0)
	sw $t1, 352($t0)
	sw $t1, 356($t0)
	sw $t1, 360($t0)
	sw $t1, 364($t0)
	sw $t1, 368($t0)
	sw $t1, 372($t0)
	sw $t1, 376($t0)
	sw $t1, 380($t0)
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 392($t0)
	sw $t1, 396($t0)
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
	sw $t1, 440($t0)
	sw $t1, 444($t0)
	sw $t1, 448($t0)
	sw $t1, 452($t0)
	sw $t1, 456($t0)
	sw $t1, 460($t0)
	sw $t1, 464($t0)
	sw $t1, 468($t0)
	sw $t1, 472($t0)
	sw $t1, 476($t0)
	sw $t1, 480($t0)
	sw $t1, 484($t0)
	sw $t1, 488($t0)
	sw $t1, 492($t0)
	sw $t1, 496($t0)
	sw $t1, 500($t0)
	sw $t1, 504($t0)
	sw $t1, 508($t0)
	sw $t2, 1552($t0)
	sw $t2, 1556($t0)
	sw $t2, 1564($t0)
	sw $t2, 1572($t0)
	sw $t2, 1580($t0)
	sw $t2, 1588($t0)
	sw $t2, 1596($t0)
	sw $t2, 1728($t0)
	sw $t2, 1736($t0)
	sw $t2, 1744($t0)
	sw $t2, 1752($t0)
	sw $t2, 1760($t0)
	sw $t2, 1768($t0)
	sw $t2, 1772($t0)
	sw $t2, 1812($t0)
	sw $t2, 1816($t0)
	sw $t2, 1820($t0)
	sw $t2, 1824($t0)
	sw $t2, 1828($t0)
	sw $t2, 1832($t0)
	sw $t2, 1836($t0)
	sw $t2, 1840($t0)
	sw $t2, 1844($t0)
	sw $t2, 1848($t0)
	sw $t2, 1852($t0)
	sw $t2, 1856($t0)
	sw $t2, 1980($t0)
	sw $t2, 1984($t0)
	sw $t2, 1988($t0)
	sw $t2, 1992($t0)
	sw $t2, 1996($t0)
	sw $t2, 2000($t0)
	sw $t2, 2004($t0)
	sw $t2, 2008($t0)
	sw $t2, 2012($t0)
	sw $t2, 2016($t0)
	sw $t2, 2020($t0)
	sw $t2, 2024($t0)
	sw $t2, 2064($t0)
	sw $t2, 2068($t0)
	sw $t2, 2108($t0)
	sw $t3, 2160($t0)
	sw $t3, 2168($t0)
	sw $t3, 2176($t0)
	sw $t2, 2240($t0)
	sw $t2, 2280($t0)
	sw $t2, 2284($t0)
	sw $t2, 2324($t0)
	sw $t4, 2340($t0)
	sw $t4, 2348($t0)
	sw $t2, 2364($t0)
	sw $t2, 2368($t0)
	sw $t3, 2416($t0)
	sw $t3, 2420($t0)
	sw $t3, 2424($t0)
	sw $t3, 2428($t0)
	sw $t3, 2432($t0)
	sw $t2, 2492($t0)
	sw $t2, 2496($t0)
	sw $t4, 2512($t0)
	sw $t4, 2520($t0)
	sw $t2, 2536($t0)
	sw $t2, 2576($t0)
	sw $t2, 2580($t0)
	sw $t4, 2592($t0)
	sw $t5, 2596($t0)
	sw $t4, 2600($t0)
	sw $t5, 2604($t0)
	sw $t4, 2608($t0)
	sw $t2, 2620($t0)
	sw $t3, 2676($t0)
	sw $t3, 2684($t0)
	sw $t2, 2752($t0)
	sw $t4, 2764($t0)
	sw $t5, 2768($t0)
	sw $t4, 2772($t0)
	sw $t5, 2776($t0)
	sw $t4, 2780($t0)
	sw $t2, 2792($t0)
	sw $t2, 2796($t0)
	sw $t2, 2836($t0)
	sw $t4, 2844($t0)
	sw $t5, 2848($t0)
	sw $t5, 2852($t0)
	sw $t5, 2856($t0)
	sw $t5, 2860($t0)
	sw $t5, 2864($t0)
	sw $t4, 2868($t0)
	sw $t2, 2876($t0)
	sw $t2, 2880($t0)
	sw $t4, 2924($t0)
	sw $t4, 2928($t0)
	sw $t4, 2932($t0)
	sw $t4, 2936($t0)
	sw $t4, 2940($t0)
	sw $t4, 2944($t0)
	sw $t4, 2948($t0)
	sw $t2, 3004($t0)
	sw $t2, 3008($t0)
	sw $t4, 3016($t0)
	sw $t5, 3020($t0)
	sw $t5, 3024($t0)
	sw $t5, 3028($t0)
	sw $t5, 3032($t0)
	sw $t5, 3036($t0)
	sw $t4, 3040($t0)
	sw $t2, 3048($t0)
	sw $t2, 3088($t0)
	sw $t2, 3092($t0)
	sw $t4, 3104($t0)
	sw $t5, 3108($t0)
	sw $t5, 3112($t0)
	sw $t5, 3116($t0)
	sw $t4, 3120($t0)
	sw $t2, 3132($t0)
	sw $t4, 3176($t0)
	sw $t4, 3180($t0)
	sw $t4, 3204($t0)
	sw $t4, 3208($t0)
	sw $t2, 3264($t0)
	sw $t4, 3276($t0)
	sw $t5, 3280($t0)
	sw $t5, 3284($t0)
	sw $t5, 3288($t0)
	sw $t4, 3292($t0)
	sw $t2, 3304($t0)
	sw $t2, 3308($t0)
	sw $t2, 3348($t0)
	sw $t4, 3364($t0)
	sw $t5, 3368($t0)
	sw $t4, 3372($t0)
	sw $t2, 3388($t0)
	sw $t2, 3392($t0)
	sw $t2, 3516($t0)
	sw $t2, 3520($t0)
	sw $t4, 3536($t0)
	sw $t5, 3540($t0)
	sw $t4, 3544($t0)
	sw $t2, 3560($t0)
	sw $t2, 3600($t0)
	sw $t2, 3604($t0)
	sw $t4, 3624($t0)
	sw $t2, 3644($t0)
	sw $t2, 3776($t0)
	sw $t4, 3796($t0)
	sw $t2, 3816($t0)
	sw $t2, 3820($t0)
	sw $t2, 3860($t0)
	sw $t2, 3900($t0)
	sw $t2, 3904($t0)
	sw $t2, 4028($t0)
	sw $t2, 4032($t0)
	sw $t2, 4072($t0)
	sw $t2, 4112($t0)
	sw $t2, 4116($t0)
	sw $t2, 4120($t0)
	sw $t2, 4124($t0)
	sw $t2, 4128($t0)
	sw $t2, 4132($t0)
	sw $t2, 4136($t0)
	sw $t2, 4140($t0)
	sw $t2, 4144($t0)
	sw $t2, 4148($t0)
	sw $t2, 4152($t0)
	sw $t2, 4156($t0)
	sw $t6, 4240($t0)
	sw $t2, 4288($t0)
	sw $t2, 4292($t0)
	sw $t2, 4296($t0)
	sw $t2, 4300($t0)
	sw $t2, 4304($t0)
	sw $t2, 4308($t0)
	sw $t2, 4312($t0)
	sw $t2, 4316($t0)
	sw $t2, 4320($t0)
	sw $t2, 4324($t0)
	sw $t2, 4328($t0)
	sw $t2, 4332($t0)
	sw $t2, 4372($t0)
	sw $t2, 4380($t0)
	sw $t2, 4388($t0)
	sw $t2, 4396($t0)
	sw $t2, 4404($t0)
	sw $t2, 4412($t0)
	sw $t2, 4416($t0)
	sw $t6, 4492($t0)
	sw $t6, 4496($t0)
	sw $t6, 4500($t0)
	sw $t2, 4540($t0)
	sw $t2, 4544($t0)
	sw $t2, 4552($t0)
	sw $t2, 4560($t0)
	sw $t2, 4568($t0)
	sw $t2, 4576($t0)
	sw $t2, 4584($t0)
	sw $t4, 4748($t0)
	sw $t4, 4752($t0)
	sw $t4, 4756($t0)
	sw $t4, 4760($t0)
	sw $t4, 4764($t0)
	sw $t4, 4768($t0)
	sw $t4, 4772($t0)
	sw $t4, 4776($t0)
	sw $t4, 5896($t0)
	sw $t4, 5900($t0)
	sw $t4, 5904($t0)
	sw $t4, 5908($t0)
	sw $t4, 5912($t0)
	sw $t4, 5916($t0)
	sw $t4, 5920($t0)
	sw $t4, 5924($t0)
	sw $t4, 5928($t0)
	sw $t4, 5936($t0)
	sw $t4, 5940($t0)
	sw $t4, 5944($t0)
	sw $t4, 5948($t0)
	sw $t4, 5952($t0)
	sw $t4, 5956($t0)
	sw $t4, 5960($t0)
	sw $t4, 5964($t0)
	sw $t4, 5968($t0)
	sw $t4, 5976($t0)
	sw $t4, 5980($t0)
	sw $t4, 5984($t0)
	sw $t4, 5988($t0)
	sw $t4, 5992($t0)
	sw $t4, 5996($t0)
	sw $t4, 6000($t0)
	sw $t4, 6004($t0)
	sw $t4, 6008($t0)
	sw $t4, 6032($t0)
	sw $t4, 6036($t0)
	sw $t4, 6040($t0)
	sw $t4, 6064($t0)
	sw $t4, 6068($t0)
	sw $t4, 6072($t0)
	sw $t4, 6076($t0)
	sw $t4, 6080($t0)
	sw $t4, 6084($t0)
	sw $t4, 6088($t0)
	sw $t4, 6092($t0)
	sw $t4, 6096($t0)
	sw $t4, 6104($t0)
	sw $t4, 6108($t0)
	sw $t4, 6112($t0)
	sw $t4, 6116($t0)
	sw $t4, 6120($t0)
	sw $t4, 6124($t0)
	sw $t4, 6128($t0)
	sw $t4, 6132($t0)
	sw $t4, 6136($t0)
	sw $t4, 6152($t0)
	sw $t3, 6156($t0)
	sw $t3, 6160($t0)
	sw $t3, 6164($t0)
	sw $t3, 6168($t0)
	sw $t3, 6172($t0)
	sw $t3, 6176($t0)
	sw $t3, 6180($t0)
	sw $t4, 6184($t0)
	sw $t4, 6192($t0)
	sw $t3, 6196($t0)
	sw $t3, 6200($t0)
	sw $t3, 6204($t0)
	sw $t3, 6208($t0)
	sw $t3, 6212($t0)
	sw $t3, 6216($t0)
	sw $t3, 6220($t0)
	sw $t4, 6224($t0)
	sw $t4, 6232($t0)
	sw $t3, 6236($t0)
	sw $t3, 6240($t0)
	sw $t3, 6244($t0)
	sw $t3, 6248($t0)
	sw $t3, 6252($t0)
	sw $t3, 6256($t0)
	sw $t3, 6260($t0)
	sw $t4, 6264($t0)
	sw $t4, 6284($t0)
	sw $t4, 6288($t0)
	sw $t3, 6292($t0)
	sw $t4, 6296($t0)
	sw $t4, 6300($t0)
	sw $t4, 6320($t0)
	sw $t3, 6324($t0)
	sw $t3, 6328($t0)
	sw $t3, 6332($t0)
	sw $t3, 6336($t0)
	sw $t3, 6340($t0)
	sw $t3, 6344($t0)
	sw $t3, 6348($t0)
	sw $t4, 6352($t0)
	sw $t4, 6360($t0)
	sw $t3, 6364($t0)
	sw $t3, 6368($t0)
	sw $t3, 6372($t0)
	sw $t3, 6376($t0)
	sw $t3, 6380($t0)
	sw $t3, 6384($t0)
	sw $t3, 6388($t0)
	sw $t4, 6392($t0)
	sw $t4, 6408($t0)
	sw $t3, 6412($t0)
	sw $t4, 6416($t0)
	sw $t4, 6420($t0)
	sw $t4, 6424($t0)
	sw $t4, 6428($t0)
	sw $t4, 6432($t0)
	sw $t4, 6436($t0)
	sw $t4, 6440($t0)
	sw $t4, 6448($t0)
	sw $t3, 6452($t0)
	sw $t4, 6456($t0)
	sw $t4, 6460($t0)
	sw $t4, 6464($t0)
	sw $t4, 6468($t0)
	sw $t4, 6472($t0)
	sw $t4, 6476($t0)
	sw $t4, 6480($t0)
	sw $t4, 6488($t0)
	sw $t3, 6492($t0)
	sw $t4, 6496($t0)
	sw $t4, 6500($t0)
	sw $t4, 6504($t0)
	sw $t4, 6508($t0)
	sw $t4, 6512($t0)
	sw $t4, 6516($t0)
	sw $t4, 6520($t0)
	sw $t4, 6536($t0)
	sw $t4, 6540($t0)
	sw $t3, 6544($t0)
	sw $t3, 6548($t0)
	sw $t3, 6552($t0)
	sw $t4, 6556($t0)
	sw $t4, 6560($t0)
	sw $t4, 6576($t0)
	sw $t3, 6580($t0)
	sw $t4, 6584($t0)
	sw $t4, 6588($t0)
	sw $t4, 6592($t0)
	sw $t4, 6596($t0)
	sw $t4, 6600($t0)
	sw $t3, 6604($t0)
	sw $t4, 6608($t0)
	sw $t4, 6616($t0)
	sw $t3, 6620($t0)
	sw $t4, 6624($t0)
	sw $t4, 6628($t0)
	sw $t4, 6632($t0)
	sw $t4, 6636($t0)
	sw $t4, 6640($t0)
	sw $t4, 6644($t0)
	sw $t4, 6648($t0)
	sw $t4, 6664($t0)
	sw $t3, 6668($t0)
	sw $t4, 6672($t0)
	sw $t4, 6704($t0)
	sw $t3, 6708($t0)
	sw $t4, 6712($t0)
	sw $t4, 6744($t0)
	sw $t3, 6748($t0)
	sw $t4, 6752($t0)
	sw $t4, 6792($t0)
	sw $t3, 6796($t0)
	sw $t3, 6800($t0)
	sw $t4, 6804($t0)
	sw $t3, 6808($t0)
	sw $t3, 6812($t0)
	sw $t4, 6816($t0)
	sw $t4, 6832($t0)
	sw $t3, 6836($t0)
	sw $t4, 6840($t0)
	sw $t4, 6856($t0)
	sw $t3, 6860($t0)
	sw $t4, 6864($t0)
	sw $t4, 6872($t0)
	sw $t3, 6876($t0)
	sw $t4, 6880($t0)
	sw $t4, 6920($t0)
	sw $t3, 6924($t0)
	sw $t4, 6928($t0)
	sw $t4, 6960($t0)
	sw $t3, 6964($t0)
	sw $t4, 6968($t0)
	sw $t4, 7000($t0)
	sw $t3, 7004($t0)
	sw $t4, 7008($t0)
	sw $t4, 7048($t0)
	sw $t3, 7052($t0)
	sw $t4, 7056($t0)
	sw $t4, 7064($t0)
	sw $t3, 7068($t0)
	sw $t4, 7072($t0)
	sw $t4, 7088($t0)
	sw $t3, 7092($t0)
	sw $t4, 7096($t0)
	sw $t4, 7112($t0)
	sw $t3, 7116($t0)
	sw $t4, 7120($t0)
	sw $t4, 7128($t0)
	sw $t3, 7132($t0)
	sw $t4, 7136($t0)
	sw $t4, 7176($t0)
	sw $t3, 7180($t0)
	sw $t4, 7184($t0)
	sw $t4, 7188($t0)
	sw $t4, 7192($t0)
	sw $t4, 7196($t0)
	sw $t4, 7200($t0)
	sw $t4, 7204($t0)
	sw $t4, 7208($t0)
	sw $t4, 7216($t0)
	sw $t3, 7220($t0)
	sw $t4, 7224($t0)
	sw $t4, 7228($t0)
	sw $t4, 7232($t0)
	sw $t4, 7236($t0)
	sw $t4, 7240($t0)
	sw $t4, 7244($t0)
	sw $t4, 7248($t0)
	sw $t4, 7256($t0)
	sw $t3, 7260($t0)
	sw $t4, 7264($t0)
	sw $t4, 7304($t0)
	sw $t3, 7308($t0)
	sw $t4, 7312($t0)
	sw $t4, 7316($t0)
	sw $t4, 7320($t0)
	sw $t3, 7324($t0)
	sw $t4, 7328($t0)
	sw $t4, 7344($t0)
	sw $t3, 7348($t0)
	sw $t4, 7352($t0)
	sw $t4, 7356($t0)
	sw $t4, 7360($t0)
	sw $t4, 7364($t0)
	sw $t4, 7368($t0)
	sw $t3, 7372($t0)
	sw $t4, 7376($t0)
	sw $t4, 7384($t0)
	sw $t3, 7388($t0)
	sw $t4, 7392($t0)
	sw $t4, 7396($t0)
	sw $t4, 7400($t0)
	sw $t4, 7404($t0)
	sw $t4, 7408($t0)
	sw $t4, 7412($t0)
	sw $t4, 7416($t0)
	sw $t4, 7432($t0)
	sw $t3, 7436($t0)
	sw $t3, 7440($t0)
	sw $t3, 7444($t0)
	sw $t3, 7448($t0)
	sw $t3, 7452($t0)
	sw $t3, 7456($t0)
	sw $t3, 7460($t0)
	sw $t4, 7464($t0)
	sw $t4, 7472($t0)
	sw $t3, 7476($t0)
	sw $t3, 7480($t0)
	sw $t3, 7484($t0)
	sw $t3, 7488($t0)
	sw $t3, 7492($t0)
	sw $t3, 7496($t0)
	sw $t3, 7500($t0)
	sw $t4, 7504($t0)
	sw $t4, 7512($t0)
	sw $t3, 7516($t0)
	sw $t4, 7520($t0)
	sw $t4, 7556($t0)
	sw $t4, 7560($t0)
	sw $t3, 7564($t0)
	sw $t3, 7568($t0)
	sw $t3, 7572($t0)
	sw $t3, 7576($t0)
	sw $t3, 7580($t0)
	sw $t4, 7584($t0)
	sw $t4, 7588($t0)
	sw $t4, 7600($t0)
	sw $t3, 7604($t0)
	sw $t3, 7608($t0)
	sw $t3, 7612($t0)
	sw $t3, 7616($t0)
	sw $t3, 7620($t0)
	sw $t3, 7624($t0)
	sw $t3, 7628($t0)
	sw $t4, 7632($t0)
	sw $t4, 7640($t0)
	sw $t3, 7644($t0)
	sw $t3, 7648($t0)
	sw $t3, 7652($t0)
	sw $t3, 7656($t0)
	sw $t3, 7660($t0)
	sw $t3, 7664($t0)
	sw $t3, 7668($t0)
	sw $t4, 7672($t0)
	sw $t4, 7688($t0)
	sw $t3, 7692($t0)
	sw $t4, 7696($t0)
	sw $t4, 7704($t0)
	sw $t4, 7708($t0)
	sw $t4, 7712($t0)
	sw $t4, 7716($t0)
	sw $t4, 7720($t0)
	sw $t4, 7728($t0)
	sw $t4, 7732($t0)
	sw $t4, 7736($t0)
	sw $t4, 7740($t0)
	sw $t4, 7744($t0)
	sw $t4, 7748($t0)
	sw $t4, 7752($t0)
	sw $t3, 7756($t0)
	sw $t4, 7760($t0)
	sw $t4, 7768($t0)
	sw $t3, 7772($t0)
	sw $t4, 7776($t0)
	sw $t4, 7812($t0)
	sw $t3, 7816($t0)
	sw $t3, 7820($t0)
	sw $t4, 7824($t0)
	sw $t4, 7828($t0)
	sw $t4, 7832($t0)
	sw $t3, 7836($t0)
	sw $t3, 7840($t0)
	sw $t4, 7844($t0)
	sw $t4, 7856($t0)
	sw $t3, 7860($t0)
	sw $t4, 7864($t0)
	sw $t4, 7868($t0)
	sw $t4, 7872($t0)
	sw $t4, 7876($t0)
	sw $t4, 7880($t0)
	sw $t4, 7884($t0)
	sw $t4, 7888($t0)
	sw $t4, 7896($t0)
	sw $t3, 7900($t0)
	sw $t4, 7904($t0)
	sw $t4, 7908($t0)
	sw $t4, 7912($t0)
	sw $t4, 7916($t0)
	sw $t4, 7920($t0)
	sw $t4, 7924($t0)
	sw $t4, 7928($t0)
	sw $t4, 7944($t0)
	sw $t3, 7948($t0)
	sw $t4, 7952($t0)
	sw $t4, 8008($t0)
	sw $t3, 8012($t0)
	sw $t4, 8016($t0)
	sw $t4, 8024($t0)
	sw $t3, 8028($t0)
	sw $t4, 8032($t0)
	sw $t4, 8064($t0)
	sw $t4, 8068($t0)
	sw $t3, 8072($t0)
	sw $t3, 8076($t0)
	sw $t4, 8080($t0)
	sw $t4, 8088($t0)
	sw $t3, 8092($t0)
	sw $t3, 8096($t0)
	sw $t4, 8100($t0)
	sw $t4, 8104($t0)
	sw $t4, 8112($t0)
	sw $t3, 8116($t0)
	sw $t4, 8120($t0)
	sw $t4, 8152($t0)
	sw $t3, 8156($t0)
	sw $t4, 8160($t0)
	sw $t4, 8200($t0)
	sw $t3, 8204($t0)
	sw $t4, 8208($t0)
	sw $t4, 8264($t0)
	sw $t3, 8268($t0)
	sw $t4, 8272($t0)
	sw $t4, 8280($t0)
	sw $t3, 8284($t0)
	sw $t4, 8288($t0)
	sw $t4, 8320($t0)
	sw $t3, 8324($t0)
	sw $t3, 8328($t0)
	sw $t4, 8332($t0)
	sw $t4, 8348($t0)
	sw $t3, 8352($t0)
	sw $t3, 8356($t0)
	sw $t4, 8360($t0)
	sw $t4, 8368($t0)
	sw $t3, 8372($t0)
	sw $t4, 8376($t0)
	sw $t4, 8408($t0)
	sw $t3, 8412($t0)
	sw $t4, 8416($t0)
	sw $t4, 8456($t0)
	sw $t3, 8460($t0)
	sw $t4, 8464($t0)
	sw $t4, 8468($t0)
	sw $t4, 8472($t0)
	sw $t4, 8476($t0)
	sw $t4, 8480($t0)
	sw $t4, 8484($t0)
	sw $t4, 8488($t0)
	sw $t4, 8496($t0)
	sw $t4, 8500($t0)
	sw $t4, 8504($t0)
	sw $t4, 8508($t0)
	sw $t4, 8512($t0)
	sw $t4, 8516($t0)
	sw $t4, 8520($t0)
	sw $t3, 8524($t0)
	sw $t4, 8528($t0)
	sw $t4, 8536($t0)
	sw $t3, 8540($t0)
	sw $t4, 8544($t0)
	sw $t4, 8548($t0)
	sw $t4, 8552($t0)
	sw $t4, 8556($t0)
	sw $t4, 8560($t0)
	sw $t4, 8564($t0)
	sw $t4, 8568($t0)
	sw $t4, 8576($t0)
	sw $t3, 8580($t0)
	sw $t4, 8584($t0)
	sw $t4, 8588($t0)
	sw $t4, 8604($t0)
	sw $t4, 8608($t0)
	sw $t3, 8612($t0)
	sw $t4, 8616($t0)
	sw $t4, 8624($t0)
	sw $t3, 8628($t0)
	sw $t4, 8632($t0)
	sw $t4, 8664($t0)
	sw $t3, 8668($t0)
	sw $t4, 8672($t0)
	sw $t4, 8676($t0)
	sw $t4, 8680($t0)
	sw $t4, 8684($t0)
	sw $t4, 8688($t0)
	sw $t4, 8692($t0)
	sw $t4, 8696($t0)
	sw $t4, 8712($t0)
	sw $t3, 8716($t0)
	sw $t3, 8720($t0)
	sw $t3, 8724($t0)
	sw $t3, 8728($t0)
	sw $t3, 8732($t0)
	sw $t3, 8736($t0)
	sw $t3, 8740($t0)
	sw $t4, 8744($t0)
	sw $t4, 8752($t0)
	sw $t3, 8756($t0)
	sw $t3, 8760($t0)
	sw $t3, 8764($t0)
	sw $t3, 8768($t0)
	sw $t3, 8772($t0)
	sw $t3, 8776($t0)
	sw $t3, 8780($t0)
	sw $t4, 8784($t0)
	sw $t4, 8792($t0)
	sw $t3, 8796($t0)
	sw $t3, 8800($t0)
	sw $t3, 8804($t0)
	sw $t3, 8808($t0)
	sw $t3, 8812($t0)
	sw $t3, 8816($t0)
	sw $t3, 8820($t0)
	sw $t4, 8824($t0)
	sw $t4, 8832($t0)
	sw $t3, 8836($t0)
	sw $t4, 8840($t0)
	sw $t4, 8864($t0)
	sw $t3, 8868($t0)
	sw $t4, 8872($t0)
	sw $t4, 8880($t0)
	sw $t3, 8884($t0)
	sw $t4, 8888($t0)
	sw $t4, 8920($t0)
	sw $t3, 8924($t0)
	sw $t3, 8928($t0)
	sw $t3, 8932($t0)
	sw $t3, 8936($t0)
	sw $t3, 8940($t0)
	sw $t3, 8944($t0)
	sw $t3, 8948($t0)
	sw $t4, 8952($t0)
	sw $t4, 8968($t0)
	sw $t4, 8972($t0)
	sw $t4, 8976($t0)
	sw $t4, 8980($t0)
	sw $t4, 8984($t0)
	sw $t4, 8988($t0)
	sw $t4, 8992($t0)
	sw $t4, 8996($t0)
	sw $t4, 9000($t0)
	sw $t4, 9008($t0)
	sw $t4, 9012($t0)
	sw $t4, 9016($t0)
	sw $t4, 9020($t0)
	sw $t4, 9024($t0)
	sw $t4, 9028($t0)
	sw $t4, 9032($t0)
	sw $t4, 9036($t0)
	sw $t4, 9040($t0)
	sw $t4, 9048($t0)
	sw $t4, 9052($t0)
	sw $t4, 9056($t0)
	sw $t4, 9060($t0)
	sw $t4, 9064($t0)
	sw $t4, 9068($t0)
	sw $t4, 9072($t0)
	sw $t4, 9076($t0)
	sw $t4, 9080($t0)
	sw $t4, 9088($t0)
	sw $t4, 9092($t0)
	sw $t4, 9096($t0)
	sw $t4, 9120($t0)
	sw $t4, 9124($t0)
	sw $t4, 9128($t0)
	sw $t4, 9136($t0)
	sw $t4, 9140($t0)
	sw $t4, 9144($t0)
	sw $t4, 9176($t0)
	sw $t4, 9180($t0)
	sw $t4, 9184($t0)
	sw $t4, 9188($t0)
	sw $t4, 9192($t0)
	sw $t4, 9196($t0)
	sw $t4, 9200($t0)
	sw $t4, 9204($t0)
	sw $t4, 9208($t0)
	sw $t2, 10772($t0)
	sw $t2, 10780($t0)
	sw $t2, 10788($t0)
	sw $t2, 10796($t0)
	sw $t2, 10804($t0)
	sw $t2, 10812($t0)
	sw $t2, 10816($t0)
	sw $t6, 10868($t0)
	sw $t2, 10940($t0)
	sw $t2, 10944($t0)
	sw $t2, 10952($t0)
	sw $t2, 10960($t0)
	sw $t2, 10968($t0)
	sw $t2, 10976($t0)
	sw $t2, 10984($t0)
	sw $t2, 11024($t0)
	sw $t2, 11028($t0)
	sw $t2, 11032($t0)
	sw $t2, 11036($t0)
	sw $t2, 11040($t0)
	sw $t2, 11044($t0)
	sw $t2, 11048($t0)
	sw $t2, 11052($t0)
	sw $t2, 11056($t0)
	sw $t2, 11060($t0)
	sw $t2, 11064($t0)
	sw $t2, 11068($t0)
	sw $t6, 11120($t0)
	sw $t6, 11124($t0)
	sw $t6, 11128($t0)
	sw $t2, 11200($t0)
	sw $t2, 11204($t0)
	sw $t2, 11208($t0)
	sw $t2, 11212($t0)
	sw $t2, 11216($t0)
	sw $t2, 11220($t0)
	sw $t2, 11224($t0)
	sw $t2, 11228($t0)
	sw $t2, 11232($t0)
	sw $t2, 11236($t0)
	sw $t2, 11240($t0)
	sw $t2, 11244($t0)
	sw $t2, 11284($t0)
	sw $t2, 11324($t0)
	sw $t2, 11328($t0)
	sw $t4, 11360($t0)
	sw $t4, 11364($t0)
	sw $t4, 11368($t0)
	sw $t4, 11372($t0)
	sw $t4, 11376($t0)
	sw $t4, 11380($t0)
	sw $t4, 11384($t0)
	sw $t4, 11388($t0)
	sw $t2, 11452($t0)
	sw $t2, 11456($t0)
	sw $t2, 11496($t0)
	sw $t2, 11536($t0)
	sw $t2, 11540($t0)
	sw $t4, 11556($t0)
	sw $t4, 11564($t0)
	sw $t2, 11580($t0)
	sw $t2, 11712($t0)
	sw $t4, 11728($t0)
	sw $t4, 11736($t0)
	sw $t2, 11752($t0)
	sw $t2, 11756($t0)
	sw $t2, 11796($t0)
	sw $t4, 11808($t0)
	sw $t5, 11812($t0)
	sw $t4, 11816($t0)
	sw $t5, 11820($t0)
	sw $t4, 11824($t0)
	sw $t2, 11836($t0)
	sw $t2, 11840($t0)
	sw $t2, 11964($t0)
	sw $t2, 11968($t0)
	sw $t4, 11980($t0)
	sw $t5, 11984($t0)
	sw $t4, 11988($t0)
	sw $t5, 11992($t0)
	sw $t4, 11996($t0)
	sw $t2, 12008($t0)
	sw $t2, 12048($t0)
	sw $t2, 12052($t0)
	sw $t4, 12060($t0)
	sw $t5, 12064($t0)
	sw $t5, 12068($t0)
	sw $t5, 12072($t0)
	sw $t5, 12076($t0)
	sw $t5, 12080($t0)
	sw $t4, 12084($t0)
	sw $t2, 12092($t0)
	sw $t2, 12224($t0)
	sw $t4, 12232($t0)
	sw $t5, 12236($t0)
	sw $t5, 12240($t0)
	sw $t5, 12244($t0)
	sw $t5, 12248($t0)
	sw $t5, 12252($t0)
	sw $t4, 12256($t0)
	sw $t2, 12264($t0)
	sw $t2, 12268($t0)
	sw $t2, 12308($t0)
	sw $t4, 12320($t0)
	sw $t5, 12324($t0)
	sw $t5, 12328($t0)
	sw $t5, 12332($t0)
	sw $t4, 12336($t0)
	sw $t2, 12348($t0)
	sw $t2, 12352($t0)
	sw $t2, 12476($t0)
	sw $t2, 12480($t0)
	sw $t4, 12492($t0)
	sw $t5, 12496($t0)
	sw $t5, 12500($t0)
	sw $t5, 12504($t0)
	sw $t4, 12508($t0)
	sw $t2, 12520($t0)
	sw $t2, 12560($t0)
	sw $t2, 12564($t0)
	sw $t4, 12580($t0)
	sw $t5, 12584($t0)
	sw $t4, 12588($t0)
	sw $t2, 12604($t0)
	sw $t2, 12736($t0)
	sw $t4, 12752($t0)
	sw $t5, 12756($t0)
	sw $t4, 12760($t0)
	sw $t2, 12776($t0)
	sw $t2, 12780($t0)
	sw $t2, 12820($t0)
	sw $t4, 12840($t0)
	sw $t2, 12860($t0)
	sw $t2, 12864($t0)
	sw $t2, 12988($t0)
	sw $t2, 12992($t0)
	sw $t4, 13012($t0)
	sw $t2, 13032($t0)
	sw $t2, 13072($t0)
	sw $t2, 13076($t0)
	sw $t2, 13116($t0)
	sw $t2, 13248($t0)
	sw $t2, 13288($t0)
	sw $t2, 13292($t0)
	sw $t2, 13332($t0)
	sw $t2, 13336($t0)
	sw $t2, 13340($t0)
	sw $t2, 13344($t0)
	sw $t2, 13348($t0)
	sw $t2, 13352($t0)
	sw $t2, 13356($t0)
	sw $t2, 13360($t0)
	sw $t2, 13364($t0)
	sw $t2, 13368($t0)
	sw $t2, 13372($t0)
	sw $t2, 13376($t0)
	sw $t4, 13436($t0)
	sw $t4, 13440($t0)
	sw $t4, 13444($t0)
	sw $t4, 13448($t0)
	sw $t4, 13452($t0)
	sw $t4, 13456($t0)
	sw $t4, 13460($t0)
	sw $t4, 13464($t0)
	sw $t2, 13500($t0)
	sw $t2, 13504($t0)
	sw $t2, 13508($t0)
	sw $t2, 13512($t0)
	sw $t2, 13516($t0)
	sw $t2, 13520($t0)
	sw $t2, 13524($t0)
	sw $t2, 13528($t0)
	sw $t2, 13532($t0)
	sw $t2, 13536($t0)
	sw $t2, 13540($t0)
	sw $t2, 13544($t0)
	sw $t2, 13584($t0)
	sw $t2, 13588($t0)
	sw $t2, 13596($t0)
	sw $t2, 13604($t0)
	sw $t2, 13612($t0)
	sw $t2, 13620($t0)
	sw $t2, 13628($t0)
	sw $t2, 13760($t0)
	sw $t2, 13768($t0)
	sw $t2, 13776($t0)
	sw $t2, 13784($t0)
	sw $t2, 13792($t0)
	sw $t2, 13800($t0)
	sw $t2, 13804($t0)
	sw $t5, 14156($t0)
	sw $t5, 14408($t0)
	sw $t5, 14416($t0)
	sw $t5, 14668($t0)
	sw $t5, 14920($t0)
	sw $t5, 14924($t0)
	sw $t5, 14928($t0)
	sw $t4, 15168($t0)
	sw $t4, 15172($t0)
	sw $t4, 15176($t0)
	sw $t4, 15180($t0)
	sw $t4, 15184($t0)
	sw $t4, 15188($t0)
	sw $t4, 15192($t0)
	sw $t7, 15872($t0)
	sw $t7, 15876($t0)
	sw $t7, 15880($t0)
	sw $t7, 15884($t0)
	sw $t7, 15888($t0)
	sw $t7, 15892($t0)
	sw $t7, 15896($t0)
	sw $t7, 15900($t0)
	sw $t7, 15904($t0)
	sw $t7, 15908($t0)
	sw $t7, 15912($t0)
	sw $t7, 15916($t0)
	sw $t7, 15920($t0)
	sw $t7, 15924($t0)
	sw $t7, 15928($t0)
	sw $t7, 15932($t0)
	sw $t7, 15936($t0)
	sw $t7, 15940($t0)
	sw $t7, 15944($t0)
	sw $t7, 15948($t0)
	sw $t7, 15952($t0)
	sw $t7, 15956($t0)
	sw $t7, 15960($t0)
	sw $t7, 15964($t0)
	sw $t7, 15968($t0)
	sw $t7, 15972($t0)
	sw $t7, 15976($t0)
	sw $t7, 15980($t0)
	sw $t7, 15984($t0)
	sw $t7, 15988($t0)
	sw $t7, 15992($t0)
	sw $t7, 15996($t0)
	sw $t7, 16000($t0)
	sw $t7, 16004($t0)
	sw $t7, 16008($t0)
	sw $t7, 16012($t0)
	sw $t7, 16016($t0)
	sw $t7, 16020($t0)
	sw $t7, 16024($t0)
	sw $t7, 16028($t0)
	sw $t7, 16032($t0)
	sw $t7, 16036($t0)
	sw $t7, 16040($t0)
	sw $t7, 16044($t0)
	sw $t7, 16048($t0)
	sw $t7, 16052($t0)
	sw $t7, 16056($t0)
	sw $t7, 16060($t0)
	sw $t7, 16064($t0)
	sw $t7, 16068($t0)
	sw $t7, 16072($t0)
	sw $t7, 16076($t0)
	sw $t7, 16080($t0)
	sw $t7, 16084($t0)
	sw $t7, 16088($t0)
	sw $t7, 16092($t0)
	sw $t7, 16096($t0)
	sw $t7, 16100($t0)
	sw $t7, 16104($t0)
	sw $t7, 16108($t0)
	sw $t7, 16112($t0)
	sw $t7, 16116($t0)
	sw $t7, 16120($t0)
	sw $t7, 16124($t0)
	sw $t7, 16128($t0)
	sw $t7, 16132($t0)
	sw $t7, 16136($t0)
	sw $t7, 16140($t0)
	sw $t7, 16144($t0)
	sw $t7, 16148($t0)
	sw $t7, 16152($t0)
	sw $t7, 16156($t0)
	sw $t7, 16160($t0)
	sw $t7, 16164($t0)
	sw $t7, 16168($t0)
	sw $t7, 16172($t0)
	sw $t7, 16176($t0)
	sw $t7, 16180($t0)
	sw $t7, 16184($t0)
	sw $t7, 16188($t0)
	sw $t7, 16192($t0)
	sw $t7, 16196($t0)
	sw $t7, 16200($t0)
	sw $t7, 16204($t0)
	sw $t7, 16208($t0)
	sw $t7, 16212($t0)
	sw $t7, 16216($t0)
	sw $t7, 16220($t0)
	sw $t7, 16224($t0)
	sw $t7, 16228($t0)
	sw $t7, 16232($t0)
	sw $t7, 16236($t0)
	sw $t7, 16240($t0)
	sw $t7, 16244($t0)
	sw $t7, 16248($t0)
	sw $t7, 16252($t0)
	sw $t7, 16256($t0)
	sw $t7, 16260($t0)
	sw $t7, 16264($t0)
	sw $t7, 16268($t0)
	sw $t7, 16272($t0)
	sw $t7, 16276($t0)
	sw $t7, 16280($t0)
	sw $t7, 16284($t0)
	sw $t7, 16288($t0)
	sw $t7, 16292($t0)
	sw $t7, 16296($t0)
	sw $t7, 16300($t0)
	sw $t7, 16304($t0)
	sw $t7, 16308($t0)
	sw $t7, 16312($t0)
	sw $t7, 16316($t0)
	sw $t7, 16320($t0)
	sw $t7, 16324($t0)
	sw $t7, 16328($t0)
	sw $t7, 16332($t0)
	sw $t7, 16336($t0)
	sw $t7, 16340($t0)
	sw $t7, 16344($t0)
	sw $t7, 16348($t0)
	sw $t7, 16352($t0)
	sw $t7, 16356($t0)
	sw $t7, 16360($t0)
	sw $t7, 16364($t0)
	sw $t7, 16368($t0)
	sw $t7, 16372($t0)
	sw $t7, 16376($t0)
	sw $t7, 16380($t0)
	jr $ra

initialize_screen:
	la $t0, base_address
	li $t1, BLUE
	li $t2, GREEN
	li $t3, WHITE
	li $t4, GOLDEN
	li $t5, ORANGE
	li $t6, GREY
	li $t7, RED
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	sw $t1, 84($t0)
	sw $t1, 88($t0)
	sw $t1, 92($t0)
	sw $t1, 96($t0)
	sw $t1, 100($t0)
	sw $t1, 104($t0)
	sw $t1, 108($t0)
	sw $t1, 112($t0)
	sw $t1, 116($t0)
	sw $t1, 120($t0)
	sw $t1, 124($t0)
	sw $t1, 128($t0)
	sw $t1, 132($t0)
	sw $t1, 136($t0)
	sw $t1, 140($t0)
	sw $t1, 144($t0)
	sw $t1, 148($t0)
	sw $t1, 152($t0)
	sw $t1, 156($t0)
	sw $t1, 160($t0)
	sw $t1, 164($t0)
	sw $t1, 168($t0)
	sw $t1, 172($t0)
	sw $t1, 176($t0)
	sw $t1, 180($t0)
	sw $t1, 184($t0)
	sw $t1, 188($t0)
	sw $t1, 192($t0)
	sw $t1, 196($t0)
	sw $t1, 200($t0)
	sw $t1, 204($t0)
	sw $t1, 208($t0)
	sw $t1, 212($t0)
	sw $t1, 216($t0)
	sw $t1, 220($t0)
	sw $t1, 224($t0)
	sw $t1, 228($t0)
	sw $t1, 232($t0)
	sw $t1, 236($t0)
	sw $t1, 240($t0)
	sw $t1, 244($t0)
	sw $t1, 248($t0)
	sw $t1, 252($t0)
	sw $t1, 256($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 268($t0)
	sw $t1, 272($t0)
	sw $t1, 276($t0)
	sw $t1, 280($t0)
	sw $t1, 284($t0)
	sw $t1, 288($t0)
	sw $t1, 292($t0)
	sw $t1, 296($t0)
	sw $t1, 300($t0)
	sw $t1, 304($t0)
	sw $t1, 308($t0)
	sw $t1, 312($t0)
	sw $t1, 316($t0)
	sw $t1, 320($t0)
	sw $t1, 324($t0)
	sw $t1, 328($t0)
	sw $t1, 332($t0)
	sw $t1, 336($t0)
	sw $t1, 340($t0)
	sw $t1, 344($t0)
	sw $t1, 348($t0)
	sw $t1, 352($t0)
	sw $t1, 356($t0)
	sw $t1, 360($t0)
	sw $t1, 364($t0)
	sw $t1, 368($t0)
	sw $t1, 372($t0)
	sw $t1, 376($t0)
	sw $t1, 380($t0)
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 392($t0)
	sw $t1, 396($t0)
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
	sw $t1, 440($t0)
	sw $t1, 444($t0)
	sw $t1, 448($t0)
	sw $t1, 452($t0)
	sw $t1, 456($t0)
	sw $t1, 460($t0)
	sw $t1, 464($t0)
	sw $t1, 468($t0)
	sw $t1, 472($t0)
	sw $t1, 476($t0)
	sw $t1, 480($t0)
	sw $t1, 484($t0)
	sw $t1, 488($t0)
	sw $t1, 492($t0)
	sw $t1, 496($t0)
	sw $t1, 500($t0)
	sw $t1, 504($t0)
	sw $t1, 508($t0)
	sw $t2, 512($t0)
	sw $t2, 516($t0)
	sw $t2, 520($t0)
	sw $t2, 524($t0)
	sw $t2, 528($t0)
	sw $t2, 532($t0)
	sw $t2, 536($t0)
	sw $t2, 540($t0)
	sw $t2, 544($t0)
	sw $t2, 548($t0)
	sw $t2, 552($t0)
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
	sw $t2, 808($t0)
	sw $t2, 812($t0)
	sw $t2, 976($t0)
	sw $t2, 980($t0)
	sw $t2, 1020($t0)
	sw $t2, 1024($t0)
	sw $t3, 1040($t0)
	sw $t3, 1048($t0)
	sw $t2, 1064($t0)
	sw $t2, 1068($t0)
	sw $t2, 1072($t0)
	sw $t4, 1144($t0)
	sw $t4, 1152($t0)
	sw $t4, 1160($t0)
	sw $t2, 1228($t0)
	sw $t2, 1232($t0)
	sw $t2, 1236($t0)
	sw $t3, 1252($t0)
	sw $t3, 1260($t0)
	sw $t2, 1276($t0)
	sw $t2, 1280($t0)
	sw $t3, 1292($t0)
	sw $t5, 1296($t0)
	sw $t3, 1300($t0)
	sw $t5, 1304($t0)
	sw $t3, 1308($t0)
	sw $t2, 1320($t0)
	sw $t2, 1324($t0)
	sw $t4, 1400($t0)
	sw $t4, 1404($t0)
	sw $t4, 1408($t0)
	sw $t4, 1412($t0)
	sw $t4, 1416($t0)
	sw $t2, 1488($t0)
	sw $t2, 1492($t0)
	sw $t3, 1504($t0)
	sw $t5, 1508($t0)
	sw $t3, 1512($t0)
	sw $t5, 1516($t0)
	sw $t3, 1520($t0)
	sw $t2, 1532($t0)
	sw $t2, 1536($t0)
	sw $t3, 1544($t0)
	sw $t5, 1548($t0)
	sw $t5, 1552($t0)
	sw $t5, 1556($t0)
	sw $t5, 1560($t0)
	sw $t5, 1564($t0)
	sw $t3, 1568($t0)
	sw $t2, 1576($t0)
	sw $t4, 1660($t0)
	sw $t4, 1668($t0)
	sw $t2, 1748($t0)
	sw $t3, 1756($t0)
	sw $t5, 1760($t0)
	sw $t5, 1764($t0)
	sw $t5, 1768($t0)
	sw $t5, 1772($t0)
	sw $t5, 1776($t0)
	sw $t3, 1780($t0)
	sw $t2, 1788($t0)
	sw $t2, 1792($t0)
	sw $t3, 1804($t0)
	sw $t5, 1808($t0)
	sw $t5, 1812($t0)
	sw $t5, 1816($t0)
	sw $t3, 1820($t0)
	sw $t2, 1832($t0)
	sw $t2, 1836($t0)
	sw $t3, 1908($t0)
	sw $t3, 1912($t0)
	sw $t3, 1916($t0)
	sw $t3, 1920($t0)
	sw $t3, 1924($t0)
	sw $t3, 1928($t0)
	sw $t3, 1932($t0)
	sw $t2, 2000($t0)
	sw $t2, 2004($t0)
	sw $t3, 2016($t0)
	sw $t5, 2020($t0)
	sw $t5, 2024($t0)
	sw $t5, 2028($t0)
	sw $t3, 2032($t0)
	sw $t2, 2044($t0)
	sw $t2, 2048($t0)
	sw $t3, 2064($t0)
	sw $t5, 2068($t0)
	sw $t3, 2072($t0)
	sw $t2, 2088($t0)
	sw $t2, 2092($t0)
	sw $t2, 2096($t0)
	sw $t3, 2160($t0)
	sw $t3, 2164($t0)
	sw $t3, 2188($t0)
	sw $t3, 2192($t0)
	sw $t2, 2252($t0)
	sw $t2, 2256($t0)
	sw $t2, 2260($t0)
	sw $t3, 2276($t0)
	sw $t5, 2280($t0)
	sw $t3, 2284($t0)
	sw $t2, 2300($t0)
	sw $t2, 2304($t0)
	sw $t3, 2324($t0)
	sw $t2, 2344($t0)
	sw $t2, 2348($t0)
	sw $t2, 2512($t0)
	sw $t2, 2516($t0)
	sw $t3, 2536($t0)
	sw $t2, 2556($t0)
	sw $t2, 2560($t0)
	sw $t2, 2600($t0)
	sw $t2, 2772($t0)
	sw $t2, 2812($t0)
	sw $t2, 2816($t0)
	sw $t2, 2820($t0)
	sw $t2, 2824($t0)
	sw $t2, 2828($t0)
	sw $t2, 2832($t0)
	sw $t2, 2836($t0)
	sw $t2, 2840($t0)
	sw $t2, 2844($t0)
	sw $t2, 2848($t0)
	sw $t2, 2852($t0)
	sw $t2, 2856($t0)
	sw $t2, 2860($t0)
	sw $t2, 3024($t0)
	sw $t2, 3028($t0)
	sw $t2, 3032($t0)
	sw $t2, 3036($t0)
	sw $t2, 3040($t0)
	sw $t2, 3044($t0)
	sw $t2, 3048($t0)
	sw $t2, 3052($t0)
	sw $t2, 3056($t0)
	sw $t2, 3060($t0)
	sw $t2, 3064($t0)
	sw $t2, 3068($t0)
	sw $t2, 3072($t0)
	sw $t2, 3076($t0)
	sw $t2, 3080($t0)
	sw $t2, 3084($t0)
	sw $t2, 3088($t0)
	sw $t2, 3092($t0)
	sw $t2, 3096($t0)
	sw $t2, 3100($t0)
	sw $t2, 3104($t0)
	sw $t2, 3108($t0)
	sw $t2, 3112($t0)
	sw $t2, 3116($t0)
	sw $t2, 3120($t0)
	sw $t2, 3276($t0)
	sw $t2, 3280($t0)
	sw $t2, 3284($t0)
	sw $t2, 3288($t0)
	sw $t2, 3292($t0)
	sw $t2, 3296($t0)
	sw $t2, 3300($t0)
	sw $t2, 3304($t0)
	sw $t2, 3308($t0)
	sw $t2, 3312($t0)
	sw $t2, 3316($t0)
	sw $t2, 3320($t0)
	sw $t2, 3324($t0)
	sw $t2, 3328($t0)
	sw $t2, 3332($t0)
	sw $t2, 3336($t0)
	sw $t2, 3340($t0)
	sw $t2, 3344($t0)
	sw $t2, 3348($t0)
	sw $t2, 3352($t0)
	sw $t2, 3356($t0)
	sw $t2, 3360($t0)
	sw $t2, 3364($t0)
	sw $t2, 3368($t0)
	sw $t2, 3372($t0)
	sw $t3, 3468($t0)
	sw $t3, 3472($t0)
	sw $t3, 3476($t0)
	sw $t3, 3480($t0)
	sw $t3, 3484($t0)
	sw $t3, 3488($t0)
	sw $t3, 3492($t0)
	sw $t3, 3496($t0)
	sw $t2, 3536($t0)
	sw $t2, 3540($t0)
	sw $t2, 3544($t0)
	sw $t2, 3548($t0)
	sw $t2, 3552($t0)
	sw $t2, 3556($t0)
	sw $t2, 3560($t0)
	sw $t2, 3564($t0)
	sw $t2, 3568($t0)
	sw $t2, 3572($t0)
	sw $t2, 3576($t0)
	sw $t2, 3580($t0)
	sw $t2, 3584($t0)
	sw $t2, 3624($t0)
	sw $t2, 3796($t0)
	sw $t2, 3836($t0)
	sw $t2, 3840($t0)
	sw $t3, 3856($t0)
	sw $t3, 3864($t0)
	sw $t2, 3880($t0)
	sw $t2, 3884($t0)
	sw $t2, 4048($t0)
	sw $t2, 4052($t0)
	sw $t3, 4068($t0)
	sw $t3, 4076($t0)
	sw $t2, 4092($t0)
	sw $t2, 4096($t0)
	sw $t3, 4108($t0)
	sw $t5, 4112($t0)
	sw $t3, 4116($t0)
	sw $t5, 4120($t0)
	sw $t3, 4124($t0)
	sw $t2, 4136($t0)
	sw $t2, 4140($t0)
	sw $t2, 4144($t0)
	sw $t2, 4300($t0)
	sw $t2, 4304($t0)
	sw $t2, 4308($t0)
	sw $t3, 4320($t0)
	sw $t5, 4324($t0)
	sw $t3, 4328($t0)
	sw $t5, 4332($t0)
	sw $t3, 4336($t0)
	sw $t2, 4348($t0)
	sw $t2, 4352($t0)
	sw $t3, 4360($t0)
	sw $t5, 4364($t0)
	sw $t5, 4368($t0)
	sw $t5, 4372($t0)
	sw $t5, 4376($t0)
	sw $t5, 4380($t0)
	sw $t3, 4384($t0)
	sw $t2, 4392($t0)
	sw $t2, 4396($t0)
	sw $t6, 4436($t0)
	sw $t2, 4560($t0)
	sw $t2, 4564($t0)
	sw $t3, 4572($t0)
	sw $t5, 4576($t0)
	sw $t5, 4580($t0)
	sw $t5, 4584($t0)
	sw $t5, 4588($t0)
	sw $t5, 4592($t0)
	sw $t3, 4596($t0)
	sw $t2, 4604($t0)
	sw $t2, 4608($t0)
	sw $t3, 4620($t0)
	sw $t5, 4624($t0)
	sw $t5, 4628($t0)
	sw $t5, 4632($t0)
	sw $t3, 4636($t0)
	sw $t2, 4648($t0)
	sw $t6, 4688($t0)
	sw $t6, 4692($t0)
	sw $t6, 4696($t0)
	sw $t2, 4820($t0)
	sw $t3, 4832($t0)
	sw $t5, 4836($t0)
	sw $t5, 4840($t0)
	sw $t5, 4844($t0)
	sw $t3, 4848($t0)
	sw $t2, 4860($t0)
	sw $t2, 4864($t0)
	sw $t3, 4880($t0)
	sw $t5, 4884($t0)
	sw $t3, 4888($t0)
	sw $t2, 4904($t0)
	sw $t2, 4908($t0)
	sw $t3, 4932($t0)
	sw $t3, 4936($t0)
	sw $t3, 4940($t0)
	sw $t3, 4944($t0)
	sw $t3, 4948($t0)
	sw $t3, 4952($t0)
	sw $t3, 4956($t0)
	sw $t3, 4960($t0)
	sw $t2, 5072($t0)
	sw $t2, 5076($t0)
	sw $t3, 5092($t0)
	sw $t5, 5096($t0)
	sw $t3, 5100($t0)
	sw $t2, 5116($t0)
	sw $t2, 5120($t0)
	sw $t3, 5140($t0)
	sw $t2, 5160($t0)
	sw $t2, 5164($t0)
	sw $t2, 5168($t0)
	sw $t2, 5324($t0)
	sw $t2, 5328($t0)
	sw $t2, 5332($t0)
	sw $t3, 5352($t0)
	sw $t2, 5372($t0)
	sw $t2, 5376($t0)
	sw $t2, 5416($t0)
	sw $t2, 5420($t0)
	sw $t2, 5584($t0)
	sw $t2, 5588($t0)
	sw $t2, 5628($t0)
	sw $t2, 5632($t0)
	sw $t2, 5636($t0)
	sw $t2, 5640($t0)
	sw $t2, 5644($t0)
	sw $t2, 5648($t0)
	sw $t2, 5652($t0)
	sw $t2, 5656($t0)
	sw $t2, 5660($t0)
	sw $t2, 5664($t0)
	sw $t2, 5668($t0)
	sw $t2, 5672($t0)
	sw $t2, 5844($t0)
	sw $t2, 5848($t0)
	sw $t2, 5852($t0)
	sw $t2, 5856($t0)
	sw $t2, 5860($t0)
	sw $t2, 5864($t0)
	sw $t2, 5868($t0)
	sw $t2, 5872($t0)
	sw $t2, 5876($t0)
	sw $t2, 5880($t0)
	sw $t2, 5884($t0)
	sw $t2, 5888($t0)
	sw $t2, 5892($t0)
	sw $t2, 5896($t0)
	sw $t2, 5900($t0)
	sw $t2, 5904($t0)
	sw $t2, 5908($t0)
	sw $t2, 5912($t0)
	sw $t2, 5916($t0)
	sw $t2, 5920($t0)
	sw $t2, 5924($t0)
	sw $t2, 5928($t0)
	sw $t2, 5932($t0)
	sw $t2, 6096($t0)
	sw $t2, 6100($t0)
	sw $t2, 6104($t0)
	sw $t2, 6108($t0)
	sw $t2, 6112($t0)
	sw $t2, 6116($t0)
	sw $t2, 6120($t0)
	sw $t2, 6124($t0)
	sw $t2, 6128($t0)
	sw $t2, 6132($t0)
	sw $t2, 6136($t0)
	sw $t2, 6140($t0)
	sw $t2, 6144($t0)
	sw $t2, 6148($t0)
	sw $t2, 6152($t0)
	sw $t2, 6156($t0)
	sw $t2, 6160($t0)
	sw $t2, 6164($t0)
	sw $t2, 6168($t0)
	sw $t2, 6172($t0)
	sw $t2, 6176($t0)
	sw $t2, 6180($t0)
	sw $t2, 6184($t0)
	sw $t2, 6188($t0)
	sw $t2, 6192($t0)
	sw $t2, 6348($t0)
	sw $t2, 6352($t0)
	sw $t2, 6356($t0)
	sw $t2, 6360($t0)
	sw $t2, 6364($t0)
	sw $t2, 6368($t0)
	sw $t2, 6372($t0)
	sw $t2, 6376($t0)
	sw $t2, 6380($t0)
	sw $t2, 6384($t0)
	sw $t2, 6388($t0)
	sw $t2, 6392($t0)
	sw $t2, 6396($t0)
	sw $t2, 6400($t0)
	sw $t2, 6440($t0)
	sw $t2, 6444($t0)
	sw $t3, 6500($t0)
	sw $t3, 6504($t0)
	sw $t3, 6508($t0)
	sw $t3, 6512($t0)
	sw $t3, 6516($t0)
	sw $t3, 6520($t0)
	sw $t3, 6524($t0)
	sw $t3, 6528($t0)
	sw $t2, 6608($t0)
	sw $t2, 6612($t0)
	sw $t2, 6652($t0)
	sw $t2, 6656($t0)
	sw $t3, 6672($t0)
	sw $t3, 6680($t0)
	sw $t2, 6696($t0)
	sw $t2, 6868($t0)
	sw $t3, 6884($t0)
	sw $t3, 6892($t0)
	sw $t2, 6908($t0)
	sw $t2, 6912($t0)
	sw $t3, 6924($t0)
	sw $t5, 6928($t0)
	sw $t3, 6932($t0)
	sw $t5, 6936($t0)
	sw $t3, 6940($t0)
	sw $t2, 6952($t0)
	sw $t2, 6956($t0)
	sw $t2, 7120($t0)
	sw $t2, 7124($t0)
	sw $t3, 7136($t0)
	sw $t5, 7140($t0)
	sw $t3, 7144($t0)
	sw $t5, 7148($t0)
	sw $t3, 7152($t0)
	sw $t2, 7164($t0)
	sw $t2, 7168($t0)
	sw $t3, 7176($t0)
	sw $t5, 7180($t0)
	sw $t5, 7184($t0)
	sw $t5, 7188($t0)
	sw $t5, 7192($t0)
	sw $t5, 7196($t0)
	sw $t3, 7200($t0)
	sw $t2, 7208($t0)
	sw $t2, 7212($t0)
	sw $t2, 7216($t0)
	sw $t2, 7372($t0)
	sw $t2, 7376($t0)
	sw $t2, 7380($t0)
	sw $t3, 7388($t0)
	sw $t5, 7392($t0)
	sw $t5, 7396($t0)
	sw $t5, 7400($t0)
	sw $t5, 7404($t0)
	sw $t5, 7408($t0)
	sw $t3, 7412($t0)
	sw $t2, 7420($t0)
	sw $t2, 7424($t0)
	sw $t3, 7436($t0)
	sw $t5, 7440($t0)
	sw $t5, 7444($t0)
	sw $t5, 7448($t0)
	sw $t3, 7452($t0)
	sw $t2, 7464($t0)
	sw $t2, 7468($t0)
	sw $t6, 7568($t0)
	sw $t2, 7632($t0)
	sw $t2, 7636($t0)
	sw $t3, 7648($t0)
	sw $t5, 7652($t0)
	sw $t5, 7656($t0)
	sw $t5, 7660($t0)
	sw $t3, 7664($t0)
	sw $t2, 7676($t0)
	sw $t2, 7680($t0)
	sw $t3, 7696($t0)
	sw $t5, 7700($t0)
	sw $t3, 7704($t0)
	sw $t2, 7720($t0)
	sw $t6, 7820($t0)
	sw $t6, 7824($t0)
	sw $t6, 7828($t0)
	sw $t2, 7892($t0)
	sw $t3, 7908($t0)
	sw $t5, 7912($t0)
	sw $t3, 7916($t0)
	sw $t2, 7932($t0)
	sw $t2, 7936($t0)
	sw $t3, 7956($t0)
	sw $t2, 7976($t0)
	sw $t2, 7980($t0)
	sw $t3, 8072($t0)
	sw $t3, 8076($t0)
	sw $t3, 8080($t0)
	sw $t3, 8084($t0)
	sw $t3, 8088($t0)
	sw $t3, 8092($t0)
	sw $t3, 8096($t0)
	sw $t3, 8100($t0)
	sw $t2, 8144($t0)
	sw $t2, 8148($t0)
	sw $t3, 8168($t0)
	sw $t2, 8188($t0)
	sw $t2, 8192($t0)
	sw $t2, 8232($t0)
	sw $t2, 8236($t0)
	sw $t2, 8240($t0)
	sw $t2, 8396($t0)
	sw $t2, 8400($t0)
	sw $t2, 8404($t0)
	sw $t2, 8444($t0)
	sw $t2, 8448($t0)
	sw $t2, 8452($t0)
	sw $t2, 8456($t0)
	sw $t2, 8460($t0)
	sw $t2, 8464($t0)
	sw $t2, 8468($t0)
	sw $t2, 8472($t0)
	sw $t2, 8476($t0)
	sw $t2, 8480($t0)
	sw $t2, 8484($t0)
	sw $t2, 8488($t0)
	sw $t2, 8492($t0)
	sw $t2, 8656($t0)
	sw $t2, 8660($t0)
	sw $t2, 8664($t0)
	sw $t2, 8668($t0)
	sw $t2, 8672($t0)
	sw $t2, 8676($t0)
	sw $t2, 8680($t0)
	sw $t2, 8684($t0)
	sw $t2, 8688($t0)
	sw $t2, 8692($t0)
	sw $t2, 8696($t0)
	sw $t2, 8700($t0)
	sw $t2, 8704($t0)
	sw $t2, 8708($t0)
	sw $t2, 8712($t0)
	sw $t2, 8716($t0)
	sw $t2, 8720($t0)
	sw $t2, 8724($t0)
	sw $t2, 8728($t0)
	sw $t2, 8732($t0)
	sw $t2, 8736($t0)
	sw $t2, 8740($t0)
	sw $t2, 8744($t0)
	sw $t2, 8916($t0)
	sw $t2, 8920($t0)
	sw $t2, 8924($t0)
	sw $t2, 8928($t0)
	sw $t2, 8932($t0)
	sw $t2, 8936($t0)
	sw $t2, 8940($t0)
	sw $t2, 8944($t0)
	sw $t2, 8948($t0)
	sw $t2, 8952($t0)
	sw $t2, 8956($t0)
	sw $t2, 8960($t0)
	sw $t2, 8964($t0)
	sw $t2, 8968($t0)
	sw $t2, 8972($t0)
	sw $t2, 8976($t0)
	sw $t2, 8980($t0)
	sw $t2, 8984($t0)
	sw $t2, 8988($t0)
	sw $t2, 8992($t0)
	sw $t2, 9180($t0)
	sw $t2, 9184($t0)
	sw $t2, 9188($t0)
	sw $t2, 9192($t0)
	sw $t2, 9196($t0)
	sw $t2, 9200($t0)
	sw $t2, 9204($t0)
	sw $t2, 9208($t0)
	sw $t2, 9212($t0)
	sw $t2, 9216($t0)
	sw $t2, 9220($t0)
	sw $t2, 9224($t0)
	sw $t2, 9228($t0)
	sw $t2, 9232($t0)
	sw $t2, 9236($t0)
	sw $t2, 9240($t0)
	sw $t2, 9244($t0)
	sw $t2, 9440($t0)
	sw $t2, 9444($t0)
	sw $t2, 9448($t0)
	sw $t2, 9452($t0)
	sw $t2, 9456($t0)
	sw $t2, 9460($t0)
	sw $t2, 9464($t0)
	sw $t2, 9468($t0)
	sw $t2, 9472($t0)
	sw $t2, 9476($t0)
	sw $t2, 9480($t0)
	sw $t2, 9484($t0)
	sw $t2, 9488($t0)
	sw $t2, 9492($t0)
	sw $t2, 9496($t0)
	sw $t2, 9700($t0)
	sw $t2, 9704($t0)
	sw $t2, 9708($t0)
	sw $t2, 9712($t0)
	sw $t2, 9716($t0)
	sw $t2, 9720($t0)
	sw $t2, 9724($t0)
	sw $t2, 9728($t0)
	sw $t2, 9732($t0)
	sw $t2, 9736($t0)
	sw $t2, 9740($t0)
	sw $t2, 9744($t0)
	sw $t2, 9748($t0)
	sw $t2, 9960($t0)
	sw $t2, 9964($t0)
	sw $t2, 9968($t0)
	sw $t2, 9972($t0)
	sw $t2, 9976($t0)
	sw $t2, 9980($t0)
	sw $t2, 9984($t0)
	sw $t2, 9988($t0)
	sw $t2, 9992($t0)
	sw $t2, 9996($t0)
	sw $t2, 10000($t0)
	sw $t3, 10108($t0)
	sw $t3, 10112($t0)
	sw $t3, 10116($t0)
	sw $t3, 10120($t0)
	sw $t3, 10124($t0)
	sw $t3, 10128($t0)
	sw $t3, 10132($t0)
	sw $t3, 10136($t0)
	sw $t2, 10220($t0)
	sw $t2, 10224($t0)
	sw $t2, 10228($t0)
	sw $t2, 10232($t0)
	sw $t2, 10236($t0)
	sw $t2, 10240($t0)
	sw $t2, 10244($t0)
	sw $t2, 10248($t0)
	sw $t2, 10252($t0)
	sw $t2, 10480($t0)
	sw $t2, 10484($t0)
	sw $t2, 10488($t0)
	sw $t2, 10492($t0)
	sw $t2, 10496($t0)
	sw $t2, 10500($t0)
	sw $t2, 10504($t0)
	sw $t2, 10740($t0)
	sw $t2, 10744($t0)
	sw $t2, 10748($t0)
	sw $t2, 10752($t0)
	sw $t2, 10756($t0)
	sw $t2, 11000($t0)
	sw $t2, 11004($t0)
	sw $t2, 11008($t0)
	sw $t2, 11012($t0)
	sw $t2, 11016($t0)
	sw $t2, 11252($t0)
	sw $t2, 11256($t0)
	sw $t2, 11260($t0)
	sw $t2, 11264($t0)
	sw $t2, 11268($t0)
	sw $t3, 11448($t0)
	sw $t3, 11452($t0)
	sw $t3, 11456($t0)
	sw $t3, 11460($t0)
	sw $t3, 11464($t0)
	sw $t3, 11468($t0)
	sw $t3, 11472($t0)
	sw $t3, 11476($t0)
	sw $t3, 11480($t0)
	sw $t3, 11484($t0)
	sw $t2, 11512($t0)
	sw $t2, 11516($t0)
	sw $t2, 11520($t0)
	sw $t2, 11524($t0)
	sw $t2, 11528($t0)
	sw $t2, 11764($t0)
	sw $t2, 11768($t0)
	sw $t2, 11772($t0)
	sw $t2, 11776($t0)
	sw $t2, 11780($t0)
	sw $t2, 12024($t0)
	sw $t2, 12028($t0)
	sw $t2, 12032($t0)
	sw $t2, 12036($t0)
	sw $t2, 12040($t0)
	sw $t2, 12276($t0)
	sw $t2, 12280($t0)
	sw $t2, 12284($t0)
	sw $t2, 12288($t0)
	sw $t2, 12292($t0)
	sw $t2, 12536($t0)
	sw $t2, 12540($t0)
	sw $t2, 12544($t0)
	sw $t2, 12548($t0)
	sw $t2, 12552($t0)
	sw $t3, 12676($t0)
	sw $t3, 12680($t0)
	sw $t3, 12684($t0)
	sw $t3, 12688($t0)
	sw $t3, 12692($t0)
	sw $t3, 12696($t0)
	sw $t3, 12700($t0)
	sw $t3, 12704($t0)
	sw $t3, 12708($t0)
	sw $t3, 12712($t0)
	sw $t2, 12788($t0)
	sw $t2, 12792($t0)
	sw $t2, 12796($t0)
	sw $t2, 12800($t0)
	sw $t2, 12804($t0)
	sw $t2, 13048($t0)
	sw $t2, 13052($t0)
	sw $t2, 13056($t0)
	sw $t2, 13060($t0)
	sw $t2, 13064($t0)
	sw $t2, 13300($t0)
	sw $t2, 13304($t0)
	sw $t2, 13308($t0)
	sw $t2, 13312($t0)
	sw $t2, 13316($t0)
	sw $t2, 13560($t0)
	sw $t2, 13564($t0)
	sw $t2, 13568($t0)
	sw $t2, 13572($t0)
	sw $t2, 13576($t0)
	sw $t2, 13812($t0)
	sw $t2, 13816($t0)
	sw $t2, 13820($t0)
	sw $t2, 13824($t0)
	sw $t2, 13828($t0)
	sw $t5, 13864($t0)
	sw $t3, 13904($t0)
	sw $t3, 13908($t0)
	sw $t3, 13912($t0)
	sw $t3, 13916($t0)
	sw $t3, 13920($t0)
	sw $t3, 13924($t0)
	sw $t3, 13928($t0)
	sw $t3, 13932($t0)
	sw $t3, 13936($t0)
	sw $t3, 13940($t0)
	sw $t2, 14072($t0)
	sw $t2, 14076($t0)
	sw $t2, 14080($t0)
	sw $t2, 14084($t0)
	sw $t2, 14088($t0)
	sw $t5, 14116($t0)
	sw $t5, 14124($t0)
	sw $t2, 14324($t0)
	sw $t2, 14328($t0)
	sw $t2, 14332($t0)
	sw $t2, 14336($t0)
	sw $t2, 14340($t0)
	sw $t5, 14376($t0)
	sw $t2, 14584($t0)
	sw $t2, 14588($t0)
	sw $t2, 14592($t0)
	sw $t2, 14596($t0)
	sw $t2, 14600($t0)
	sw $t5, 14628($t0)
	sw $t5, 14632($t0)
	sw $t5, 14636($t0)
	sw $t2, 14836($t0)
	sw $t2, 14840($t0)
	sw $t2, 14844($t0)
	sw $t2, 14848($t0)
	sw $t2, 14852($t0)
	sw $t2, 15096($t0)
	sw $t2, 15100($t0)
	sw $t2, 15104($t0)
	sw $t2, 15108($t0)
	sw $t2, 15112($t0)
	sw $t3, 15132($t0)
	sw $t3, 15136($t0)
	sw $t3, 15140($t0)
	sw $t3, 15144($t0)
	sw $t3, 15148($t0)
	sw $t3, 15152($t0)
	sw $t3, 15156($t0)
	sw $t3, 15160($t0)
	sw $t3, 15164($t0)
	sw $t3, 15168($t0)
	sw $t2, 15348($t0)
	sw $t2, 15352($t0)
	sw $t2, 15356($t0)
	sw $t2, 15360($t0)
	sw $t2, 15364($t0)
	sw $t2, 15608($t0)
	sw $t2, 15612($t0)
	sw $t2, 15616($t0)
	sw $t2, 15620($t0)
	sw $t2, 15624($t0)
	sw $t2, 15860($t0)
	sw $t2, 15864($t0)
	sw $t2, 15868($t0)
	sw $t7, 15872($t0)
	sw $t7, 15876($t0)
	sw $t7, 15880($t0)
	sw $t7, 15884($t0)
	sw $t7, 15888($t0)
	sw $t7, 15892($t0)
	sw $t7, 15896($t0)
	sw $t7, 15900($t0)
	sw $t7, 15904($t0)
	sw $t7, 15908($t0)
	sw $t7, 15912($t0)
	sw $t7, 15916($t0)
	sw $t7, 15920($t0)
	sw $t7, 15924($t0)
	sw $t7, 15928($t0)
	sw $t7, 15932($t0)
	sw $t7, 15936($t0)
	sw $t7, 15940($t0)
	sw $t7, 15944($t0)
	sw $t7, 15948($t0)
	sw $t7, 15952($t0)
	sw $t7, 15956($t0)
	sw $t7, 15960($t0)
	sw $t7, 15964($t0)
	sw $t7, 15968($t0)
	sw $t7, 15972($t0)
	sw $t7, 15976($t0)
	sw $t7, 15980($t0)
	sw $t7, 15984($t0)
	sw $t7, 15988($t0)
	sw $t7, 15992($t0)
	sw $t7, 15996($t0)
	sw $t7, 16000($t0)
	sw $t7, 16004($t0)
	sw $t7, 16008($t0)
	sw $t7, 16012($t0)
	sw $t7, 16016($t0)
	sw $t7, 16020($t0)
	sw $t7, 16024($t0)
	sw $t7, 16028($t0)
	sw $t7, 16032($t0)
	sw $t7, 16036($t0)
	sw $t7, 16040($t0)
	sw $t7, 16044($t0)
	sw $t7, 16048($t0)
	sw $t7, 16052($t0)
	sw $t7, 16056($t0)
	sw $t7, 16060($t0)
	sw $t7, 16064($t0)
	sw $t7, 16068($t0)
	sw $t7, 16072($t0)
	sw $t7, 16076($t0)
	sw $t7, 16080($t0)
	sw $t7, 16084($t0)
	sw $t7, 16088($t0)
	sw $t7, 16092($t0)
	sw $t7, 16096($t0)
	sw $t7, 16100($t0)
	sw $t7, 16104($t0)
	sw $t7, 16108($t0)
	sw $t7, 16112($t0)
	sw $t7, 16116($t0)
	sw $t7, 16120($t0)
	sw $t7, 16124($t0)
	sw $t7, 16128($t0)
	sw $t7, 16132($t0)
	sw $t7, 16136($t0)
	sw $t7, 16140($t0)
	sw $t7, 16144($t0)
	sw $t7, 16148($t0)
	sw $t7, 16152($t0)
	sw $t7, 16156($t0)
	sw $t7, 16160($t0)
	sw $t7, 16164($t0)
	sw $t7, 16168($t0)
	sw $t7, 16172($t0)
	sw $t7, 16176($t0)
	sw $t7, 16180($t0)
	sw $t7, 16184($t0)
	sw $t7, 16188($t0)
	sw $t7, 16192($t0)
	sw $t7, 16196($t0)
	sw $t7, 16200($t0)
	sw $t7, 16204($t0)
	sw $t7, 16208($t0)
	sw $t7, 16212($t0)
	sw $t7, 16216($t0)
	sw $t7, 16220($t0)
	sw $t7, 16224($t0)
	sw $t7, 16228($t0)
	sw $t7, 16232($t0)
	sw $t7, 16236($t0)
	sw $t7, 16240($t0)
	sw $t7, 16244($t0)
	sw $t7, 16248($t0)
	sw $t7, 16252($t0)
	sw $t7, 16256($t0)
	sw $t7, 16260($t0)
	sw $t7, 16264($t0)
	sw $t7, 16268($t0)
	sw $t7, 16272($t0)
	sw $t7, 16276($t0)
	sw $t7, 16280($t0)
	sw $t7, 16284($t0)
	sw $t7, 16288($t0)
	sw $t7, 16292($t0)
	sw $t7, 16296($t0)
	sw $t7, 16300($t0)
	sw $t7, 16304($t0)
	sw $t7, 16308($t0)
	sw $t7, 16312($t0)
	sw $t7, 16316($t0)
	sw $t7, 16320($t0)
	sw $t7, 16324($t0)
	sw $t7, 16328($t0)
	sw $t7, 16332($t0)
	sw $t7, 16336($t0)
	sw $t7, 16340($t0)
	sw $t7, 16344($t0)
	sw $t7, 16348($t0)
	sw $t7, 16352($t0)
	sw $t7, 16356($t0)
	sw $t7, 16360($t0)
	sw $t7, 16364($t0)
	sw $t7, 16368($t0)
	sw $t7, 16372($t0)
	sw $t7, 16376($t0)
	sw $t7, 16380($t0)
	jr $ra

draw_win:
	la $t0, base_address
	li $t1, BLUE
	li $t2, ORANGE
	li $t3, GOLDEN
	li $t4, RED
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	sw $t1, 84($t0)
	sw $t1, 88($t0)
	sw $t1, 92($t0)
	sw $t1, 96($t0)
	sw $t1, 100($t0)
	sw $t1, 104($t0)
	sw $t1, 108($t0)
	sw $t1, 112($t0)
	sw $t1, 116($t0)
	sw $t1, 120($t0)
	sw $t1, 124($t0)
	sw $t1, 128($t0)
	sw $t1, 132($t0)
	sw $t1, 136($t0)
	sw $t1, 140($t0)
	sw $t1, 144($t0)
	sw $t1, 148($t0)
	sw $t1, 152($t0)
	sw $t1, 156($t0)
	sw $t1, 160($t0)
	sw $t1, 164($t0)
	sw $t1, 168($t0)
	sw $t1, 172($t0)
	sw $t1, 176($t0)
	sw $t1, 180($t0)
	sw $t1, 184($t0)
	sw $t1, 188($t0)
	sw $t1, 192($t0)
	sw $t1, 196($t0)
	sw $t1, 200($t0)
	sw $t1, 204($t0)
	sw $t1, 208($t0)
	sw $t1, 212($t0)
	sw $t1, 216($t0)
	sw $t1, 220($t0)
	sw $t1, 224($t0)
	sw $t1, 228($t0)
	sw $t1, 232($t0)
	sw $t1, 236($t0)
	sw $t1, 240($t0)
	sw $t1, 244($t0)
	sw $t1, 248($t0)
	sw $t1, 252($t0)
	sw $t1, 256($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 268($t0)
	sw $t1, 272($t0)
	sw $t1, 276($t0)
	sw $t1, 280($t0)
	sw $t1, 284($t0)
	sw $t1, 288($t0)
	sw $t1, 292($t0)
	sw $t1, 296($t0)
	sw $t1, 300($t0)
	sw $t1, 304($t0)
	sw $t1, 308($t0)
	sw $t1, 312($t0)
	sw $t1, 316($t0)
	sw $t1, 320($t0)
	sw $t1, 324($t0)
	sw $t1, 328($t0)
	sw $t1, 332($t0)
	sw $t1, 336($t0)
	sw $t1, 340($t0)
	sw $t1, 344($t0)
	sw $t1, 348($t0)
	sw $t1, 352($t0)
	sw $t1, 356($t0)
	sw $t1, 360($t0)
	sw $t1, 364($t0)
	sw $t1, 368($t0)
	sw $t1, 372($t0)
	sw $t1, 376($t0)
	sw $t1, 380($t0)
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 392($t0)
	sw $t1, 396($t0)
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
	sw $t1, 440($t0)
	sw $t1, 444($t0)
	sw $t1, 448($t0)
	sw $t1, 452($t0)
	sw $t1, 456($t0)
	sw $t1, 460($t0)
	sw $t1, 464($t0)
	sw $t1, 468($t0)
	sw $t1, 472($t0)
	sw $t1, 476($t0)
	sw $t1, 480($t0)
	sw $t1, 484($t0)
	sw $t1, 488($t0)
	sw $t1, 492($t0)
	sw $t1, 496($t0)
	sw $t1, 500($t0)
	sw $t1, 504($t0)
	sw $t1, 508($t0)
	sw $t2, 1920($t0)
	sw $t2, 2172($t0)
	sw $t2, 2180($t0)
	sw $t2, 2432($t0)
	sw $t2, 2684($t0)
	sw $t2, 2688($t0)
	sw $t2, 2692($t0)
	sw $t3, 2944($t0)
	sw $t3, 3168($t0)
	sw $t3, 3200($t0)
	sw $t3, 3232($t0)
	sw $t3, 3424($t0)
	sw $t3, 3456($t0)
	sw $t3, 3488($t0)
	sw $t3, 3680($t0)
	sw $t3, 3712($t0)
	sw $t3, 3744($t0)
	sw $t3, 3936($t0)
	sw $t3, 3968($t0)
	sw $t3, 4000($t0)
	sw $t3, 4192($t0)
	sw $t3, 4196($t0)
	sw $t3, 4200($t0)
	sw $t3, 4204($t0)
	sw $t3, 4224($t0)
	sw $t3, 4244($t0)
	sw $t3, 4248($t0)
	sw $t3, 4252($t0)
	sw $t3, 4256($t0)
	sw $t3, 4460($t0)
	sw $t3, 4480($t0)
	sw $t3, 4500($t0)
	sw $t3, 4716($t0)
	sw $t3, 4736($t0)
	sw $t3, 4756($t0)
	sw $t3, 4972($t0)
	sw $t3, 4992($t0)
	sw $t3, 5012($t0)
	sw $t3, 5228($t0)
	sw $t3, 5248($t0)
	sw $t3, 5268($t0)
	sw $t3, 5484($t0)
	sw $t3, 5488($t0)
	sw $t3, 5492($t0)
	sw $t3, 5496($t0)
	sw $t3, 5500($t0)
	sw $t3, 5504($t0)
	sw $t3, 5508($t0)
	sw $t3, 5512($t0)
	sw $t3, 5516($t0)
	sw $t3, 5520($t0)
	sw $t3, 5524($t0)
	sw $t3, 6764($t0)
	sw $t3, 6768($t0)
	sw $t3, 6772($t0)
	sw $t3, 6776($t0)
	sw $t3, 6780($t0)
	sw $t3, 6784($t0)
	sw $t3, 6788($t0)
	sw $t3, 6792($t0)
	sw $t3, 6796($t0)
	sw $t3, 6800($t0)
	sw $t3, 6804($t0)
	sw $t3, 7040($t0)
	sw $t3, 7296($t0)
	sw $t3, 7552($t0)
	sw $t3, 7808($t0)
	sw $t3, 8064($t0)
	sw $t3, 8320($t0)
	sw $t3, 8576($t0)
	sw $t3, 8832($t0)
	sw $t3, 9088($t0)
	sw $t3, 9344($t0)
	sw $t3, 9580($t0)
	sw $t3, 9584($t0)
	sw $t3, 9588($t0)
	sw $t3, 9592($t0)
	sw $t3, 9596($t0)
	sw $t3, 9600($t0)
	sw $t3, 9604($t0)
	sw $t3, 9608($t0)
	sw $t3, 9612($t0)
	sw $t3, 9616($t0)
	sw $t3, 9620($t0)
	sw $t3, 10860($t0)
	sw $t3, 10900($t0)
	sw $t3, 11116($t0)
	sw $t3, 11120($t0)
	sw $t3, 11156($t0)
	sw $t3, 11372($t0)
	sw $t3, 11376($t0)
	sw $t3, 11380($t0)
	sw $t3, 11412($t0)
	sw $t3, 11628($t0)
	sw $t3, 11636($t0)
	sw $t3, 11640($t0)
	sw $t3, 11668($t0)
	sw $t3, 11884($t0)
	sw $t3, 11896($t0)
	sw $t3, 11900($t0)
	sw $t3, 11924($t0)
	sw $t3, 12140($t0)
	sw $t3, 12156($t0)
	sw $t3, 12160($t0)
	sw $t3, 12180($t0)
	sw $t3, 12396($t0)
	sw $t3, 12416($t0)
	sw $t3, 12420($t0)
	sw $t3, 12436($t0)
	sw $t3, 12652($t0)
	sw $t3, 12676($t0)
	sw $t3, 12680($t0)
	sw $t3, 12692($t0)
	sw $t3, 12908($t0)
	sw $t3, 12936($t0)
	sw $t3, 12940($t0)
	sw $t3, 12948($t0)
	sw $t3, 13164($t0)
	sw $t3, 13196($t0)
	sw $t3, 13200($t0)
	sw $t3, 13204($t0)
	sw $t3, 13420($t0)
	sw $t3, 13456($t0)
	sw $t3, 13460($t0)
	sw $t3, 13676($t0)
	sw $t3, 13716($t0)
	sw $t4, 15872($t0)
	sw $t4, 15876($t0)
	sw $t4, 15880($t0)
	sw $t4, 15884($t0)
	sw $t4, 15888($t0)
	sw $t4, 15892($t0)
	sw $t4, 15896($t0)
	sw $t4, 15900($t0)
	sw $t4, 15904($t0)
	sw $t4, 15908($t0)
	sw $t4, 15912($t0)
	sw $t4, 15916($t0)
	sw $t4, 15920($t0)
	sw $t4, 15924($t0)
	sw $t4, 15928($t0)
	sw $t4, 15932($t0)
	sw $t4, 15936($t0)
	sw $t4, 15940($t0)
	sw $t4, 15944($t0)
	sw $t4, 15948($t0)
	sw $t4, 15952($t0)
	sw $t4, 15956($t0)
	sw $t4, 15960($t0)
	sw $t4, 15964($t0)
	sw $t4, 15968($t0)
	sw $t4, 15972($t0)
	sw $t4, 15976($t0)
	sw $t4, 15980($t0)
	sw $t4, 15984($t0)
	sw $t4, 15988($t0)
	sw $t4, 15992($t0)
	sw $t4, 15996($t0)
	sw $t4, 16000($t0)
	sw $t4, 16004($t0)
	sw $t4, 16008($t0)
	sw $t4, 16012($t0)
	sw $t4, 16016($t0)
	sw $t4, 16020($t0)
	sw $t4, 16024($t0)
	sw $t4, 16028($t0)
	sw $t4, 16032($t0)
	sw $t4, 16036($t0)
	sw $t4, 16040($t0)
	sw $t4, 16044($t0)
	sw $t4, 16048($t0)
	sw $t4, 16052($t0)
	sw $t4, 16056($t0)
	sw $t4, 16060($t0)
	sw $t4, 16064($t0)
	sw $t4, 16068($t0)
	sw $t4, 16072($t0)
	sw $t4, 16076($t0)
	sw $t4, 16080($t0)
	sw $t4, 16084($t0)
	sw $t4, 16088($t0)
	sw $t4, 16092($t0)
	sw $t4, 16096($t0)
	sw $t4, 16100($t0)
	sw $t4, 16104($t0)
	sw $t4, 16108($t0)
	sw $t4, 16112($t0)
	sw $t4, 16116($t0)
	sw $t4, 16120($t0)
	sw $t4, 16124($t0)
	sw $t4, 16128($t0)
	sw $t4, 16132($t0)
	sw $t4, 16136($t0)
	sw $t4, 16140($t0)
	sw $t4, 16144($t0)
	sw $t4, 16148($t0)
	sw $t4, 16152($t0)
	sw $t4, 16156($t0)
	sw $t4, 16160($t0)
	sw $t4, 16164($t0)
	sw $t4, 16168($t0)
	sw $t4, 16172($t0)
	sw $t4, 16176($t0)
	sw $t4, 16180($t0)
	sw $t4, 16184($t0)
	sw $t4, 16188($t0)
	sw $t4, 16192($t0)
	sw $t4, 16196($t0)
	sw $t4, 16200($t0)
	sw $t4, 16204($t0)
	sw $t4, 16208($t0)
	sw $t4, 16212($t0)
	sw $t4, 16216($t0)
	sw $t4, 16220($t0)
	sw $t4, 16224($t0)
	sw $t4, 16228($t0)
	sw $t4, 16232($t0)
	sw $t4, 16236($t0)
	sw $t4, 16240($t0)
	sw $t4, 16244($t0)
	sw $t4, 16248($t0)
	sw $t4, 16252($t0)
	sw $t4, 16256($t0)
	sw $t4, 16260($t0)
	sw $t4, 16264($t0)
	sw $t4, 16268($t0)
	sw $t4, 16272($t0)
	sw $t4, 16276($t0)
	sw $t4, 16280($t0)
	sw $t4, 16284($t0)
	sw $t4, 16288($t0)
	sw $t4, 16292($t0)
	sw $t4, 16296($t0)
	sw $t4, 16300($t0)
	sw $t4, 16304($t0)
	sw $t4, 16308($t0)
	sw $t4, 16312($t0)
	sw $t4, 16316($t0)
	sw $t4, 16320($t0)
	sw $t4, 16324($t0)
	sw $t4, 16328($t0)
	sw $t4, 16332($t0)
	sw $t4, 16336($t0)
	sw $t4, 16340($t0)
	sw $t4, 16344($t0)
	sw $t4, 16348($t0)
	sw $t4, 16352($t0)
	sw $t4, 16356($t0)
	sw $t4, 16360($t0)
	sw $t4, 16364($t0)
	sw $t4, 16368($t0)
	sw $t4, 16372($t0)
	sw $t4, 16376($t0)
	sw $t4, 16380($t0)
	jr $ra

draw_loss:
	la $t0, base_address
	li $t1, BLUE
	li $t2, GOLDEN
	li $t3, WHITE
	li $t4, ORANGE
	li $t5, GREY
	li $t6, RED
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	sw $t1, 84($t0)
	sw $t1, 88($t0)
	sw $t1, 92($t0)
	sw $t1, 96($t0)
	sw $t1, 100($t0)
	sw $t1, 104($t0)
	sw $t1, 108($t0)
	sw $t1, 112($t0)
	sw $t1, 116($t0)
	sw $t1, 120($t0)
	sw $t1, 124($t0)
	sw $t1, 128($t0)
	sw $t1, 132($t0)
	sw $t1, 136($t0)
	sw $t1, 140($t0)
	sw $t1, 144($t0)
	sw $t1, 148($t0)
	sw $t1, 152($t0)
	sw $t1, 156($t0)
	sw $t1, 160($t0)
	sw $t1, 164($t0)
	sw $t1, 168($t0)
	sw $t1, 172($t0)
	sw $t1, 176($t0)
	sw $t1, 180($t0)
	sw $t1, 184($t0)
	sw $t1, 188($t0)
	sw $t1, 192($t0)
	sw $t1, 196($t0)
	sw $t1, 200($t0)
	sw $t1, 204($t0)
	sw $t1, 208($t0)
	sw $t1, 212($t0)
	sw $t1, 216($t0)
	sw $t1, 220($t0)
	sw $t1, 224($t0)
	sw $t1, 228($t0)
	sw $t1, 232($t0)
	sw $t1, 236($t0)
	sw $t1, 240($t0)
	sw $t1, 244($t0)
	sw $t1, 248($t0)
	sw $t1, 252($t0)
	sw $t1, 256($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 268($t0)
	sw $t1, 272($t0)
	sw $t1, 276($t0)
	sw $t1, 280($t0)
	sw $t1, 284($t0)
	sw $t1, 288($t0)
	sw $t1, 292($t0)
	sw $t1, 296($t0)
	sw $t1, 300($t0)
	sw $t1, 304($t0)
	sw $t1, 308($t0)
	sw $t1, 312($t0)
	sw $t1, 316($t0)
	sw $t1, 320($t0)
	sw $t1, 324($t0)
	sw $t1, 328($t0)
	sw $t1, 332($t0)
	sw $t1, 336($t0)
	sw $t1, 340($t0)
	sw $t1, 344($t0)
	sw $t1, 348($t0)
	sw $t1, 352($t0)
	sw $t1, 356($t0)
	sw $t1, 360($t0)
	sw $t1, 364($t0)
	sw $t1, 368($t0)
	sw $t1, 372($t0)
	sw $t1, 376($t0)
	sw $t1, 380($t0)
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 392($t0)
	sw $t1, 396($t0)
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
	sw $t1, 440($t0)
	sw $t1, 444($t0)
	sw $t1, 448($t0)
	sw $t1, 452($t0)
	sw $t1, 456($t0)
	sw $t1, 460($t0)
	sw $t1, 464($t0)
	sw $t1, 468($t0)
	sw $t1, 472($t0)
	sw $t1, 476($t0)
	sw $t1, 480($t0)
	sw $t1, 484($t0)
	sw $t1, 488($t0)
	sw $t1, 492($t0)
	sw $t1, 496($t0)
	sw $t1, 500($t0)
	sw $t1, 504($t0)
	sw $t1, 508($t0)
	sw $t2, 2444($t0)
	sw $t2, 2452($t0)
	sw $t2, 2460($t0)
	sw $t2, 2700($t0)
	sw $t2, 2704($t0)
	sw $t2, 2708($t0)
	sw $t2, 2712($t0)
	sw $t2, 2716($t0)
	sw $t2, 2960($t0)
	sw $t2, 2968($t0)
	sw $t3, 3136($t0)
	sw $t3, 3184($t0)
	sw $t3, 3204($t0)
	sw $t3, 3208($t0)
	sw $t3, 3212($t0)
	sw $t3, 3216($t0)
	sw $t3, 3220($t0)
	sw $t3, 3224($t0)
	sw $t3, 3228($t0)
	sw $t3, 3232($t0)
	sw $t3, 3236($t0)
	sw $t3, 3240($t0)
	sw $t3, 3244($t0)
	sw $t3, 3264($t0)
	sw $t3, 3304($t0)
	sw $t3, 3392($t0)
	sw $t3, 3396($t0)
	sw $t3, 3436($t0)
	sw $t3, 3440($t0)
	sw $t3, 3460($t0)
	sw $t3, 3500($t0)
	sw $t3, 3520($t0)
	sw $t3, 3560($t0)
	sw $t3, 3652($t0)
	sw $t3, 3656($t0)
	sw $t3, 3688($t0)
	sw $t3, 3692($t0)
	sw $t3, 3716($t0)
	sw $t3, 3756($t0)
	sw $t3, 3776($t0)
	sw $t3, 3816($t0)
	sw $t3, 3912($t0)
	sw $t3, 3916($t0)
	sw $t3, 3940($t0)
	sw $t3, 3944($t0)
	sw $t3, 3972($t0)
	sw $t3, 4012($t0)
	sw $t3, 4032($t0)
	sw $t3, 4072($t0)
	sw $t3, 4172($t0)
	sw $t3, 4176($t0)
	sw $t3, 4192($t0)
	sw $t3, 4196($t0)
	sw $t3, 4228($t0)
	sw $t3, 4268($t0)
	sw $t3, 4288($t0)
	sw $t3, 4328($t0)
	sw $t3, 4432($t0)
	sw $t3, 4436($t0)
	sw $t3, 4444($t0)
	sw $t3, 4448($t0)
	sw $t3, 4484($t0)
	sw $t3, 4524($t0)
	sw $t3, 4544($t0)
	sw $t3, 4584($t0)
	sw $t3, 4692($t0)
	sw $t3, 4696($t0)
	sw $t3, 4700($t0)
	sw $t3, 4740($t0)
	sw $t3, 4780($t0)
	sw $t3, 4800($t0)
	sw $t3, 4840($t0)
	sw $t3, 4952($t0)
	sw $t3, 4996($t0)
	sw $t3, 5036($t0)
	sw $t3, 5056($t0)
	sw $t3, 5096($t0)
	sw $t3, 5208($t0)
	sw $t3, 5252($t0)
	sw $t3, 5292($t0)
	sw $t3, 5312($t0)
	sw $t3, 5352($t0)
	sw $t3, 5464($t0)
	sw $t3, 5508($t0)
	sw $t3, 5548($t0)
	sw $t3, 5568($t0)
	sw $t3, 5608($t0)
	sw $t3, 5720($t0)
	sw $t3, 5764($t0)
	sw $t3, 5804($t0)
	sw $t3, 5824($t0)
	sw $t3, 5864($t0)
	sw $t3, 5976($t0)
	sw $t3, 6020($t0)
	sw $t3, 6060($t0)
	sw $t3, 6080($t0)
	sw $t3, 6120($t0)
	sw $t4, 6172($t0)
	sw $t4, 6176($t0)
	sw $t4, 6180($t0)
	sw $t3, 6232($t0)
	sw $t3, 6276($t0)
	sw $t3, 6316($t0)
	sw $t3, 6336($t0)
	sw $t3, 6376($t0)
	sw $t4, 6432($t0)
	sw $t3, 6488($t0)
	sw $t3, 6532($t0)
	sw $t3, 6572($t0)
	sw $t3, 6592($t0)
	sw $t3, 6632($t0)
	sw $t4, 6684($t0)
	sw $t4, 6692($t0)
	sw $t3, 6744($t0)
	sw $t3, 6788($t0)
	sw $t3, 6828($t0)
	sw $t3, 6848($t0)
	sw $t3, 6888($t0)
	sw $t4, 6944($t0)
	sw $t3, 7000($t0)
	sw $t3, 7044($t0)
	sw $t3, 7048($t0)
	sw $t3, 7052($t0)
	sw $t3, 7056($t0)
	sw $t3, 7060($t0)
	sw $t3, 7064($t0)
	sw $t3, 7068($t0)
	sw $t3, 7072($t0)
	sw $t3, 7076($t0)
	sw $t3, 7080($t0)
	sw $t3, 7084($t0)
	sw $t3, 7104($t0)
	sw $t3, 7108($t0)
	sw $t3, 7112($t0)
	sw $t3, 7116($t0)
	sw $t3, 7120($t0)
	sw $t3, 7124($t0)
	sw $t3, 7128($t0)
	sw $t3, 7132($t0)
	sw $t3, 7136($t0)
	sw $t3, 7140($t0)
	sw $t3, 7144($t0)
	sw $t5, 8932($t0)
	sw $t5, 9184($t0)
	sw $t5, 9188($t0)
	sw $t5, 9192($t0)
	sw $t3, 9240($t0)
	sw $t3, 9292($t0)
	sw $t3, 9296($t0)
	sw $t3, 9300($t0)
	sw $t3, 9304($t0)
	sw $t3, 9308($t0)
	sw $t3, 9312($t0)
	sw $t3, 9316($t0)
	sw $t3, 9320($t0)
	sw $t3, 9324($t0)
	sw $t3, 9328($t0)
	sw $t3, 9332($t0)
	sw $t3, 9360($t0)
	sw $t3, 9364($t0)
	sw $t3, 9368($t0)
	sw $t3, 9372($t0)
	sw $t3, 9376($t0)
	sw $t3, 9380($t0)
	sw $t3, 9384($t0)
	sw $t3, 9388($t0)
	sw $t3, 9392($t0)
	sw $t3, 9416($t0)
	sw $t3, 9420($t0)
	sw $t3, 9424($t0)
	sw $t3, 9428($t0)
	sw $t3, 9432($t0)
	sw $t3, 9436($t0)
	sw $t3, 9440($t0)
	sw $t3, 9444($t0)
	sw $t3, 9448($t0)
	sw $t3, 9496($t0)
	sw $t3, 9548($t0)
	sw $t3, 9588($t0)
	sw $t3, 9616($t0)
	sw $t3, 9648($t0)
	sw $t3, 9672($t0)
	sw $t3, 9704($t0)
	sw $t3, 9752($t0)
	sw $t3, 9804($t0)
	sw $t3, 9844($t0)
	sw $t3, 9872($t0)
	sw $t3, 9928($t0)
	sw $t3, 10008($t0)
	sw $t3, 10060($t0)
	sw $t3, 10076($t0)
	sw $t3, 10084($t0)
	sw $t3, 10100($t0)
	sw $t3, 10128($t0)
	sw $t3, 10184($t0)
	sw $t3, 10264($t0)
	sw $t3, 10316($t0)
	sw $t3, 10328($t0)
	sw $t5, 10332($t0)
	sw $t3, 10336($t0)
	sw $t5, 10340($t0)
	sw $t3, 10344($t0)
	sw $t3, 10356($t0)
	sw $t3, 10384($t0)
	sw $t3, 10440($t0)
	sw $t3, 10520($t0)
	sw $t3, 10572($t0)
	sw $t3, 10580($t0)
	sw $t5, 10584($t0)
	sw $t5, 10588($t0)
	sw $t5, 10592($t0)
	sw $t5, 10596($t0)
	sw $t5, 10600($t0)
	sw $t3, 10604($t0)
	sw $t3, 10612($t0)
	sw $t3, 10640($t0)
	sw $t3, 10644($t0)
	sw $t3, 10648($t0)
	sw $t3, 10652($t0)
	sw $t3, 10656($t0)
	sw $t3, 10660($t0)
	sw $t3, 10664($t0)
	sw $t3, 10668($t0)
	sw $t3, 10696($t0)
	sw $t3, 10700($t0)
	sw $t3, 10704($t0)
	sw $t3, 10708($t0)
	sw $t3, 10712($t0)
	sw $t3, 10716($t0)
	sw $t3, 10720($t0)
	sw $t3, 10724($t0)
	sw $t3, 10776($t0)
	sw $t3, 10828($t0)
	sw $t3, 10840($t0)
	sw $t5, 10844($t0)
	sw $t5, 10848($t0)
	sw $t5, 10852($t0)
	sw $t3, 10856($t0)
	sw $t3, 10868($t0)
	sw $t3, 10924($t0)
	sw $t3, 10980($t0)
	sw $t3, 11032($t0)
	sw $t3, 11084($t0)
	sw $t3, 11100($t0)
	sw $t5, 11104($t0)
	sw $t3, 11108($t0)
	sw $t3, 11124($t0)
	sw $t3, 11180($t0)
	sw $t3, 11236($t0)
	sw $t3, 11288($t0)
	sw $t3, 11340($t0)
	sw $t3, 11360($t0)
	sw $t3, 11380($t0)
	sw $t5, 11408($t0)
	sw $t3, 11436($t0)
	sw $t3, 11492($t0)
	sw $t3, 11544($t0)
	sw $t3, 11596($t0)
	sw $t3, 11636($t0)
	sw $t5, 11660($t0)
	sw $t5, 11664($t0)
	sw $t5, 11668($t0)
	sw $t3, 11692($t0)
	sw $t3, 11748($t0)
	sw $t3, 11800($t0)
	sw $t3, 11852($t0)
	sw $t3, 11892($t0)
	sw $t3, 11916($t0)
	sw $t3, 11920($t0)
	sw $t3, 11948($t0)
	sw $t3, 11972($t0)
	sw $t3, 11976($t0)
	sw $t3, 12004($t0)
	sw $t3, 12056($t0)
	sw $t3, 12060($t0)
	sw $t3, 12064($t0)
	sw $t3, 12068($t0)
	sw $t3, 12072($t0)
	sw $t3, 12076($t0)
	sw $t3, 12080($t0)
	sw $t3, 12084($t0)
	sw $t3, 12088($t0)
	sw $t3, 12092($t0)
	sw $t3, 12108($t0)
	sw $t3, 12112($t0)
	sw $t3, 12116($t0)
	sw $t3, 12120($t0)
	sw $t3, 12124($t0)
	sw $t3, 12128($t0)
	sw $t3, 12132($t0)
	sw $t3, 12136($t0)
	sw $t3, 12140($t0)
	sw $t3, 12144($t0)
	sw $t3, 12148($t0)
	sw $t3, 12172($t0)
	sw $t3, 12176($t0)
	sw $t3, 12180($t0)
	sw $t3, 12184($t0)
	sw $t3, 12188($t0)
	sw $t3, 12192($t0)
	sw $t3, 12196($t0)
	sw $t3, 12200($t0)
	sw $t3, 12204($t0)
	sw $t3, 12228($t0)
	sw $t3, 12232($t0)
	sw $t3, 12236($t0)
	sw $t3, 12240($t0)
	sw $t3, 12244($t0)
	sw $t3, 12248($t0)
	sw $t3, 12252($t0)
	sw $t3, 12256($t0)
	sw $t3, 12260($t0)
	sw $t4, 13952($t0)
	sw $t4, 14064($t0)
	sw $t4, 14080($t0)
	sw $t4, 14084($t0)
	sw $t4, 14088($t0)
	sw $t4, 14096($t0)
	sw $t4, 14120($t0)
	sw $t4, 14140($t0)
	sw $t4, 14144($t0)
	sw $t4, 14148($t0)
	sw $t4, 14160($t0)
	sw $t4, 14168($t0)
	sw $t4, 14180($t0)
	sw $t4, 14188($t0)
	sw $t4, 14204($t0)
	sw $t4, 14212($t0)
	sw $t4, 14220($t0)
	sw $t4, 14228($t0)
	sw $t4, 14244($t0)
	sw $t4, 14260($t0)
	sw $t4, 14268($t0)
	sw $t4, 14288($t0)
	sw $t4, 14316($t0)
	sw $t4, 14324($t0)
	sw $t4, 14340($t0)
	sw $t4, 14348($t0)
	sw $t4, 14356($t0)
	sw $t4, 14372($t0)
	sw $t4, 14380($t0)
	sw $t4, 14400($t0)
	sw $t4, 14412($t0)
	sw $t4, 14420($t0)
	sw $t4, 14424($t0)
	sw $t4, 14436($t0)
	sw $t4, 14440($t0)
	sw $t4, 14448($t0)
	sw $t4, 14464($t0)
	sw $t4, 14476($t0)
	sw $t4, 14480($t0)
	sw $t4, 14488($t0)
	sw $t4, 14496($t0)
	sw $t4, 14504($t0)
	sw $t4, 14516($t0)
	sw $t4, 14520($t0)
	sw $t4, 14528($t0)
	sw $t4, 14540($t0)
	sw $t4, 14548($t0)
	sw $t4, 14556($t0)
	sw $t4, 14564($t0)
	sw $t4, 14576($t0)
	sw $t4, 14592($t0)
	sw $t4, 14600($t0)
	sw $t4, 14608($t0)
	sw $t4, 14632($t0)
	sw $t4, 14652($t0)
	sw $t4, 14660($t0)
	sw $t4, 14672($t0)
	sw $t4, 14680($t0)
	sw $t4, 14692($t0)
	sw $t4, 14700($t0)
	sw $t4, 14716($t0)
	sw $t4, 14720($t0)
	sw $t4, 14724($t0)
	sw $t4, 14732($t0)
	sw $t4, 14740($t0)
	sw $t4, 14756($t0)
	sw $t4, 14772($t0)
	sw $t4, 14780($t0)
	sw $t4, 14800($t0)
	sw $t4, 14808($t0)
	sw $t4, 14816($t0)
	sw $t4, 14820($t0)
	sw $t4, 14828($t0)
	sw $t4, 14832($t0)
	sw $t4, 14836($t0)
	sw $t4, 14852($t0)
	sw $t4, 14860($t0)
	sw $t4, 14864($t0)
	sw $t4, 14868($t0)
	sw $t4, 14876($t0)
	sw $t4, 14884($t0)
	sw $t4, 14888($t0)
	sw $t4, 14892($t0)
	sw $t4, 14912($t0)
	sw $t4, 14928($t0)
	sw $t4, 14932($t0)
	sw $t4, 14936($t0)
	sw $t4, 14948($t0)
	sw $t4, 14980($t0)
	sw $t4, 14984($t0)
	sw $t4, 14988($t0)
	sw $t4, 15008($t0)
	sw $t4, 15012($t0)
	sw $t4, 15016($t0)
	sw $t4, 15020($t0)
	sw $t4, 15036($t0)
	sw $t4, 15052($t0)
	sw $t4, 15056($t0)
	sw $t4, 15060($t0)
	sw $t4, 15068($t0)
	sw $t4, 15076($t0)
	sw $t4, 15088($t0)
	sw $t4, 15092($t0)
	sw $t4, 15096($t0)
	sw $t4, 15108($t0)
	sw $t4, 15116($t0)
	sw $t4, 15128($t0)
	sw $t4, 15136($t0)
	sw $t4, 15144($t0)
	sw $t4, 15152($t0)
	sw $t4, 15168($t0)
	sw $t4, 15176($t0)
	sw $t4, 15188($t0)
	sw $t4, 15200($t0)
	sw $t4, 15208($t0)
	sw $t4, 15216($t0)
	sw $t4, 15224($t0)
	sw $t4, 15240($t0)
	sw $t4, 15256($t0)
	sw $t4, 15264($t0)
	sw $t4, 15272($t0)
	sw $t4, 15280($t0)
	sw $t4, 15288($t0)
	sw $t4, 15296($t0)
	sw $t4, 15308($t0)
	sw $t4, 15316($t0)
	sw $t4, 15324($t0)
	sw $t4, 15332($t0)
	sw $t4, 15348($t0)
	sw $t4, 15364($t0)
	sw $t4, 15368($t0)
	sw $t4, 15376($t0)
	sw $t4, 15388($t0)
	sw $t4, 15400($t0)
	sw $t4, 15404($t0)
	sw $t4, 15412($t0)
	sw $t4, 15420($t0)
	sw $t4, 15428($t0)
	sw $t4, 15432($t0)
	sw $t4, 15440($t0)
	sw $t4, 15448($t0)
	sw $t4, 15460($t0)
	sw $t4, 15472($t0)
	sw $t4, 15476($t0)
	sw $t4, 15484($t0)
	sw $t4, 15492($t0)
	sw $t4, 15500($t0)
	sw $t4, 15508($t0)
	sw $t4, 15516($t0)
	sw $t4, 15520($t0)
	sw $t4, 15532($t0)
	sw $t4, 15548($t0)
	sw $t4, 15560($t0)
	sw $t4, 15568($t0)
	sw $t4, 15572($t0)
	sw $t4, 15580($t0)
	sw $t4, 15584($t0)
	sw $t4, 15592($t0)
	sw $t4, 15600($t0)
	sw $t4, 15608($t0)
	sw $t4, 15620($t0)
	sw $t4, 15628($t0)
	sw $t4, 15640($t0)
	sw $t4, 15644($t0)
	sw $t4, 15648($t0)
	sw $t4, 15656($t0)
	sw $t4, 15664($t0)
	sw $t4, 15680($t0)
	sw $t4, 15688($t0)
	sw $t4, 15700($t0)
	sw $t4, 15712($t0)
	sw $t4, 15716($t0)
	sw $t4, 15720($t0)
	sw $t4, 15728($t0)
	sw $t4, 15736($t0)
	sw $t4, 15752($t0)
	sw $t4, 15768($t0)
	sw $t4, 15776($t0)
	sw $t4, 15784($t0)
	sw $t4, 15788($t0)
	sw $t4, 15792($t0)
	sw $t4, 15800($t0)
	sw $t4, 15804($t0)
	sw $t4, 15808($t0)
	sw $t4, 15820($t0)
	sw $t4, 15828($t0)
	sw $t4, 15836($t0)
	sw $t4, 15844($t0)
	sw $t4, 15860($t0)
	sw $t6, 15872($t0)
	sw $t6, 15876($t0)
	sw $t6, 15880($t0)
	sw $t6, 15884($t0)
	sw $t6, 15888($t0)
	sw $t6, 15892($t0)
	sw $t6, 15896($t0)
	sw $t6, 15900($t0)
	sw $t6, 15904($t0)
	sw $t6, 15908($t0)
	sw $t6, 15912($t0)
	sw $t6, 15916($t0)
	sw $t6, 15920($t0)
	sw $t6, 15924($t0)
	sw $t6, 15928($t0)
	sw $t6, 15932($t0)
	sw $t6, 15936($t0)
	sw $t6, 15940($t0)
	sw $t6, 15944($t0)
	sw $t6, 15948($t0)
	sw $t6, 15952($t0)
	sw $t6, 15956($t0)
	sw $t6, 15960($t0)
	sw $t6, 15964($t0)
	sw $t6, 15968($t0)
	sw $t6, 15972($t0)
	sw $t6, 15976($t0)
	sw $t6, 15980($t0)
	sw $t6, 15984($t0)
	sw $t6, 15988($t0)
	sw $t6, 15992($t0)
	sw $t6, 15996($t0)
	sw $t6, 16000($t0)
	sw $t6, 16004($t0)
	sw $t6, 16008($t0)
	sw $t6, 16012($t0)
	sw $t6, 16016($t0)
	sw $t6, 16020($t0)
	sw $t6, 16024($t0)
	sw $t6, 16028($t0)
	sw $t6, 16032($t0)
	sw $t6, 16036($t0)
	sw $t6, 16040($t0)
	sw $t6, 16044($t0)
	sw $t6, 16048($t0)
	sw $t6, 16052($t0)
	sw $t6, 16056($t0)
	sw $t6, 16060($t0)
	sw $t6, 16064($t0)
	sw $t6, 16068($t0)
	sw $t6, 16072($t0)
	sw $t6, 16076($t0)
	sw $t6, 16080($t0)
	sw $t6, 16084($t0)
	sw $t6, 16088($t0)
	sw $t6, 16092($t0)
	sw $t6, 16096($t0)
	sw $t6, 16100($t0)
	sw $t6, 16104($t0)
	sw $t6, 16108($t0)
	sw $t6, 16112($t0)
	sw $t6, 16116($t0)
	sw $t6, 16120($t0)
	sw $t6, 16124($t0)
	sw $t6, 16128($t0)
	sw $t6, 16132($t0)
	sw $t6, 16136($t0)
	sw $t6, 16140($t0)
	sw $t6, 16144($t0)
	sw $t6, 16148($t0)
	sw $t6, 16152($t0)
	sw $t6, 16156($t0)
	sw $t6, 16160($t0)
	sw $t6, 16164($t0)
	sw $t6, 16168($t0)
	sw $t6, 16172($t0)
	sw $t6, 16176($t0)
	sw $t6, 16180($t0)
	sw $t6, 16184($t0)
	sw $t6, 16188($t0)
	sw $t6, 16192($t0)
	sw $t6, 16196($t0)
	sw $t6, 16200($t0)
	sw $t6, 16204($t0)
	sw $t6, 16208($t0)
	sw $t6, 16212($t0)
	sw $t6, 16216($t0)
	sw $t6, 16220($t0)
	sw $t6, 16224($t0)
	sw $t6, 16228($t0)
	sw $t6, 16232($t0)
	sw $t6, 16236($t0)
	sw $t6, 16240($t0)
	sw $t6, 16244($t0)
	sw $t6, 16248($t0)
	sw $t6, 16252($t0)
	sw $t6, 16256($t0)
	sw $t6, 16260($t0)
	sw $t6, 16264($t0)
	sw $t6, 16268($t0)
	sw $t6, 16272($t0)
	sw $t6, 16276($t0)
	sw $t6, 16280($t0)
	sw $t6, 16284($t0)
	sw $t6, 16288($t0)
	sw $t6, 16292($t0)
	sw $t6, 16296($t0)
	sw $t6, 16300($t0)
	sw $t6, 16304($t0)
	sw $t6, 16308($t0)
	sw $t6, 16312($t0)
	sw $t6, 16316($t0)
	sw $t6, 16320($t0)
	sw $t6, 16324($t0)
	sw $t6, 16328($t0)
	sw $t6, 16332($t0)
	sw $t6, 16336($t0)
	sw $t6, 16340($t0)
	sw $t6, 16344($t0)
	sw $t6, 16348($t0)
	sw $t6, 16352($t0)
	sw $t6, 16356($t0)
	sw $t6, 16360($t0)
	sw $t6, 16364($t0)
	sw $t6, 16368($t0)
	sw $t6, 16372($t0)
	sw $t6, 16376($t0)
	sw $t6, 16380($t0)
	jr $ra
