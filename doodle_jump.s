#####################################################################
#
# Fall 2020 Assembly Project
# Author: Xaria Prempeh
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which game feautures have been implemented?
# 1. game over/retry
# 2. 3 different levels (with increasing difficulty)
#
# Which approved additional features have been implemented?
# 1. Two Doodle Birds	(operated by d&f and j&k)
# 2. More Platform Types
# 3. Opponents/Lethal Creatures (2 random types)
#
# Additional information:
# - Press 'x' to terminate the program with a goodbye message.
# - Press 's' on the start screen to start the game at the current selected level.
# - Press 's' otherwise to retry/restart the same level at anytime and opens the start screen.
# - Press 'w' to cycle through the start screens for the 3 different levels at anytime.
# - Press 'r' to reset the platform positions at the start of the game, in the case where the platforms were
#   intially generated in such a way that it's impossible to advance. (i.e positioned out of the doodler's reach.
# - The game is lost only when both doodlers fall off the screen or run into enemies.
# - Lethal creatures only appear on levels 2 and 3, the number of platform types used increases with the level.
# - The red doodler is moved with d and e.
# - The pink doodler is moved with j and k.
# - The orange opponent pushes the doodler back down when touched (stops jumps early).
# - The grey opponent instantly kills the doodler it touches.
# - Opponents move quicker in level 3 than in level 2.
#####################################################################

.data
topLeft: .word 0x10008000		# Position references for display addresses
topRight: .word 0x1000807c
bottomLeft: .word 0x10008f80
bottomRight: .word 0x10008ffc

platformColourNormal: .word 0xc71585	# Platform Colours/Types
platformColourBounce: .word 0x87cefa
platformColourBreak: .word 0x808080
platformColourMove: .word 0x98fb98
platformLocations: .space 48	# Array to store the display addresses of at most 6 platforms + their colours (2 x 6 x 4)

doodlerColour1: .word 0xdb7093
doodlerColour2: .word 0xdc143c
doodlerCharacter1: .space 52 	# Array to store doodler colour + the display addresses of 5 parts and the background colour corresponding to each, 1 to jump 0 to fall, 2 extra jump, -1 to be dead, distance jumped
doodlerCharacter2: .space 52 	# Array to store doodler colour + the display addresses of 5 parts and the background colour corresponding to each, 1 to jump, 0 to fall, distance jumped

enemyColour1: .word 0xf8f8ff
enemyColour2: .word 0xb0c4de
enemyColour3: .word 0xffa07a
enemyLocations: .space 24	# Array to store the display addresses of at most 2 enemies + their colours + direction (2 x 3 x 4)

skyColour1:  .word 0xe0ffff	# Background colours for levels
skyColour2: .word 0xfff0f5
skyColour3: .word 0x00008b
LevelsAttributes: .space 24	# Stores # of platforms associated with each level and # enemies (2x3x4)
currentLevel: .space 20 		# Stores current level number, background colour, # platforms, # enemies, flag for new level (5 x 4)

movePlatformDirection: .space 4 	# For moving platforms, stores -4 to go left, 4 to go right

.text
SetUp:			# Fill in characteristics for each level
la $t0, LevelsAttributes	# Starting location for array containing level info
li $t1, 0		# Index for array
li $t3, 4		# Number of platforms to start
li $t4, 0		# Number of enemies to start
setUpLoop:
beq $t1, 24, EndSetUpLoop	# Repeat for each level (3)
add $t2, $t0, $t1	# Points to first location for current level
sw $t3, 0($t2)		# Store number of platforms for this level
sw $t4, 4($t2)		# Store number of enemies for this level
addi $t3, $t3, 1		# Increase number by 1 for next level
addi $t4, $t4, 1		# Increase number of enemies by 1
addi $t1, $t1, 8		# Jump index two locations after for next level
j setUpLoop
EndSetUpLoop:

la $s4, movePlatformDirection	# For moving platform, stores -4 to go left, 4 to go right
li $t1, 4
sw $t1, 0($s4)			# Initialize to go right

li $a0, 1
jal updateLevel		# Set initial level to level 1
j StartScreen		# Open start screen
EndSetUp:


nextLevel:		# Switch to next level or back to level 1 if all levels reached
addi $sp, $sp, -4
sw $ra , 0($sp)

la $t0, currentLevel
lw $a0, 0($t0)		# Get current level number
beq $a0, 3, resetLevelNum	# If lvl 3 reached, return to lvl 1
addi $a0, $a0, 1			# otherwise increase number
j setLevel
resetLevelNum: li $a0, 1
setLevel: jal updateLevel	# fetch new characteristics for new level

lw $ra , 0($sp)
addi $sp, $sp, 4
jr $ra
endNextLevel:


restartLevel:		# Resets current level to initial attributes
addi $sp, $sp, -4
sw $ra , 0($sp)
la $t0, currentLevel
lw $a0, 0($t0)		# Reload current level number
jal updateLevel		# Reset contents
lw $ra , 0($sp)
addi $sp, $sp, 4
jr $ra
endRestartLevel:


updateLevel:		# Takes an input of $a0 as level number to fetch
la $t0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
sw $a0, 0($t0)		# Store new level number given

level1: bne $a0, 1, level2
	lw $t1, skyColour1
	j endLvlSelect
level2: bne $a0, 2, level3
	lw $t1, skyColour2
	j endLvlSelect
level3: lw $t1, skyColour3
endLvlSelect:
sw $t1, 4($t0)		# Store associated background colour

la $t2, LevelsAttributes	# Starting location for array storing all characteristics
addi $a1, $a0, -1	# Subtract 1 from level number
li $t3, 8
mult $a1, $t3		# Multiply by 8 to jump 2 array locations
mflo $t3
add $t2, $t2, $t3	# Go to array location of this level

lw $t1, 0($t2)		# Fetch # platforms
sw $t1, 8($t0)		# Store number of platforms
lw $t1, 4($t2)		# Fetch # enemies
sw $t1, 12($t0)		# Store number of enemies
li $t1, 1
sw $t1, 16($t0)		# Store indicator for new level
jr $ra
EndUpdateLevel:


StartScreen:		# Initial game screen
jal DrawMap
jal DrawStart
jal DrawLvl		# Print Level number to screen
start:
lw $t8, 0xffff0000
bne $t8, 1, skipinput	# Check for new input
lw $s1, 0xffff0004
beq $s1, 0x73, respond_to_Start	# s
beq $s1, 0x78, respond_to_Exit	# x
beq $s1, 0x77, respond_to_NxtLvl	# w
skipinput:
j start

respond_to_Start:
	j Main
respond_to_NxtLvl:
	jal nextLevel
	j StartScreen
respond_to_Exit:
	j Exit


Main:			# Main function for game
jal DrawMap		# Draw background for level
# Create Platforms
addi $a0, $zero, 2	# Generate random platforms anywhere
addi $a1, $zero, 1	# Colour platforms
jal RecolourPlatforms

li $a0, 1		# Set character 1 to start position
jal CreateDoodler
li $a0, 2		# Set character 2 to start position
jal CreateDoodler

jal CreateEnemies	# Generate enemies if level requires them

startGame:		# Active game loop
li $a0, 1		# Tracks movement for char 1
jal CheckDoodlerMovement

li $a0, 2		# Tracks movement for char 2
jal CheckDoodlerMovement

jal MoveEnemies		# Tracks movement for all enemies

jal checkIfLost		# Determine if any doodlers have fallen, return number of current losses
lw $s5 , 0($sp)		# Get number of losses this game, max 2 (number of doodlers)
addi $sp, $sp, 4
beq $s5, 2, EndGame	# If both doodlers lost, end the game (go to retry screen)

jal ShiftDoodlerInput	# Check for keyboard input
j startGame
EndMain:


checkIfLost:		# Checks doodlers and returns number of inactive doodlers
addi $sp, $sp, -4
sw $ra , 0($sp)

li $a0, 1		# Pass in char 1
jal checkIfDoodlerActive	# returns $v1, contains 0 indicates active, 1 indicates inactive
add $s5, $zero, $v1

li $a0, 2		# Pass in char 2
jal checkIfDoodlerActive	# returns $v1, 0 indicates active, 1 indicates inactive
add $s5, $s5, $v1

lw $ra , 0($sp)
addi $sp, $sp, 4		# Reload return address

addi $sp, $sp, -4
sw $s5 , 0($sp)		# Returns # of doodlers that lost to caller
jr $ra


checkIfDoodlerActive: 	# takes in $a0, as doodler number, returns $v1, as inactive or not
addi $sp, $sp, -4
sw $ra , 0($sp)
jal GetDoodler		# returns $v0, doodler array start location for required char number
lw $t0, 44($v0)		# get status of this doodler, 0 for fall, 1 for jump, -1 for inactive
li $v1, 0		# Initialize as 0
bne $t0, -1, Return0	# If doodler still active return $v1 as 0
li $v1, 1		# otherwise return 1
Return0:
lw $ra , 0($sp)
addi $sp, $sp, 4
jr $ra


CheckDoodlerMovement:	# Take in $a0 as doodler ID number (1 or 2)
addi $sp, $sp, -4
sw $ra, 0($sp)		# Restore display address from stack
jal GetDoodler		# Pass in $a0 and receive $v0 for corresponding doodler array

addi $sp, $sp, -4
sw $a0, 0($sp)		# Store doodler number to stack

lw $t0, 44($v0)		# get doodler status (0 for fall, 1 for jump, 2 for double jump, -1 for dead)
beq $t0, -1, KD		# If doodler lost, skip move function

addi $sp, $sp, -4
sw $v0, 0($sp)		# Store doodler array to stack

beq $t0, 0, FD		# If falling
beq $t0, 1, JD		# If jumping
beq $t0, 2, JD		# If double jumping
FD: jal FallDoodler
j EndDecision
JD: jal JumpDoodler
j EndDecision

EndDecision:
lw $v1, 0($sp)		# Restore direction to move in from stack (put there by Fall/Jump functions
addi $sp, $sp, 4
lw $v0, 0($sp)		# Restore doodler array from stack
addi $sp, $sp, 4

jal MoveDoodler		# Move doodler in the direction $v1 specifies

jal MoveGreenPlatform	# Move special platforms

KD:
lw $a0, 0($sp)		# Restore doodler ID number from stack
addi $sp, $sp, 4
lw $ra, 0($sp)		# Restore return address from stack
addi $sp, $sp, 4
jr $ra


ShiftDoodlerInput:	# Check for keyboard input
lw $t8, 0xffff0000
bne $t8, 1, endinput	# No new key pressed, so don't check for function
keyboard_input:
addi $sp, $sp, -4
sw $ra, 0($sp)		# Save return address
lw $s1, 0xffff0004	# Fetch new key input
# Move Doodlers Left
beq $s1, 0x6a, respond_to_J
beq $s1, 0x6b, respond_to_K
# Move Doodlers Right
beq $s1, 0x64, respond_to_D
beq $s1, 0x66, respond_to_F
# General Game Start/Exit Functions
beq $s1, 0x73, respond_to_S
beq $s1, 0x78, respond_to_X
beq $s1, 0x77, respond_to_W
beq $s1, 0x72, respond_to_R
j endinput

# Left Direction Keys for doodlers 1 and 2 respectfully
respond_to_J:
li $a0, 1
jal GetDoodler
j Left
respond_to_D:
li $a0, 2
jal GetDoodler
Left: addi $v1, $zero, -4
j saveNewLoc

# Right Direction Keys for doodlers 1 and 2 respectively
respond_to_K:
li $a0, 1
jal GetDoodler
j Right
respond_to_F:
li $a0, 2
jal GetDoodler
Right: addi $v1, $zero, 4
j saveNewLoc

respond_to_S:		# Restart Game, takes to initial start screen
jal restartLevel
j StartScreen

respond_to_W:		# Switch between levels 1-3
jal nextLevel
j StartScreen

respond_to_R:		# Refresh platforms in case platforms generated in an impossible to play position
jal restartLevel
j Main

respond_to_X:		# Close game
j Exit

saveNewLoc:
jal MoveDoodler		# Move Doodler if directional keys pressed
lw $ra, 0($sp)
addi $sp, $sp, 4		# Load return address

endinput:
jr $ra


# Draws background image plus inital ground (to prevent possibily failing on initial fall)
DrawMap:
addi $s0, $zero, 0	# Counter to track number of pixels drawn
lw $t1, topLeft		# Stores current display address to colour
	DetermineColour:
	beq $s0, 1024, EndMap	# While entire map not drawn
		la $t3, currentLevel	# Fetch info for this level
		lw $t2, 4($t3)		# Get background colour for level
		blt $s0, 992, DrawSky	# Every row except last row gets sky colour
		DrawGround: lw $t2, platformColourNormal	# Draw platform on ground level
		DrawSky: sw $t2, 0($t1)
		addi $t1, $t1, 4		# Go to next display address
		addi $s0, $s0, 1		# Increment pixel counter
	j DetermineColour
EndMap: jr $ra


CreateDoodler:
addi $sp, $sp, -4
sw $ra, 0($sp)		# Save return address in stack

lw $t3, topLeft		# Start at initial display address
beq $a0, 1, Char1	# Determine character to create
beq $a0, 2, Char2
Char1: 
	la $s0, doodlerCharacter1
	lw $a0, doodlerColour1		# Fetch doodler's colour
	j EndCharSelect
Char2: 
	la $s0, doodlerCharacter2
	lw $a0, doodlerColour2
	addi $t3, $t3, -20		# Shift character 2 to the left (5 spaces)
EndCharSelect:
sw $a0, 0($s0)		# Store doodler colour into array

addi $s2, $zero, 44	# Maximum array location of array
addi $s1, $zero, 4	# Set to the first location in array which stores an address
addi $t3, $t3, 60	# Position doodler to the center at the top
addi $t3, $t3, 384	# Position center of doodler downwards (3 rows)

CreateLoop:		# Loop to draw 5-piece doodler (X shape)
beq $s1, $s2, EndCreateLoop	# While all 5 pieces not drawn
	add $t2, $s0, $s1	# Set $t2 to point to address which will hold this piece's location
	beq $s1, 4, P1		# Bottom Left
	beq $s1, 12, P2		# Bottom Right
	beq $s1, 20, P3		# Center
	beq $s1, 28, P4		# Top Left
	beq $s1, 36, P5		# Top Right
	P1: addi $a1, $t3, -4
	j Next
	P2: addi $a1, $t3, 4
	j Next
	P3: addi $a1, $t3, -128
	j Next
	P4: addi $a1, $t3, -260
	j Next
	P5: addi $a1, $t3, -252
	Next:
	sw $a1, 0($t2)		# Store location into array
	lw $t4, 0($a1)
	sw $t4, 4($t2)		# Store background colour about to be overwritten
	jal DrawPixel		# Input colour $a0 and location $a1
	addi $s1, $s1, 8		# Increase index of platform array by 2 addresses
j CreateLoop
EndCreateLoop:
li $t4, 0
sw $t4, 44($s0)		# Store fall action (0) to last array location
sw $t4, 48($s0)		# Store distance jumped as 0 to last array location

lw $ra, 0($sp)		# Restore address in stack
addi $sp, $sp, 4
jr $ra


DrawPixel:
sw $a0, 0($a1) 		# Paint square
jr $ra


CreateEnemies:		# Generate enemies required for level
addi $sp, $sp, -4
sw $ra, 0($sp)
la $s0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
lw $t0, 12($s0)		# Load maximum number of enemies to use
li $t1, 12		# Multiply by length of 3 address locations (3x4)
mult $t0, $t1
mflo $t0			# Maximum location to access

addi $s2, $zero, 0	# Initialize array index to 0
la $s1, enemyLocations	# Array to store the display addresses of at most 2 enemies + their colours + direction (2 x 2 x 4)

EnemyLoop:
beq $s2, $t0, EndEnemyLoop	# If not all enemies drawn
add $t2, $s1, $s2		# Set to appropriate array location

lw $t1, topLeft
addi $t1, $t1, 1288
li $v0, 42
li $a0, 0
li $a1 6
syscall
li $a1, 24
mult $a0, $a1
mflo $a0				# Randomise starting point for enemy on screen

add $t1, $t1, $a0		# Increse initial display address
sw $t1, 0($t2)			# store display address of enemy

li $v0, 42
li $a0, 0
li $a1 2				# Randomise colour for enemy
syscall

beq $a0, 0, Ghost		# Doodler loses when touched
beq $a0, 1, Orange		# Doodler falls when touched (jump is cut off early)
Ghost: lw $t1, enemyColour2
j ColourEn
Orange: lw $t1, enemyColour3
ColourEn: sw $t1, 4($t2)		# store colour of enemy

li $t1, 132			# store direction to down right
sw $t1, 8($t2)			# store direction for enemy to go in

addi $a0, $zero, 1		# Set to colour enemy
jal DrawEnemy			# pass in array for enemy $t2, 0 for erase, 1 for draw

addi $s2, $s2, 12		# increase by 3 array locations
j EnemyLoop

EndEnemyLoop:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra


DrawEnemy:
beq $a0, 0, Erase
beq $a0, 1, Draw
Erase:
la $s0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
lw $t1, 4($s0)		# Load bg colour to erase
j StartDraw
Draw:
lw $t1, 4($t2)		# Load colour of doodler
StartDraw:
lw $t3, 0($t2)		# Load display address from enemy array location
sw $t1, 0($t3)		# Paint enemy in first loc
sw $t1, 132($t3)		# Paint enemy in first loc
sw $t1, 128($t3)		# Paint enemy in first loc
sw $t1, 124($t3)		# Paint enemy in first loc
sw $t1, 252($t3)		# Paint enemy in first loc
sw $t1, 248($t3)		# Paint enemy in first loc
jr $ra
EndDrawEnemy:


MoveEnemies:
addi $sp, $sp, -4
sw $ra, 0($sp)		# save return address

la $s0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
lw $t0, 12($s0)		# Load maximum number of enemies to use
li $t1, 12		# Multiply by length of 3 address locations
mult $t0, $t1
mflo $t0			# Maximum location in array to access

addi $s2, $zero, 0	# Initialize counter
la $s1, enemyLocations	# Array to store the display addresses of at most 2 enemies + their colours + direction (2 x 2 x 4)

EnemyLoop2:
beq $s2, $t0, EndEnemyLoop2
add $t2, $s1, $s2	# Set to the appropriate enemy's array location

lw $t3, 0($t2)		# load display address of enemy
lw $t4, 4($t2)		# load colour of enemy
lw $t5, 8($t2)		# load direction of enemy

li $a0, 0		# Erase using bg colour
jal DrawEnemy

li $v0, 42
li $a0, 0
li $a1 14		# Maximum value for randomiser to give
syscall
beq $t0, 12, slowMode	# Level 2 enemies move slower
beq $t0, 24, fastMode	# move faster in level 3
slowMode: li $a1, 3	# moves when value less than 3
j checkFreeze
fastMode: li $a1, 7	# moves when value less than 7
checkFreeze:
blt $a0, $a1, unfreeze	# If number less then move enemy
li $t5, 0		# initialize direction to 0 (doesn't move)

unfreeze:
add $a1, $zero, $a0
add $t3, $t3, $t5	# Move in specified direction
sw $t3, 0($t2)		# Store new location of enemy
li $a0, 1		# Redraw
jal DrawEnemy

bne $a1, 0, skipDirChange # If 0 then change direction
li $v0, 42
li $a0, 0
li $a1 4
syscall

beq $a0, 0, downRight
beq $a0, 1, downLeft
beq $a0, 2, upRight
beq $a0, 3, upLeft
#beq $a0, 4, disappear
downRight:
li $t5, 132
j ChangeDir
downLeft:
li $t5, 124
j ChangeDir
upRight:
li $t5, -124
j ChangeDir
upLeft:
li $t5, -132
j ChangeDir
#disappear:
#li $t5, 0
#la $t1, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
#lw $t1, 4($t1)		# Load bg colour
#sw $t1, 4($t2)
#j ChangeDir

ChangeDir: sw $t5, 8($t2)	# store direction of enemy

skipDirChange:
lw $t5, 8($t2)			# get direction and add to current location
add $t8, $t3, $t5

lw $t6, topRight			# If enemy reaches top of screen, change direction so it doesn't go off map
ble $t8, $t6, downRight		# If next movement give invalid location, change direction

addi $t8, $t3, 384		# Get location of bottom of enemy
add $t8, $t8, $t5		# If goes off screen, change direction back up

lw $t7, bottomLeft
bge $t8, $t7, upLeft

skipDraw:
addi $s2, $s2, 12		# Get next enemy
j EnemyLoop2

EndEnemyLoop2:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra


GetMaxNumPlatforms:	# returns maximum location in platform array to stop at in loops
la $s0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
lw $t0, 8($s0)		# Load maximum number of platforms to use
li $t1, 8		# Multiply by length of 2 address locations
mult $t0, $t1
mflo $t7
addi $sp, $sp, -4
sw $t7, 0($sp)		# Save result in stack
jr $ra


RecolourPlatforms:
addi $sp, $sp, -4
sw $ra, 0($sp)		# Save address in stack

addi $sp, $sp, -4
sw $a1, 0($sp)		# Save parameter which stores colour to use
addi $sp, $sp, -4
sw $a0, 0($sp)		# Save parameter which stores randomize method

jal GetMaxNumPlatforms
lw $t7, 0($sp)		# Load result in stack
addi $sp, $sp, 4

addi $s1, $zero, 0	# index for platform array
Rand:
beq $s1, $t7, EndRand		# While all platforms not randomized (3 x 4)
	la $t3, platformLocations# Array to store the display addresses of at most 6 platforms + their colours (2 x 6 x 4)

	add $t4, $t3, $s1	# Set $t4 to point to address which will hold this platform's location
	lw $a0, 0($sp)		# Load from stack
	lw $v1, 0($t4)		# Load location stored in $t4

	bne $a0, 3, continueRand	# If set to shift down and the space below is out of bounds don't branch
	lw $t3, bottomLeft
	blt $v1, $t3, continueRand	# If location is after bottom left corner then regenerate new platform at now after erased
	addi $a0, $zero, 1	# Set to 1 for new random platform from the top
	#li $s3, 1
	
	continueRand:
	jal RandomPlatformLoc	# Generate random platform location (Returns new location)
	lw $t6, 0($sp)		# Load type of platform, -1 stay, 0-3 for new type
	addi $sp, $sp, 4
	lw $s2, 0($sp)		# Load new platform location from stack
	addi $sp, $sp, 4	
	
	sw $s2, 0($t4)		# Store new location into array
	
	SamePlat:  beq $t6, -1, SkipType
	Plat1: bne $t6, 0, Plat2
		lw $s2, platformColourNormal
		j SetType
	Plat2: bne $t6, 1, Plat3
		lw $s2, platformColourBounce
		j SetType
	Plat3: bne $t6, 2, Plat4
		lw $s2, platformColourBreak
		j SetType
	Plat4: bne $t6, 3, Plat0
		lw $s2, platformColourMove
		j SetType
	Plat0: bne $t6, 4, SamePlat	# When a grey platform is broken...
		la $s0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
		lw $s2, 4($s0)		# Get background colour
		j SetType
	SetType: sw $s2, 4($t4)		# Store location into array
	
	SkipType:
	# Input 
	lw $a1, 4($sp)			# Load 1 to draw, 0 to erase
	beq $a1, 1, drawplat
	eraseplat:
		la $s0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
		lw $t1, 4($s0)		# get bg colour
		j DrawPlatform
	drawplat:
		lw $t1, 4($t4)		# get platform's colour
	
	DrawPlatform:		# Start drawing new platform
	addi $s0, $zero, 0
	lw $s2, 0($t4)		# Load new display address
	DrawPlatformLoop:
	beq $s0, 10, StopDrawing	# While entire platform's not drawn (10 spaces)
		sw $t1, 0($s2)
		addi $s2, $s2, 4
		addi $s0, $s0, 1
	j DrawPlatformLoop
	StopDrawing:
addi $s1, $s1, 8		# Increase index of platform array / draw next platform
j Rand
EndRand:
addi $sp, $sp, 4		# pop
addi $sp, $sp, 4		# pop

lw $ra, 0($sp)
addi $sp, $sp, 4		# Restore return address
jr $ra


RandomPlatHorizontal:
li $v0, 42		# Set randomizer system call
li $a0, 0		# Stores the randomized number
li $a1, 21		# Choose a random number within 10 spaces from the right
syscall
li $v1, 4		# Initialize to 4
mult $a0, $v1		# Multiply value by 4
mflo $v0
jr $ra

RandomPlatVertical:
li $v0, 42
li $a0, 0
li $a1, 6		# Choose a random number up to 7
syscall
li $v1, 4		# Initialize to 3
mult $a0, $v1		
mflo $a0
addi $a0, $a0, 6
li $v1, 128		# Initialize to 128
mult $a0, $v1		# Multiply by vertical value to move location downwards
mflo $v0
jr $ra

RandomPlatType:		# Returns 0 for Normal, 1 Bounce, 2 Break, 3 Move
la $t8, currentLevel
lw $t8, 0($t8)		# Get level number (1-3)
addi $t8, $t8, 1		# Increase by one to determine the range of platforms possible (2-4)
li $v0, 42
li $a0, 0
add $a1, $zero, $t8	# Set max val for platform type
syscall
add $v0, $zero, $a0
jr $ra


RandomPlatformLoc:	# Takes in $a0, if 0 then no randomize, 1 then only hori, 2 then randomize both, 3 then shift down
addi $sp, $sp, -4	# Also takes in $v1 with current platform location
sw $ra, 0($sp)

bne $a0, 3, skipShift
addi $v1, $v1, 128	# Move platform address down
j returnPlatAddress

skipShift:
bne $a0, 0, Randomize
j returnPlatAddress

Randomize:
lw $v1, topLeft		# Platform intially set to first display address
# Randomize Horizontal
addi $sp, $sp, -4
sw $a0, 0($sp)		# store randomize function
addi $sp, $sp, -4
sw $v1, 0($sp)		# store shift downward amount
jal RandomPlatHorizontal
lw $v1, 0($sp)		# restore shift
addi $sp, $sp, 4
lw $a0, 0($sp)		# restore randomize
addi $sp, $sp, 4	
add $v1, $v1, $v0	# Add horizontal value to platform address

# Randomize Vertical
beq $a0, 1, returnPlatAddress
addi $sp, $sp, -4
sw $a0, 0($sp) 
addi $sp, $sp, -4
sw $v1, 0($sp) 
jal RandomPlatVertical
lw $v1, 0($sp)
addi $sp, $sp, 4
lw $a0, 0($sp) 
addi $sp, $sp, 4	
add $v1, $v1, $v0	# Add vertical value to platform address

returnPlatAddress:
# Randomize Colour and Type
beq $a0, 0, skipColour	# If platform is not being randomized skip new type
beq $a0, 3, skipColour	# If platform is shifted downwards keep old type
addi $sp, $sp, -4
sw $v1, 0($sp)		# Store current platform address
jal RandomPlatType	# returns $v0 with new type
lw $v1, 0($sp)		# Reload address
addi $sp, $sp, 4
j returnPlatInfo

skipColour:
addi $v0, $zero, -1	# return platform type as -1 (indicating that type stays as it was before)

returnPlatInfo:
lw $ra, 0($sp)
addi $sp, $sp, 4		# restore return address
addi $sp, $sp, -4
sw $v1, 0($sp)		# Store new platform address to stack

addi $sp, $sp, -4
sw $v0, 0($sp)		# Store platform type indicator to stack

jr $ra			# Return to last caller function
EndRandomPlatform:


ShiftPlatforms:
addi $sp, $sp, -4
sw $ra, 0($sp)		# Save address

addi $a0, $zero, 0	# Keep previous platform values
addi $a1, $zero, 0	# Erase
jal RecolourPlatforms

addi $a0, $zero, 3	# Shift platform values down
addi $a1, $zero, 1	# Colour them
jal RecolourPlatforms

DeleteGround:
la $s0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
lw $s6, 16($s0)
lw $t9, 4($s0)
beq $s6, 0, SkipGroundErase	# 1 means new level so remove ground, skip if 0
lw $t2, bottomLeft
li $s2, 992
DelLoop:
beq $s2, 1024, EndDelLoop 	# erase ground from bottom of beginning screen
addi $t8, $t9, 0
sw $t8, 0($t2)
addi $t2, $t2, 4		# Go to next display address
addi $s2, $s2, 1		# Increment pixel counter
j DelLoop
EndDelLoop:
li $s6, 0
sw $s6, 16($s0)
SkipGroundErase:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra


GetDoodler:		# Return array for the specified doodler (1 or 2)
beq $a0, 1, Char1.2
beq $a0, 2, Char2.2
Char1.2: 
	la $v0, doodlerCharacter1
	j EndCharSelect2
Char2.2: 
	la $v0, doodlerCharacter2
EndCharSelect2:
jr $ra


FallDoodler:		# Takes in $a0 which stores the Doodler's ID number (1 or 2)
addi $sp, $sp, -4
sw $ra, 0($sp)		# Save return address in stack
jal GetDoodler		# Pass in $a0, and get $v0 (doodler array) in return

lw $t3, bottomRight
lw $s2, 4($v0)		# Display address stored for first bottom piece of doodler
addi $s2, $s2, 128	# Shift display address to the one below
bgt $s2, $t3, SetToLose	# If doodler falls off screen, set this Doodler's status to "lost"

skipFallCheck1:
lw $t4, platformColourNormal	# Nothing extra happens
jal CheckIfToJump
lw $t4, platformColourBounce	# Doodlers jump higher... changes doodler status to 2
jal CheckIfToJump
lw $t4, platformColourBreak	# Platform breaks i.e turns invisible(copies bg colour)
jal CheckIfToJump
lw $t4, platformColourMove	# Platforms move side to side constantly
jal CheckIfToJump
lw $t4, doodlerColour1		# If jumps on another doodler, then jump, eventually one loses balance so it's not a cheat to avoid platforms
jal CheckIfToJump
lw $t4, doodlerColour2
jal CheckIfToJump
j EndJumpCheck

CheckIfToJump:
lw $s2, 44($v0)			# Load doodler's status (-1 lost, 0 fall, 1 jump, 2 double jump)
beq $s2, -1, EndJumpCheck	# If doodler lost, don't check for jump, continue to fall (Falls through platforms once killed)
# Check if left side of doodler touched something
lw $s2, 4($v0)			# Display address stored for first piece of doodler
addi $t8, $s2, 128		# Hold display address that was jumped on
lw $s2, 128($s2)			# Colour stored at that location
beq $s2, $t4, SetToJump 		# If platform of specified colour $t4 is below then jump
# Check if right side of doodler touched something
lw $s3, 12($v0)			# Display address stored for second base piece of doodler
addi $t8, $s3, 128
lw $s3, 128($s3)			# Load colour stored in location below
beq $s3, $t4, SetToJump		# If platform of specified colour $t4 is below then jump
jr $ra				# Return to outer function
EndJumpCheck:

j continueFall			# If nothing was jumped on, keep falling
EndCheck:

SetToJump:
#lw $s1, platformColourNormal	# Nothing extra happens
lw $s2, platformColourBounce	# Doodlers jump higher... #set jump distance negative
lw $s3, platformColourBreak	# Platform breaks i.e turns invisible(bg colour)
#lw $s4, platformColourMove	# Platforms move side to side or up and down

li $t5, 1
sw $t5, 48($v0)			# Initialise distance jumped to 1

beq $t4, $s2, BluePlat		# Double Jumps
beq $t4, $s3, GreyPlat		# Breaks
j SkipTypeCheck

BluePlat:
li $t5, 2		# Set doodler status to double jump
j SkipTypeCheck

GreyPlat:
addi $sp, $sp, -4
sw $v0, 0($sp)		# Save doodler array
addi $sp, $sp, -4
sw $t5, 0($sp)		# Save distance jumped

addi $sp, $sp, -4
sw $t8, 0($sp)		# Store display address to check for platforms (location jumped on)
jal BreakGreyPlatform	# Break the platform once jumped on once

lw $t5, 0($sp)		# Restore doodler array in stack
addi $sp, $sp, 4
lw $v0, 0($sp)		# Restore distance jumped in stack
addi $sp, $sp, 4

SkipTypeCheck:
sw $t5, 44($v0)		# stores 1 for jump and 2 for extra jump into array
li $v1, -128		# set direction to jump up
j returnMoveVal

SetToLose:
jal LoseDoodler
j returnMoveVal

continueFall:
li $v1, 128		# set direction to fall downwards
li $t5, 0
sw $t5, 48($v0)		# Set distance jumped to 0

returnMoveVal:
lw $ra, 0($sp)		# Restore address in stack
addi $sp, $sp, 4

addi $sp, $sp, -4
sw $v1, 0($sp)		# store direction to move in
jr $ra			# Return to main


JumpDoodler:
# Wait before jumping for first time
addi $sp, $sp, -4
sw $ra, 0($sp)		# Save address in stack
jal GetDoodler		# pass $a0, get $v0, doodler array
addi $sp, $sp, -4
sw $v0, 0($sp)		# Save doodler array in stack

lw $t4, enemyColour3		# Cuts jump short
lw $s2, 4($v0)			# Display address stored for first piece of doodler		
lw $s2, 128($s2)			# Colour stored at that location
beq $s2, $t4, SetToFall 		# If orange enemy below then fall
lw $s3, 12($v0)			# Display address stored for second base piece of doodler
lw $s3, 128($s3)			# Load colour below
beq $s3, $t4, SetToFall		# If orange creature below then fall immediately

lw $s0, 44($v0)			# Get jump status (1 normal, 2 double)
beq $s0, 2, doubleJump
beq $s0, 1, singleJump
doubleJump: li $s6, 50
j GoJump
singleJump: li $s6, 18

GoJump:
lw $s0, 48($v0)			# Get distance jumped
bge $s0, $s6, SetToFall		# Once max height is reached fall
lw $v0, 0($sp)			# Load doodler array
lw $t1, 36($v0)			# Set to position of doodler's top
lw $t3, topRight
addi $t3, $t3, 512		# Set barrier from top to start shifting platforms
bgt $t1, $t3, continueJump	# If top of doodler not at a certain level don't shift platforms

addi $s5, $zero, 0
startShift:
beq $s5, 4, endShift	# shift 4 times in one jump
jal ShiftPlatforms
addi $s5, $s5, 1
lw $v0, 0($sp)		# Restore array in stack
jal IncreaseJump		# add to doodler's jump height
li $v0, 32
li $a0, 20
syscall			# sleep between shifts
j startShift
endShift:

addi $v1, $zero, 0
j skipmove

SetToFall:
addi $t5, $zero, 0
lw $v0, 0($sp)		# Load doodler array 
sw $t5, 44($v0)		# set status to fall
sw $t5, 48($v0)		# reset distance jumped to 0
li $v1, 128		# set direction to up
j skipmove

continueJump:
li $v1, -128		# keep direction down

skipmove:
lw $v0, 0($sp)		# Restore array address in stack
addi $sp, $sp, 4
jal IncreaseJump
lw $ra, 0($sp)		# Restore return address in stack
addi $sp, $sp, 4

addi $sp, $sp, -4
sw $v1, 0($sp)		# Store direction to move
jr $ra			# Return to main


IncreaseJump: 		# Receives $v0 and increases that doodler's jump by 1
lw $s7, 48($v0)
addi $s7, $s7, 1
sw $s7, 48($v0)
jr $ra


MoveGreenPlatform:	# Shifts green platforms left to right
addi $sp, $sp, -4
sw $ra, 0($sp)		# Save return address

la $t3, platformLocations	# Load Array that stores the display addresses of at most 6 platforms + their colours (2 x 6 x 4)
jal GetMaxNumPlatforms
lw $t7, 0($sp)		# Save max number in stack
addi $sp, $sp, 4

addi $s1, $zero, 0	# Initialize platform counter to 0 (goes up by 4 for every platform)
GreenCheckLoop:
lw $s0, platformColourMove	# Get colour for moving platform
beq $s1, $t7, EndCheck3	# While all platforms are not checked (#platforms x 4)
	add $t4, $t3, $s1	# Set current array location of the current platform
	lw $s3, 0($t4)		# Load platform's first display address
	lw $s2, 4($t4)		# Load colour of platform
	bne $s2, $s0, checkNext3	# if colour doesnt match, check next platform

	eraseplat2:		# erase platform
	la $s0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
	lw $t1, 4($s0)		# get background colour to erase
	addi $s0, $zero, 0
	lw $s2, 0($t4)		# Load initial display address
	ErasePlatformLoop:
	beq $s0, 10, StopErase	# While entire platform's not erased
		sw $t1, 0($s2)
		addi $s2, $s2, 4
		addi $s0, $s0, 1
	j ErasePlatformLoop
	StopErase:

	lw $t6, topLeft
	sub $t6, $s3, $t6	# Get the distance from the inital display address
	li $s4, 128
	div $t6, $s4		# divide by 128, remainder 0 means far left, remainder 127 far right so rem larger than 118
	mfhi $t6
	
	la $s4, movePlatformDirection	# Stores -4 to go left, 4 to go right
	beq $t6, 0, MoveRight		# move right when a platform hits the left edge
	bge $t6, 84, MoveLeft		# move left when a platform hits the right edge
	j FinishMoving
	
	MoveRight:
	addi $s5, $zero, 4	# Add 4 to original address to shift
	sw $s5, 0($s4)
	j FinishMoving
	
	MoveLeft:
	addi $s5, $zero, -4	# Add -4 to original address to shift
	sw $s5, 0($s4)
	
	FinishMoving:
	la $s4, movePlatformDirection
	lw $s5, 0($s4)		# get direction platform moves in
	add $s3, $s3, $s5 	# add to initial location
	sw $s3, 0($t4)		# Store new location into array (shifted by 4 or -4 depending on distance from edge)
	
	checkNext3:
	drawplat2:		# draw platform
	lw $t1, 4($t4)
	addi $s0, $zero, 0
	lw $s2, 0($t4)		# Load new display address
	ErasePlatformLoop2:
	beq $s0, 10, StopErase2	# While entire platform is not drawn
		sw $t1, 0($s2)
		addi $s2, $s2, 4
		addi $s0, $s0, 1
	j ErasePlatformLoop2
	StopErase2:
addi $s1, $s1, 8			# increase array index
j GreenCheckLoop
EndCheck3:

li $v0, 32
li $a0, 20		# sleep between shifts
syscall

lw $ra, 0($sp)		# Save return address
addi $sp, $sp, 4
jr $ra
	

BreakGreyPlatform:
lw $t8, 0($sp)		# Store display address to check for platforms
addi $sp, $sp, 4

addi $sp, $sp, -4
sw $ra, 0($sp)		# Save return address

addi $sp, $sp, -4
sw $t8, 0($sp)		# send display address of doodler
jal RunPlatCheck		# Returns array location of platform
lw $t4, 0($sp)
addi $sp, $sp, 4

addi $a0, $zero, 0	# Keep previous platform values
addi $a1, $zero, 1	# Recolour
jal RecolourPlatforms

lw $ra, 0($sp)		# Save return address
addi $sp, $sp, 4
jr $ra

RunPlatCheck:		# Takes in a location of doodler that landed on platform
# Load Arguments
lw $a0, 0($sp)		# Load display address to check for platforms
addi $sp, $sp, 4		# Move stack pointer to pop stack

addi $sp, $sp, -4	# move stack pointer to push stack
sw $ra, 0($sp)		# Save return address before calling another function

la $t3, platformLocations	# Load Array that stores the display addresses of at most 6 platforms + their colours (2 x 6 x 4)
jal GetMaxNumPlatforms
lw $t7, 0($sp)		# Save result in stack
addi $sp, $sp, 4

addi $s1, $zero, 0	# Initialize platform counter to 0 (goes up by 4 for every platform)
PlatCheckLoop:
beq $s1, $t7, EndCheck2	# While all platforms are not checked (#platforms x 4)
	add $t4, $t3, $s1	# Set current array location (current platform)
	lw $s2, 0($t4)		# Load platform's first display address
	blt $a0, $s2, checkNext2	# continue if on or after the platform
	addi $s2, $s2, 40	# load last display address of platform
	bgt $a0, $s2, checkNext2	# addresses are 10 spaces long # 0 4 8 12 16 | 20 24 28 36 40
	lw $s3, platformColourBreak	# Platform breaks i.e turns invisible(bg colour)
	lw $s4, 4($t4)		# Get platform's colour
	bne $s3, $s4, checkNext2	# if not breakable, skip
	la $s0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
	lw $s2, 4($s0)
	sw $s2, 4($t4)		# erase platform $t4 underneath doodler that is grey
	checkNext2:		
	addi $s1, $s1, 8		# increase array index
j PlatCheckLoop
EndCheck2:
lw $ra, 0($sp)		# Store return address
addi $sp, $sp, 4
addi $sp, $sp, -4
sw $t4, 0($sp)		# Save array location of platform below
jr $ra


# Takes in $v1 which stores location displacement i.e 128, -4, -128, 4
MoveDoodler:		# Function which erases, updates position and redraws doodler
addi $s0, $zero, 44	# Location to stop at in loop (range that holds piece locations
addi $s1, $zero, 4	# Initialize Array Index to 2nd location

addi $sp, $sp, -4
sw $ra, 0($sp)		# Save return address

# Get address of Array stored in $v0
# Array stores 1+10 slots, 1 for doodler colour, 5 for character pieces' location, 5 for bg colours

lw $t1, 48($v0)		# Get distance jumped or 0 if falling
bne $t1, 1, EndRest	# If doodler landed and goes to jump, pause for a bit
lw $t1, 44($v0)		# Get status: jumped, fell, lost
beq $t1, 0, EndRest	# If doodler is falling do not pause longer

Rest:
addi $sp, $sp, -4
sw $v0, 0($sp)
li $v0, 32
li $a0, 200
syscall
lw $v0, 0($sp)
addi $sp, $sp, 4
EndRest:

