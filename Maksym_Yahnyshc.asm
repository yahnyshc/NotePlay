.data
explain:    .asciiz     "\nOptions:\tColours:\n1 - cls\t\t1 - red\n2 - stave\t2 - orange\n3 - note\t3 - yellow\n4 - exit\t4 - green\n\t\t5 - blue\n"
input:      .asciiz		"Select an option:"
detail:	    .asciiz 	"Select colour/row/note:"
wrongInputText: .asciiz "\nWrong input:\nOptions allowed: 1,2,3,4.\nColours allowed: 1,2,3,4,5.\nNotes allowed: A,B,C,D,E,F,G.\nRow allowed, < 256.\nPlease enter again.\n\n"

note_char:  .byte ' ' 	# user input note

red:        .word	0x00FF0000
orrange:    .word	0x00FFCC00
yellow:     .word	0x00FFFF00
green:      .word	0x0000FF00
blue:       .word	0x000000FF

.text

main:
    	j options
    
wrongInput:
	addi $v0,$zero,4 	# print 
   	la $a0, wrongInputText 	# wrong input notification
   	syscall
   	j options 		# try to enter option again

cls: 
 	lw, $t1, red
 	beq $a0, 1, fill_background
 	lw $t1, orrange
 	beq $a0, 2, fill_background
 	lw $t1, yellow
 	beq $a0, 3, fill_background
 	lw $t1, green
 	beq $a0, 4, fill_background
 	lw $t1, blue
 	beq $a0, 5, fill_background
 	
 	j wrongInput
	
	fill_background:
		addi $s0,$zero,0 	#sets $s0 to zero – initialise
 		lui $s0, 0x1004 	#store in heap memory
 	
		li $s1, 4
		lui $s1,0x100C 		#end of screen area in $s1
	
		filling:   beq $s0, $s1, options # jump to options if filled
	     		sw $t1, 0($s0)

			addi $s0, $s0, 4
			j filling

stave:
	addi $s0,$zero,0 	#sets $s0 to zero – initialise
	lui $s0, 0x1004
	sll $a0, $a0, 11 	# multiply input by 2^11 = 512*4
	add $s1, $s0, $a0 	# first stave starting position
	li $a1, 0 		# colour of staves
	add $t0, $zero, 0 	# counter of staves
	addi $a0, $zero, 512 	# line length
	la $a3, 0($s1) 		# line starting address
	lines:  
		addi $a2,$zero,0 	# drawLine counter
		jal drawLine
		addi $a3, $a3, 20480 	# jump 10 lines
		addi $t0, $t0, 1
		bne $t0, 5, lines 	# 5 staves
		
	addi $s1, $a3, -20480 	# back 10 lines
	j options
	

drawLine: # loop to draw line of length $a0, with starting position $a3 and colour $a1
	sw $a1, 0($a3)
	
	addi $a2, $a2, 1
	addi $a3, $a3, 4
	bne $a2, $a0, drawLine
	jr $ra

note:
	beq $a0, 'F', F
	beq $a0, 'G', G
	beq $a0, 'A', A
	beq $a0, 'B', B
	beq $a0, 'C', C
	beq $a0, 'D', D
	beq $a0, 'E', E
	
	# no matched note
	
	j wrongInput
	
	# register $t1 will contain number of shifts to set note on correct position
	F:	
		addi $t1, $zero, 0
		addi $s3, $zero, 65
		j e
	G:
		addi $t1, $zero, 1
		addi $s3, $zero, 67
		j e
	A:
		addi $t1, $zero, 2
		addi $s3, $zero, 69
		j e
	B:
		addi $t1, $zero, 3
		addi $s3, $zero, 71
		j e
	C:
		addi $t1, $zero, 4
		addi $s3, $zero, 72
		j e
	D:
		addi $t1, $zero, 5
		addi $s3, $zero, 74
		j e
	E:
		addi $t1, $zero, 6
		addi $s3, $zero, 76
		j e
	e:
	addi $sp, $sp, -4 
    	sw $s1, 0($sp) 		# save $s1 as it identifies position of previously printed staves
    	
	addi $s1,$s1, -18232 	# set position of starting note: 20216 = 9*4*512 - 200 
		             	# $s1 contains address of the end of last drawn stave
	addi $t0, $zero, -10240 # vertical distance between notes: 10240 = 5*4*512
	addi $t3, $zero, 264 	# horizontal distance between notes
	
	addi $t2, $zero, 0 		# counter
	positioning: beq $t2, $t1, q 	# shifting note drawing position depending on the note
		add $s1, $s1, $t0 	# shift vertical
		add $s1, $s1, $t3 	# shift horizontal
		addi $t2, $t2, 1 
		andi $t4, $t2, 1 	# check if note number is even or uneven
		bne $t4, 0, positioning # if note number is even, move up one line(for better positioning)
		addi $s1, $s1, -2048
		j positioning
	q:	
	addi $t0, $zero, 0 	# counter for heigth
	addi $a0, $zero, 8 	# width of a note
	addi $a1, $zero, 0 	# note color(black)
	la $a3, 0($s1) 	   	# starting address to draw note
	drawNote: 
		addi $a2, $zero, 0 	# drawLine counter
		jal drawLine
		addi $a3, $a3, 2016 	# jump line down
		addi $t0, $t0, 1 
		bne $t0, 6, drawNote 	# note heigth 6
	
	lw $s1, 0($sp) 		# restore $s1 value
	addi $sp, $sp, 4 	# restore stack pointer address
	
	la $a0, 0($s3) 		# pitch
	addi $a1, $zero, 1999 	# sound duration
	addi $a2, $zero, 70 	# instrument
	addi $a3, $zero, 127 	# volume
	addi $v0, $zero, 33 	# play sound
	syscall
	# options again

options:
    	addi $v0,$zero,4 	# print 
   	la $a0, explain 	# show options
   	syscall
   	
    	la $a0, input 		# ask to select option
  	syscall
  	
    	addi $v0,$zero, 5 	# get input
    	syscall
    	
    	add $s0, $zero, $v0 	#store option in $s0
    
    	beq $s0, 4, exit 	# exit if option is 4
    
    	addi $v0, $zero, 4  	# print
    	la $a0, detail 		# ask to select color row note
    	syscall
    	
    	bne $s0, 3, scan_int 	# if it is not note go to scan_int
    	# reading note char
    	addi $v0,$zero, 12 	# read char
    	syscall
    	sb $v0, note_char 	# store input in note_char
    	lb $a0, note_char 	# store note char in $s1
    	j call 			# call options
    	
    	scan_int: 
    	addi $v0,$zero, 5 	# read integer
    	syscall
    	add $a0, $zero, $v0 	# getting colour/row
    	
    	# checking if row input is less than 256
    	slti $t0, $a0, 256   	# 256 > $s1  as ($s1 < 256) != 0
    	bne $t0, $zero, call 	# if less, call functions
    	
    	j wrongInput
   	
    	call: 	
    	beq $s0, 1, cls
    	beq $s0, 2, stave
    	beq $s0, 3, note
    	
    	# no matched option
    	j wrongInput

exit:
