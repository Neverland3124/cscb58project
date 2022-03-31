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
# - Milestone 2 - 
# - Milestone 3
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


	# load heart to t9
	la $t1, heart
	lw $t9, 0($t1)
	
game_loop:
	bltz $t9, gameover

	# load me_location to $t2
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
	# weight for 40ms for next loop
	li $v0, 32
	li $a0, 40
	syscall
	
	
	# la $t0, heart  # $t0 = address of SHIP_HEALTH
	# sw $t9, 0($t0)		# $t9 = ship health
	j game_loop


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
	j end

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
	li $t2, WHITE
	li $t3, BLUE
	li $t4, GREEN
	li $t5, GOLDEN
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
	sw $t3, 640($t0)
	sw $t3, 644($t0)
	sw $t3, 648($t0)
	sw $t3, 652($t0)
	sw $t3, 656($t0)
	sw $t3, 660($t0)
	sw $t3, 664($t0)
	sw $t3, 668($t0)
	sw $t3, 672($t0)
	sw $t3, 676($t0)
	sw $t3, 680($t0)
	sw $t3, 684($t0)
	sw $t3, 688($t0)
	sw $t3, 692($t0)
	sw $t3, 696($t0)
	sw $t3, 700($t0)
	sw $t3, 704($t0)
	sw $t3, 708($t0)
	sw $t3, 712($t0)
	sw $t3, 716($t0)
	sw $t3, 720($t0)
	sw $t3, 724($t0)
	sw $t3, 728($t0)
	sw $t3, 732($t0)
	sw $t3, 736($t0)
	sw $t3, 740($t0)
	sw $t3, 744($t0)
	sw $t3, 748($t0)
	sw $t3, 752($t0)
	sw $t3, 756($t0)
	sw $t3, 760($t0)
	sw $t3, 764($t0)
	sw $t3, 768($t0)
	sw $t3, 772($t0)
	sw $t3, 776($t0)
	sw $t3, 780($t0)
	sw $t3, 784($t0)
	sw $t3, 788($t0)
	sw $t3, 792($t0)
	sw $t3, 796($t0)
	sw $t3, 800($t0)
	sw $t3, 804($t0)
	sw $t3, 808($t0)
	sw $t3, 812($t0)
	sw $t3, 816($t0)
	sw $t3, 820($t0)
	sw $t3, 824($t0)
	sw $t3, 828($t0)
	sw $t3, 832($t0)
	sw $t3, 836($t0)
	sw $t3, 840($t0)
	sw $t3, 844($t0)
	sw $t3, 848($t0)
	sw $t3, 852($t0)
	sw $t3, 856($t0)
	sw $t3, 860($t0)
	sw $t3, 864($t0)
	sw $t3, 868($t0)
	sw $t3, 872($t0)
	sw $t3, 876($t0)
	sw $t3, 880($t0)
	sw $t3, 884($t0)
	sw $t3, 888($t0)
	sw $t3, 892($t0)
	sw $t4, 896($t0)
	sw $t4, 900($t0)
	sw $t4, 1016($t0)
	sw $t4, 1020($t0)
	sw $t4, 1024($t0)
	sw $t4, 1148($t0)
	sw $t4, 1152($t0)
	sw $t4, 1156($t0)
	sw $t4, 1272($t0)
	sw $t4, 1276($t0)
	sw $t4, 1280($t0)
	sw $t5, 1312($t0)
	sw $t5, 1320($t0)
	sw $t5, 1328($t0)
	sw $t4, 1404($t0)
	sw $t4, 1408($t0)
	sw $t4, 1412($t0)
	sw $t5, 1440($t0)
	sw $t5, 1444($t0)
	sw $t5, 1448($t0)
	sw $t5, 1452($t0)
	sw $t5, 1456($t0)
	sw $t4, 1528($t0)
	sw $t4, 1532($t0)
	sw $t4, 1536($t0)
	sw $t5, 1572($t0)
	sw $t5, 1580($t0)
	sw $t4, 1660($t0)
	sw $t4, 1664($t0)
	sw $t4, 1668($t0)
	sw $t2, 1692($t0)
	sw $t2, 1696($t0)
	sw $t2, 1700($t0)
	sw $t2, 1704($t0)
	sw $t2, 1708($t0)
	sw $t2, 1712($t0)
	sw $t2, 1716($t0)
	sw $t4, 1784($t0)
	sw $t4, 1788($t0)
	sw $t4, 1792($t0)
	sw $t4, 1916($t0)
	sw $t4, 1920($t0)
	sw $t4, 1924($t0)
	sw $t6, 1988($t0)
	sw $t4, 2040($t0)
	sw $t4, 2044($t0)
	sw $t4, 2048($t0)
	sw $t6, 2112($t0)
	sw $t6, 2116($t0)
	sw $t6, 2120($t0)
	sw $t4, 2172($t0)
	sw $t4, 2176($t0)
	sw $t4, 2180($t0)
	sw $t2, 2240($t0)
	sw $t2, 2244($t0)
	sw $t2, 2248($t0)
	sw $t2, 2252($t0)
	sw $t2, 2256($t0)
	sw $t2, 2260($t0)
	sw $t2, 2264($t0)
	sw $t4, 2296($t0)
	sw $t4, 2300($t0)
	sw $t4, 2304($t0)
	sw $t4, 2428($t0)
	sw $t4, 2432($t0)
	sw $t4, 2436($t0)
	sw $t4, 2552($t0)
	sw $t4, 2556($t0)
	sw $t4, 2560($t0)
	sw $t4, 2684($t0)
	sw $t4, 2688($t0)
	sw $t4, 2692($t0)
	sw $t4, 2808($t0)
	sw $t4, 2812($t0)
	sw $t4, 2816($t0)
	sw $t4, 2940($t0)
	sw $t4, 2944($t0)
	sw $t4, 2948($t0)
	sw $t2, 2976($t0)
	sw $t2, 2980($t0)
	sw $t2, 2984($t0)
	sw $t2, 2988($t0)
	sw $t2, 2992($t0)
	sw $t2, 2996($t0)
	sw $t2, 3000($t0)
	sw $t4, 3064($t0)
	sw $t4, 3068($t0)
	sw $t4, 3072($t0)
	sw $t4, 3196($t0)
	sw $t4, 3200($t0)
	sw $t4, 3204($t0)
	sw $t4, 3320($t0)
	sw $t4, 3324($t0)
	sw $t4, 3328($t0)
	sw $t4, 3452($t0)
	sw $t4, 3456($t0)
	sw $t4, 3460($t0)
	sw $t4, 3576($t0)
	sw $t4, 3580($t0)
	sw $t4, 3584($t0)
	sw $t6, 3672($t0)
	sw $t4, 3708($t0)
	sw $t4, 3712($t0)
	sw $t4, 3716($t0)
	sw $t6, 3796($t0)
	sw $t6, 3800($t0)
	sw $t6, 3804($t0)
	sw $t4, 3832($t0)
	sw $t4, 3836($t0)
	sw $t4, 3840($t0)
	sw $t2, 3908($t0)
	sw $t2, 3912($t0)
	sw $t2, 3916($t0)
	sw $t2, 3920($t0)
	sw $t2, 3924($t0)
	sw $t2, 3928($t0)
	sw $t2, 3932($t0)
	sw $t4, 3964($t0)
	sw $t4, 3968($t0)
	sw $t4, 3972($t0)
	sw $t4, 4088($t0)
	sw $t4, 4092($t0)
	sw $t4, 4096($t0)
	sw $t4, 4220($t0)
	sw $t4, 4224($t0)
	sw $t4, 4228($t0)
	sw $t4, 4344($t0)
	sw $t4, 4348($t0)
	sw $t4, 4352($t0)
	sw $t4, 4476($t0)
	sw $t4, 4480($t0)
	sw $t4, 4484($t0)
	sw $t4, 4600($t0)
	sw $t4, 4604($t0)
	sw $t4, 4608($t0)
	sw $t4, 4732($t0)
	sw $t4, 4736($t0)
	sw $t4, 4740($t0)
	sw $t4, 4856($t0)
	sw $t4, 4860($t0)
	sw $t4, 4864($t0)
	sw $t2, 4924($t0)
	sw $t2, 4928($t0)
	sw $t2, 4932($t0)
	sw $t2, 4936($t0)
	sw $t2, 4940($t0)
	sw $t2, 4944($t0)
	sw $t2, 4948($t0)
	sw $t4, 4988($t0)
	sw $t4, 4992($t0)
	sw $t4, 4996($t0)
	sw $t4, 5112($t0)
	sw $t4, 5116($t0)
	sw $t4, 5120($t0)
	sw $t4, 5244($t0)
	sw $t4, 5248($t0)
	sw $t4, 5252($t0)
	sw $t4, 5368($t0)
	sw $t4, 5372($t0)
	sw $t4, 5376($t0)
	sw $t4, 5500($t0)
	sw $t4, 5504($t0)
	sw $t4, 5508($t0)
	sw $t4, 5624($t0)
	sw $t4, 5628($t0)
	sw $t4, 5632($t0)
	sw $t4, 5756($t0)
	sw $t4, 5760($t0)
	sw $t4, 5764($t0)
	sw $t4, 5880($t0)
	sw $t4, 5884($t0)
	sw $t4, 5888($t0)
	sw $t2, 6484($t0)
	sw $t2, 6488($t0)
	sw $t2, 6492($t0)
	sw $t2, 6496($t0)
	sw $t2, 6500($t0)
	sw $t2, 6504($t0)
	sw $t2, 6508($t0)
	sw $t2, 6512($t0)
	sw $t4, 6012($t0)
	sw $t4, 6016($t0)
	sw $t4, 6020($t0)
	sw $t4, 6136($t0)
	sw $t4, 6140($t0)
	sw $t4, 6144($t0)
	sw $t4, 6268($t0)
	sw $t4, 6272($t0)
	sw $t4, 6276($t0)
	sw $t4, 6392($t0)
	sw $t4, 6396($t0)
	sw $t4, 6400($t0)
	sw $t4, 6524($t0)
	sw $t4, 6528($t0)
	sw $t4, 6532($t0)
	sw $t4, 6648($t0)
	sw $t4, 6652($t0)
	sw $t4, 6656($t0)
	sw $t4, 6780($t0)
	sw $t4, 6784($t0)
	sw $t4, 6788($t0)
	sw $t2, 7088($t0)
	sw $t2, 7092($t0)
	sw $t2, 7096($t0)
	sw $t2, 7100($t0)
	sw $t2, 7104($t0)
	sw $t2, 7108($t0)
	sw $t2, 7112($t0)
	sw $t2, 7116($t0)
	sw $t4, 6904($t0)
	sw $t4, 6908($t0)
	sw $t4, 6912($t0)
	sw $t4, 7036($t0)
	sw $t4, 7040($t0)
	sw $t4, 7044($t0)
	sw $t7, 6936($t0)
	sw $t4, 7160($t0)
	sw $t4, 7164($t0)
	sw $t4, 7168($t0)
	sw $t7, 7060($t0)
	sw $t7, 7068($t0)
	sw $t4, 7292($t0)
	sw $t4, 7296($t0)
	sw $t4, 7300($t0)
	sw $t7, 7192($t0)
	sw $t4, 7416($t0)
	sw $t4, 7420($t0)
	sw $t4, 7424($t0)
	sw $t7, 7324($t0)
	sw $t7, 7316($t0)
	sw $t7, 7320($t0)
	sw $t4, 7548($t0)
	sw $t4, 7552($t0)
	sw $t4, 7556($t0)
	sw $t2, 7692($t0)
	sw $t2, 7696($t0)
	sw $t2, 7700($t0)
	sw $t2, 7704($t0)
	sw $t2, 7708($t0)
	sw $t2, 7712($t0)
	sw $t2, 7716($t0)
	sw $t2, 7720($t0)
	sw $t4, 7672($t0)
	sw $t4, 7676($t0)
	sw $t4, 7680($t0)
	sw $t4, 7804($t0)
	sw $t4, 7808($t0)
	sw $t4, 7812($t0)
	sw $t4, 7928($t0)
	sw $t4, 7932($t0)
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

end:
	li $v0 10
	syscall