MoveLoop:	#take in $v1, direction, and $v0 doodler array
beq $s1, $s0, EndMoveLoop	# While all pieces of doodler are not drawn
	add $t2, $v0, $s1	# Set $t2 to point to address which will hold this piece's location

	# Erase doodler and repaint appropriate background
	lw $a1, 0($t2)			# Set $a1 to current address of this character piece
	lw $a0, 0($a1)			# Load colour currently at pieces' location	
	lw $t1, doodlerColour1		# Get doodler's colour
	bne $a0, $t1, checkNext	# If current colour is not the doodler's colour then keep colour (new object was drawn over doodler so background changes)
	j initial
	checkNext:
		lw $t1, doodlerColour2
		bne $a0, $t1, drawbg
	initial: lw $a0, 4($t2)		# Set colour to the last displaced bg colour
	drawbg: jal DrawPixel		# Input colour $a0 and location $a1
	
	# Update location and colour attributes
	add $a1, $a1, $v1	# Move current location by value in $v0 (128 down, -128 up, -4 left, 4 right)
	sw $a1, 0($t2)		# Store new location into array
	lw $t4, 0($a1)		# Get colour of background space before recoloured
	sw $t4, 4($t2)		# Store displaced background colour in array location after
	lw $t8, enemyColour3
	bne $t4, $t8, notstopped	# If jumps onto an orange enemy, it falls
	li $t5, 0
	sw $t5, 44($v0)		# Set to 0 to fall
	sw $t5, 48($v0)		# Set distance jumped to 0
	notstopped:		# no enemy
	lw $t8, enemyColour2
	bne $t4, $t8, notkilled	# if touches grey enemy lose
	jal LoseDoodler
	notkilled:
	# Repaint in new location
	lw $a0, 0($v0)		# Get doodler's colour
	lw $a1, 0($t2)
	jal DrawPixel		# Input colour $a0 and location $a1 
	addi $s1, $s1, 8		# Increase index of platform array by 2 addresses
j MoveLoop
EndMoveLoop:
	
li $v0, 32		# Sleep
li $a0, 20
syscall

lw $ra, 0($sp)		# Load return address
addi $sp, $sp, 4
jr $ra
EndMoveDoodler:

LoseDoodler:
li $t5, -1
sw $t5, 44($v0)		# Set doodler's status to -1 for lost
sw $t5, 48($v0)		# Set distance jumped to -1
li $v1, 0		# Return direction to move in next
# Erase Doodle once it loses
la $t0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
lw $t1, 4($t0)		# Get associated background colour
sw $t1, 0($v0)
jr $ra
EndLose:


# Drawing Characters to the Screen
Write_R:
add $t0, $zero, $a0
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
sw $s1, 0($t0)
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 8
sw $s1, 0($t0)
jr $ra

Write_E:
add $t0, $zero, $a0
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

jr $ra

Write_T:
add $t0, $zero, $a0
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
addi $t0, $t0, 8
sw $s1, 0($t0)

jr $ra

Write_Y:
add $t0, $zero, $a0
sw $s1, 0($t0)
addi $t0, $t0, 16
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
addi $t0, $t0, 8
sw $s1, 0($t0)
jr $ra

Write_B:
add $t0, $zero, $a0
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
sw $s1, 0($t0)
addi $t0, $t0, 12
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

jr $ra


Write_exc:
add $t0, $zero, $a0
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)

jr $ra


Write_S:
add $t0, $zero, $a0
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
jr $ra


Write_A:
add $t0, $zero, $a0
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
sw $s1, 0($t0)
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
sw $s1, 0($t0)
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 8
sw $s1, 0($t0)
jr $ra

Write_L:
add $t0, $zero, $a0
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
jr $ra

# Draw numbers
Write_1:
add $t0, $zero, $a0
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
jr $ra

Write_2:
add $t0, $zero, $a0
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
jr $ra

Write_3:
add $t0, $zero, $a0
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 128
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 128
addi $t0, $t0, 8
sw $s1, 0($t0)

add $t0, $zero, $a0
addi $t0, $t0, 256
addi $t0, $t0, 256
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
addi $t0, $t0, 4
sw $s1, 0($t0)
jr $ra

# Draw words to the screen
DrawRetry:
addi $sp, $sp, -4
sw $ra, 0($sp)
lw $s1, doodlerColour1		# Set word colour
lw $a0, topLeft
add $a0, $a0, 1300		# Set position
jal Write_R
addi $a0, $a0, 16
jal Write_E
addi $a0, $a0, 16
jal Write_T
addi $a0, $a0, 24
jal Write_R
addi $a0, $a0, 16
jal Write_Y
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

DrawBye:
addi $sp, $sp, -4
sw $ra, 0($sp)
lw $s1, doodlerColour1		# Set word colour
lw $a0, topLeft
add $a0, $a0, 1692		# set position
jal Write_B
addi $a0, $a0, 20
jal Write_Y
addi $a0, $a0, 24
jal Write_E
addi $a0, $a0, 20
jal Write_exc
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

DrawStart:
addi $sp, $sp, -4
sw $ra, 0($sp)
lw $s1, platformColourBounce	# Set word colour
lw $a0, topLeft
add $a0, $a0, 2192		# Set screen location
jal Write_S
addi $a0, $a0, 16
jal Write_T
addi $a0, $a0, 24
jal Write_A
addi $a0, $a0, 20
jal Write_R
addi $a0, $a0, 16
jal Write_T
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

DrawLvl:
addi $sp, $sp, -4
sw $ra, 0($sp)
lw $s1, platformColourNormal	# Set colour of level number to display
lw $a0, topLeft
add $a0, $a0, 1200		# Set starting location to write (2728 + 20)
jal Write_L
addi $a0, $a0, 20
la $a1, currentLevel
lw $a1, 0($a1)			# Get level number
beq $a1, 1, draw1
beq $a1, 2, draw2
beq $a1, 3, draw3
draw1: jal Write_1
	j writenum
draw2: jal Write_2
	j writenum
draw3: jal Write_3
writenum:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

EndGame:
jal DrawMap
jal DrawRetry
End:
jal ShiftDoodlerInput
j End

Exit:
la $t0, currentLevel	# Stores level number, background colour, # platforms, # enemies, flag for new level (5 x 4)
lw $t1, enemyColour1
sw $t1, 4($t0)		# Store associated background colour
jal DrawMap
jal DrawBye
