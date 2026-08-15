; Serpentine for the Commodore Vic20

;--------------------------------------------------------------------------------------------------
; System addresses

; _BITMAP_GRID is the video matrix, the physical screen memory area. The VIC chip reads this via DMA
; to layout the screen coordinate grid. In this bitmap configuration, holds a fixed, sequential array
; of character index numbers ($00, $01, $02...) populated in initialise_bitmap_grid_index.
_BITMAP_GRID = $0200  ;512

; _BITMAP_CANVAS is the character generator RAM and provides the memory area of the bitmap canvas.
; Changing bytes here alters the 8-byte pixel blocks assigned to screen tiles, and is used to plot 
; shapes and sprites in plot_bitmap_on_screen, erase_bitmap_on_screen and other routines.
_BITMAP_CANVAS = $1000  ;4096

_COLOUR_SCREEN_ADDR = $9600  ;38400

_VIC_SCREEN_LEFT_EDGE = $9000  ;36864 left edge of TV picture
_VIC_SCREEN_TOP_EDGE  = $9001  ;36865 vertical TV picture origin
_VIC_SOUND_BASS       = $900a  ;36874 audio frequency generator 1
_VIC_SOUND_ALTO       = $900b  ;36875 audio frequency generator 2
_VIC_SOUND_SOPRANO    = $900c  ;36876 audio frequency generator 3
_VIC_VOLUME           = $900e  ;36878 sound volume (and auxiliary colour not used here)
_VIC_IRQ_ENABLE       = $911e  ;37150 interrupt enable register

_VIA_JOYSTICK_MIRROR  = $911f  ;37151 mirror of $9111 (37137) port A I/O register
_VIA_KEYB_ROWS        = $9120  ;37152 port B I/O register
_VIA_DATADIR_B        = $9122  ;37154 data direction register for port B

;--------------------------------------------------------------------------------------------------
; Joystick constants

JOY_RIGHT = 1
JOY_UP = 2
JOY_DOWN = 4
JOY_LEFT = 8
JOY_FIRE = 16

;--------------------------------------------------------------------------------------------------
; Snake direction constants

DIRECTION_UP = 1
DIRECTION_DOWN = 2
DIRECTION_RIGHT = 3
DIRECTION_LEFT = 4

;--------------------------------------------------------------------------------------------------
; Sound voice constants

SOUND_BASS = 1
SOUND_ALTO = 2
SOUND_SOPRANO = 3
SOUND_NOISE = 4

;--------------------------------------------------------------------------------------------------
; Maze part constants

WALL_SINGLE_GREEN_SQUARE = 0  ;"single green square"
WALL_HORIZONTAL = 1  ;"horizontal wall section with green square on left" and "horizontal wall section"
WALL_VERTICAL = 2  ;"vertical wall section with green spare on top" and "vertical wall section"
WALL_VERTICAL_AND_HORIZONTAL = 3  ;the two above combined

;--------------------------------------------------------------------------------------------------
; Other constants

column_spacing = 176  ;each column is 176 pixels apart (11 rows x 16-pixels tall), see _VIC_CR3

;--------------------------------------------------------------------------------------------------
; Zero page addresses

bitmap_screen_address_low  = $00
bitmap_screen_address_high = $01

bitmap_bit_shift = $02  ;is the horizontal bit shift amount (0–7)
bitmap_spill_bits = $03  ;holds the "spill" bits to be written into the next screen byte when a sprite crosses an 8-bit boundary

temp_snake_data_pointer1 = $05  ;variable for player or enemy snake data table pointer
temp_snake_data_pointer2 = $06  ;variable for player or enemy snake data table pointer often segments

body_segments = $07  ;value of snake body segments counting the head as a segment
snake_colour = $08  ;colour 0: player snake, 1: dangerous enemy snake, 2: weak enemy snake
desired_snake_direction = $09  ;is the planned direction
snake_in_home_or_maze = $0a  ;initially #128 (ready to leave home), #255 (reached home), #0 (left home, in maze)
snake_active_indicator = $0b
pending_direction_change = $0c  ;is the in-flight transition between the desired_snake_direction and current_segment_direction
screen_coords_table = $0d  ;$0d (current_segment_direction), $0e (screen_column), $0f (screen_row)
current_segment_direction = $0d  ;(dual use label) is the direction actually being used for this segment
maze_part_to_plot = $0d  ;dual use label

screen_column = $0e
screen_row = $0f

pixel_data_low = $10
pixel_data_high = $11

temp1 = $12

maze_cell_boundary_flag = $13  ;bit7 = 0 when snake head is aligned to a maze cell boundary, 1 otherwise
snake_direction_pointer_to_test = $14  ;0, 1, 2, 3 for checking if snake / segment direction is allowed
maze_address_low = $15
maze_address_high = $16
maze_index = $17

player_lives = $18
maze_level = $19

player_snake_speed_reload = $1a
player_snake_speed_counter = $1b
enemy_snake_speed_reload = $1c
enemy_snake_speed_counter = $1d
snake_data_pointer = $1e  ;pointer to data in player_and_enemy_table
game_speed_counter = $1f

egg_countdown_low  = $20
egg_countdown_high = $21

enemy_egg_location_column = $23
enemy_egg_location_row = $24
enemy_egg_status = $25  ;0 (no egg), 1 (develop egg), 2 (lay egg), 3 (hatchable egg)
enemy_snake_with_egg = $26  ;0, 1, 2, 3 a pointer to snake developing or has laid an egg
reincarnate_dead_snake_with_egg = $27  ;0, 1, 2, 3 pointer to dead snake which can have a replacement egg laid for it

player_egg_location_column = $2b
player_egg_location_row = $2c
player_egg_status = $2d  ;0 (no egg), 1 (develop egg), 2 (lay egg), 3 (hatchable egg)

snake_tick_table = $2e  ;game tick counter for when snakes can do things
snake_tick_table_word = $002e  ;as above

frog_display = $40
frog_location_column = $41
frog_location_row = $42
frog_location_column_word = $0041
frog_display_duration = $43

snake_index = $4e  ;0, 1, 2
scroll_message_index = $46
scroll_X_position = $47
sound_loop_counter = $48
end_loop_counter = $49

score_for_eat_snake_head = $4a
score_for_eat_snake_body = $4b
score_for_eat_egg_low = $4c
score_for_eat_egg_high = $4d

new_last_segment_pointer = $50  ;dual use label, points to the segment data for an added new segment
temp2 = $50  ;dual use label
temp3 = $51
temp4 = $52
data_index = $5c

sound_hiss_counter = $53
player_score = $54  ;3 bytes $54, $55, $56
high_score = $57  ;3 bytes $57, $58, $59
text_data_low = $5d
text_data_high = $5e

sound_data_low = $5f
sound_data_high = $60
zero_digit_control_flag = $62  ;use to check if a score digit is zero to suppress a leading zero in score
sound_clip_data_pointer_for_channel = $63  ;$63 to $66 is the sound clip data pointer per sound channel
sound_clip_duration_for_channel = $68  ;$68 to $6b is the sound duration per sound channel
sound_clip_address_low = $6d  ;low address for sound clip data
sound_clip_address_high = $72  ;high address for sound clip data

player_and_enemy_table = $80  ;table where player and enemy snake data is held
player_and_enemy_table_word = $0080  ;table where player and enemy snake data is held (alternate reference)
enemy_snake_table = $80  ;table where enemy snake data is held (used to indicate enemy snake only)
player_body_segments = $80  ;number of body segments
player_snake_direction = $82  ;direction indicator

snake_1_body_segments = $9f  ;number of body segments
snake_2_body_segments = $bd  ;number of body segments
snake_3_body_segments = $db  ;number of body segments

;--------------------------------------------------------------------------------------------------
; Other storage addresses

scroll_message_store = $0100  ;starting address of the scrolling message text (holds 20 characters)

;--------------------------------------------------------------------------------------------------
; Start program, game was originally a cartridge so no basic loader

* = $a000
    ; auto start the program
	!byte <start_of_program  ;cold start vector (low)
	!byte >start_of_program  ;cold start vector (high)
	!byte <start_of_program  ;warm / reset start vector (low)
	!byte >start_of_program  ;warm / reset start vector (high)
    !pet "a0CBM"  ;start of signature a0CBM

;--------------------------------------------------------------------------------------------------
; Player snake table, data is saved in zero page $80 +
; See references to zero page data for each snake in player_and_enemy_table, player_and_enemy_table_word

data_player_snake_for_zero_page
    !byte $03  ;player_body_segments
	!byte $00  ;snake colour number: 0 is blue
	!byte $00  ;snake direction
	!byte $80  ;snake in home or maze: #128 (ready to leave home), #255 (reached home), #0 (left home, in maze)
	!byte $80  ;snake active indicator

    ; snake segment direction, screen column, screen row
    !byte DIRECTION_UP, 166, 134  ;head
	!byte DIRECTION_UP, 166, 142  ;body segments ...
	!byte DIRECTION_UP, 166, 150
	!byte DIRECTION_UP, 166, 158
	!byte DIRECTION_RIGHT, 166, 166
	!byte DIRECTION_RIGHT, 158, 166

    !byte $aa, $aa, $aa, $aa, $aa, $aa, $aa

;--------------------------------------------------------------------------------------------------
; Enemy snake table for each snake, data is saved in zero page locations
; $9e + for snake 1, $bc + for snake 2, $da + for snake 3
; See references to zero page data for each snake in player_and_enemy_table, player_and_enemy_table_word

data_enemy_snake_for_zero_page
    !byte $3c  ;60 delay for snake to enter cave

    ; enemy snake table starts here
	!byte $06  ;$9f number of enemy snake body segments
	!byte $01  ;snake colour number, 1: dangerous enemy snake, 2: weak enemy snake
	!byte $00  ;snake direction
	!byte $80  ;snake in home or maze: #128 (ready to leave home), #255 (reached home), #0 (left home, in maze)
	!byte $80  ;snake active indicator

    ; snake segment direction, screen column, screen row
	!byte DIRECTION_UP, 6, 118  ;head
	!byte DIRECTION_UP, 6, 126  ;body
	!byte DIRECTION_UP, 6, 134
	!byte DIRECTION_UP, 6, 142
	!byte DIRECTION_UP, 6, 150
	!byte DIRECTION_UP, 6, 158

    !byte $aa, $aa, $aa, $aa, $aa, $aa

;--------------------------------------------------------------------------------------------------

start_of_program

    ; set initial system state and registers
	sei
	lda #2  ;disable restore key interrupt
	sta _VIC_IRQ_ENABLE
	jsr initialise_system_registers

    ; perform start of game actions
	lda #1
	sta maze_level
	jsr zero_player_and_high_score
	jsr initialise_pseudo_random_values
	jsr display_opening_title_screen

start_game_play

	jsr clear_all_sound_channels
	jsr set_screen_base_colours
	jsr initialise_bitmap_grid_index  ;is unnecessary to call this routine again
	jsr check_for_new_high_score
	ldx #3
	stx player_lives
	stx player_body_segments
	dex
	stx $5a
	jsr zero_player_score
	lda #1
	sta maze_level

;--------------------------------------------------------------------------------------------------

play_one_life

	ldx #247
	txs
	jsr clear_all_sound_channels
	jsr clear_egg_variables
	jsr clear_screen_and_add_heading_block
	jsr initialise_zero_page
	jsr draw_maze_on_screen
	jsr plot_level_and_headings_on_screen
	jsr plot_high_score_on_screen
	jsr plot_player_score_on_screen
	jsr plot_player_lives_on_screen
	jsr calculate_score_values_for_maze
	jsr set_frog_to_display_on_screen
	jsr plot_player_snake_and_open_entrance_door
	jsr set_enemy_snake_start_position
	jsr play_about_to_start_maze_tune

.game_play_loop
	jsr handle_player_movement
	jsr handle_enemy_snake_movement
	jsr handle_player_and_enemy_snake_interactions
	jsr handle_player_and_enemy_snake_eggs
	jsr update_snake_tick_counters
	jsr handle_frog_actions
	jsr play_sounds
	jsr play_snake_hissing_sound
	jsr get_joystick_movement
	dec game_speed_counter  ;decrease speed counter, will cycle from 0 to 255
	bne .game_play_loop

    ; perform snake speeds controls when the game_speed_counter is zero
    ; increase enemy snake speed by increasing the reload value (higher is faster, see handle_enemy_snake_movement)
	ldx enemy_snake_speed_reload
	inx
	cpx #11
	bcs .check_player_speed_control
	stx enemy_snake_speed_reload  ;enemy snake speed reload does not exceed 10 (fastest value)

.check_player_speed_control
    ; reduce player speed by reducing the speed reload value (lower is slower, see handle_player_movement)
    ; reload values are between 14 (maze level 1) to 10 (from maze level 4) initially, but can reduce to 8
	ldx player_snake_speed_reload
	dex
	cpx #8
	bcc .game_play_loop
	stx player_snake_speed_reload  ;player snake reload speed control does not exceed 8 (slowest value)
	bcs .game_play_loop  ;always branch

;--------------------------------------------------------------------------------------------------

initialise_zero_page

	ldy #25
.init_zero_page_loop
	lda data_player_snake_for_zero_page,y
	sta player_and_enemy_table_word,y  ;initialise all from table
	dey
	bne .init_zero_page_loop

    ; assign player speed controls, slowing the player down a bit as maze level increases
	lda #10  ;8 is slowest, so 10 is quite slow
	ldx maze_level
	cpx #5  ;slower speeds from maze level 5
	bcs .store_player_speed_controls
	lda #15  ;faster speed, adjusted down by maze level
	sec
	sbc maze_level
.store_player_speed_controls
	sta player_snake_speed_counter
	sta player_snake_speed_reload

    ; assign enemy snake speed controls
	lda #4  ;10 is fastest, so 4 is quite slow
	sta enemy_snake_speed_counter
	sta enemy_snake_speed_reload

	ldx #29
	jsr .init_zero_page_group_of_30
	ldx #59
	jsr .init_zero_page_group_of_30

	ldx #89
.init_zero_page_group_of_30
	ldy #29
.init_zero_page_30_loop
	lda data_enemy_snake_for_zero_page,y
	sta player_and_enemy_table+30,x  ;initialise all from table
	dex
	dey
	bpl .init_zero_page_30_loop

	ldx #5
	lda #0
.clear_zero_page_2e_33
	sta snake_tick_table,x  ;initialise all to zero
	dex
	bpl .clear_zero_page_2e_33
	sta game_speed_counter
	rts

;--------------------------------------------------------------------------------------------------

	ldy #1
delay_using_Y
	txa
	pha
.delay_Y_loop
    ldx #194
.delay_X_loop
    dex
	bne .delay_X_loop
	dey
	bne .delay_Y_loop
	pla
	tax
	rts

;--------------------------------------------------------------------------------------------------

direction_list
	!byte JOY_UP, JOY_DOWN, JOY_RIGHT, JOY_LEFT, JOY_FIRE

;--------------------------------------------------------------------------------------------------

get_joystick_movement

	jsr read_joystick
	bcs .no_joystick_action
	cmp #JOY_FIRE
	bne .joy_movement_in_X

    ; pause game when fire is pressed
	lda _VIC_VOLUME
	tay
	and #%11110000
	sta _VIC_VOLUME
.wait_no_fire_press1
	jsr read_joystick
	cmp #JOY_FIRE
	beq .wait_no_fire_press1
.wait_no_fire_press2
	jsr read_joystick
	cmp #JOY_FIRE
	bne .wait_no_fire_press2
.wait_no_fire_press3
	jsr read_joystick
	cmp #JOY_FIRE
	beq .wait_no_fire_press3
	sty _VIC_VOLUME
.no_joystick_action
	rts
.joy_movement_in_X
	stx player_snake_direction  ;X is the direction: 1 up, 2 down, 3 right, 4 left
	rts

;--------------------------------------------------------------------------------------------------

read_joystick

	lda #127
	sta _VIA_DATADIR_B
	lda _VIA_KEYB_ROWS
	eor #255
	and #%10000000  ;isolate joystick-right direction (bit 7)
	asl  ;move bit 7 to carry
	rol  ;move carry to bit 0
	sta temp1  ;put right bit in working variable
	lda _VIA_JOYSTICK_MIRROR
	eor #255
	and #%00111100  ;isolate joystick directions and fire
	lsr  ;shift right
	ora temp1  ;add right direction, bits are not fire (16 if on), left (8 if on), down (4 if on), up (2 if on) and right (1 if on)
	beq .read_joy_set_carry_exit

    ; get a single joystick direction / fire from priority table (in case more than one at the same time e.g. up-left)
	ldx #5
.direction_loop
	cmp direction_list-1,x
	beq .read_joy_clear_carry_exit
	dex
	bne .direction_loop
.read_joy_set_carry_exit  ;no matching joystick direction
	sec
	rts

.read_joy_clear_carry_exit  ;valid joystick direction
	clc
	rts

;--------------------------------------------------------------------------------------------------

set_screen_base_colours

	ldy #242  ;11 rows x 22 columns

    ; set main game screen colour
	lda #13  ;colour green
.set_screen_base_colour_loop
	sta _COLOUR_SCREEN_ADDR-1,y
	dey
	cpy #22
	bne .set_screen_base_colour_loop

    ; set top 2 title line colour
	lda #6  ;colour blue
.set_top_base_colour_loop
	sta _COLOUR_SCREEN_ADDR-1,y
	dey
	bne .set_top_base_colour_loop
	rts

;--------------------------------------------------------------------------------------------------
; Populate the video matrix location _BITMAP_GRID ($200) with sequential index numbers, necessary
; for the VIC pseudo bitmap configuration to work.
; The index values from $0200 to $02f1 (242 entries) are:
;     1st iteration:  0, 11, 22, 33, 44 ... 231
;     2nd iteration:  1, 12, 23, 34, 45 ... 232
;     3rd iteration:  2, 13, 24, 35, 46 ... 233 onwards ...
;   final iteration: 10, 21, 32, 43, 54 ... 241
; This array only needs to be set-up once and the index values do not change.
; Despite being called twice in this program, only the first call is actually necessary.

initialise_bitmap_grid_index

	lda #0
	tay
	sta temp1
.init_bitmap_grid_index_loop

    ; starting with the value in temp1 (0, 1, 2 etc) populate the bitmap grid with values 11 apart
	ldx #22
.set_index_values_11_apart_loop
	sta _BITMAP_GRID,y

	iny
	clc
	adc #11
	dex
	bne .set_index_values_11_apart_loop

	inc temp1
	lda temp1
	cmp #11  ;11 times (starts at 0)
	bcc .init_bitmap_grid_index_loop
	rts

;--------------------------------------------------------------------------------------------------

clear_screen_and_add_heading_block

	lda #>_BITMAP_CANVAS
	ldy #<_BITMAP_CANVAS
	sta bitmap_screen_address_high
	sty bitmap_screen_address_low

	ldx #16  ;2 rows x 8-pixel space character
	ldy #0
	tya  ;clear the entire character (blank space)
.clear_one_character_loop
	sta (bitmap_screen_address_low),y
	iny
	bne .clear_one_character_loop
	inc bitmap_screen_address_high
	dex
	bne .clear_one_character_loop

    ;----------------------------------------------------------------------------------------------
    ; draw blocked out characters in the top two lines
draw_blocked_out_heading_lines

	lda #>_BITMAP_CANVAS
	ldy #<_BITMAP_CANVAS
	sta bitmap_screen_address_high
	sty bitmap_screen_address_low

	ldx #22  ;22 characters
.plot_block_characters_loop

    ; draw one heading column (2 rows x 8-pixel block-space character)
	lda #255  ;fill the entire character byte
	ldy #15
.plot_one_block_character_loop
	sta (bitmap_screen_address_low),y
	dey
	bpl .plot_one_block_character_loop

	lda bitmap_screen_address_low
	clc
	adc #column_spacing
	sta bitmap_screen_address_low
	bcc *+4  ;skip high byte update
	inc bitmap_screen_address_high
	dex
	bne .plot_block_characters_loop
	rts

;--------------------------------------------------------------------------------------------------
; Base low/high bytes for each 8-pixel column on the bitmap screen
; each column is 176 pixels apart (11 rows x 16-pixels tall), see _VIC_CR3

data_bitmap_column_base_low
	!byte $00, $b0, $60, $10, $c0, $70, $20, $d0
	!byte $80, $30, $e0, $90, $40, $f0, $a0, $50
	!byte $00, $b0, $60, $10, $c0, $70

data_bitmap_column_base_high
    !byte $10, $10, $11, $12, $12, $13, $14, $14
	!byte $15, $16, $16, $17, $18, $18, $19, $1a
	!byte $1b, $1b, $1c, $1d, $1d, $1e

;--------------------------------------------------------------------------------------------------
; Compute the 8x8 bitmap screen address for the sprite at screen_column/screen_row.
; screen_column selects the 8-pixel-wide column using a table lookup.
; screen_row is added as the vertical byte offset from that column base.
; Result is returned in bitmap_screen_address_low/high.

compute_bitmap_screen_address_from_screen_row_column

	lda screen_column
	tay

    ; Get the remainder of screen column divided by 8 pixels 
    ; e.g. if screen column = 141, the remainder (the offset) is 5
    ; An 8x8 pixel sprite will have 3 pixels in one screen byte (offset is 5) 
    ; and 5 in the next one
	and #%00000111  ;7
	sta bitmap_bit_shift

    ; Convert the column into a number reference in X, with lsr x 3
	tya
	lsr
	lsr
	lsr
	tax

    ; Use X to find the column base address value (for the top of column) considering
    ; that a column value is 0 to 21 for the 22 columns on the screen (each spanning 8 pixels) and 
    ; each column is 176 pixels apart (11 rows x 16-pixels tall), see _VIC_CR3
    ; e.g. column 17 (in X) is at bitmap position 17 x 176 (176 row pixels vertically until the next column)
    ; giving 2992 ($bb0) added to the VIC screen address location ($1000) is $1bb0
	lda data_bitmap_column_base_high,x
	sta bitmap_screen_address_high
	lda data_bitmap_column_base_low,x

    ; Add the screen_row to complete the screen bitmap address
	clc
	adc screen_row
	sta bitmap_screen_address_low
	bcc *+4  ;skip high byte update
	inc bitmap_screen_address_high
	rts

;--------------------------------------------------------------------------------------------------
; Bit blitter for an 8-byte sprite / bitmap
; Plots the given object on the screen by adding to the bits already present there
plot_bitmap_on_screen

	jsr compute_bitmap_screen_address_from_screen_row_column

	ldy #7  ;8 pixel bytes in a sprite / character
.plot_bitmap_pixels_loop

    ; get pixel byte to plot
	lda #0
	sta bitmap_spill_bits  ;assume no spill bits
	lda (pixel_data_low),y  ;read sprite byte to plot as bitmap
	ldx bitmap_bit_shift  ;from subroutine above, is screen_column and #7 to shift the sprite bits right by 0..7 pixels
	beq .write_byte_to_screen_and_handle_spill_into_next_screen_byte

.shift_and_accumulate_spill_bits_loop
    ; handle where the sprite crosses an 8-bit boundary
	lsr  ;shift the sprite byte right
	ror bitmap_spill_bits  ;store the bits that fall off into a temporary byte
	dex
	bne .shift_and_accumulate_spill_bits_loop

.write_byte_to_screen_and_handle_spill_into_next_screen_byte
    ; apply the shifted sprite bits into the current screen byte and store result on screen
	ora (bitmap_screen_address_low),y  ;add the sprite bits to any already there
	sta (bitmap_screen_address_low),y

    ; calculate the next screen address using pixel counter in Y
	tya
	tax  ;store Y in X for loop later on
	ora #column_spacing
	tay

    ; plot the spill byte in the next screen address
	lda bitmap_spill_bits
	beq .continue_to_next_pixel_byte  ;no spill bits
	ora (bitmap_screen_address_low),y  ;add the sprite bits to any already there
	sta (bitmap_screen_address_low),y

.continue_to_next_pixel_byte
	txa
	tay
	dey
	bpl .plot_bitmap_pixels_loop
	rts

;--------------------------------------------------------------------------------------------------
; Bitmask-based eraser for an 8-byte sprite / bitmap
; Unplots the given object bits on the screen, thereby clearing it
erase_bitmap_on_screen

	jsr compute_bitmap_screen_address_from_screen_row_column

	ldy #7  ;8 pixel bytes in a sprite / character
.clear_bitmap_pixels_loop

    ; get pixel byte to plot
	lda #255
	sta bitmap_spill_bits
	lda (pixel_data_low),y  ;read sprite byte to unplot as bitmap
	eor #255  ;invert the pixel data (bit flip)
	ldx bitmap_bit_shift
	beq .write_erased_byte_to_screen_and_handle_spill_into_next_screen_byte

.rotate_and_accumulate_spill_bits_loop
    ; handle where the sprite crosses an 8-bit boundary
	sec
	ror  ;rotate bits right, carry (is 1) moves to sprite bit 7 and bit 0 is the new carry value
	ror bitmap_spill_bits  ;rotate bits right, carry (0 or 1) moves to spill bit 7, bit 0 into carry is not used
	dex
	bne .rotate_and_accumulate_spill_bits_loop

.write_erased_byte_to_screen_and_handle_spill_into_next_screen_byte
    ; apply the shifted sprite bits into the current screen byte and store result on screen
	and (bitmap_screen_address_low),y  ;keep only the bits that are not part of the sprite
	sta (bitmap_screen_address_low),y

    ; calculate the next screen address using pixel counter in Y
	tya
	tax
	ora #column_spacing
	tay

    ; unplot the spill byte in the next screen address
	lda bitmap_spill_bits
	cmp #255  ;check if spill bits changed from #255
	beq .progress_to_next_pixel_byte  ;no spill bits
	and (bitmap_screen_address_low),y  ;keep only the bits that are not part of the sprite
	sta (bitmap_screen_address_low),y  ;store result on screen

.progress_to_next_pixel_byte
	txa
	tay
	dey
	bpl .clear_bitmap_pixels_loop
	rts

;--------------------------------------------------------------------------------------------------

get_screen_coordinates_for_sprite

	ldy temp_snake_data_pointer2
get_screen_coordinates_for_sprite_player  ;Y is 7 when called
	ldx #2
.get_sprite_screen_coords_loop
	lda player_and_enemy_table_word,y  ;player_and_enemy_table with offset for sprite in Y
	sta screen_coords_table,x  ;update $0f (screen_row), $0e (screen_column), $0d (segment_direction)
	dey
	dex
	bpl .get_sprite_screen_coords_loop
	rts

;--------------------------------------------------------------------------------------------------

set_screen_coordinates_for_sprite

	ldy temp_snake_data_pointer2
	ldx #2
.set_sprite_screen_coords_loop
    lda screen_coords_table,x  ;get $0f (screen_row), $0e (screen_column), $0d (segment_direction)
	sta player_and_enemy_table_word,y  ;player_and_enemy_table with offset for sprite in Y
	dey
	dex
	bpl .set_sprite_screen_coords_loop
	rts

;--------------------------------------------------------------------------------------------------

data_screen_column_increments
	!byte 0, 0, 2, 254
data_screen_row_increments
	!byte 254, 2, 0, 0

;--------------------------------------------------------------------------------------------------

check_and_update_screen_row_column

	ldx current_segment_direction
	bne check_if_movement_direction_is_within_screen_bounds
	ldx screen_column
	ldy screen_row
	rts

check_if_movement_direction_is_within_screen_bounds

    ; calculate row (Y) and column (X) for screen bounds checking
	lda screen_row
	clc
	adc data_screen_row_increments-1,x
	tay  ;Y holds screen row to be tested

	lda screen_column
	clc
	adc data_screen_column_increments-1,x
	tax  ;X holds screen column to be tested

	lda #%10000000  ;128 set top bit 7 (assume within screen bounds)
	sta $04  ;set top bit 7

    ; check calculated row (Y) and column (X) are in the bounds of the screen
	cpx #6
	bcs .column_ok_on_right_edge
	asl $04  ;clear top bit 7 (outside screen bounds)
	ldx screen_column
.column_ok_on_right_edge
	cpx #167
	bcc .column_ok_on_left_edge
	asl $04  ;clear top bit 7 (outside screen bounds)
	ldx screen_column
.column_ok_on_left_edge
	cpy #22
	bcs .row_ok_on_top_edge
	asl $04  ;clear top bit 7 (outside screen bounds)
	ldy screen_row
.row_ok_on_top_edge
	cpy #167
	bcc .row_ok_on_bottom_edge
	asl $04  ;clear top bit 7 (outside screen bounds)
	ldy screen_row
.row_ok_on_bottom_edge
	rts

;--------------------------------------------------------------------------------------------------

update_screen_row_column

	jsr check_and_update_screen_row_column
	stx screen_column
	sty screen_row
	rts

;--------------------------------------------------------------------------------------------------

check_snake_head_maze_cell_alignment

    ; checks if the snake head is aligned to the 16-pixel cell maze grid
    ; before going on to check whether the movement should be validated (within screen bounds, not blocked etc)

	lda #128  ;set bit 7 on (assume snake head is not aligned to a maze cell boundary)
	sta maze_cell_boundary_flag
	ldx #1
.check_row_then_column_loop
	lda screen_coords_table+1,x  ;points to $0e (snake head screen column), $0f (snake head screen row)
	sec
	sbc #6  ;6 is the offset from the screen edge / maze origin, carry will clear if row / column is 5 or less
	and #%00001111  ;15 for the 16-pixel maze-cell size
	bne .end_if_not_zero
	dex
	bpl .check_row_then_column_loop
	asl maze_cell_boundary_flag  ;indicates snake head is aligned to a maze cell boundary (move bit 7 to carry, making bit 7 zero)
.end_if_not_zero
    ; at this point:
    ; maze_cell_boundary_flag bit 7 is 1 if either row or column are not zero, otherwise
    ; maze_cell_boundary_flag bit 7 is 0 if both row or column are zero
    ; carry is clear if either row or column coordinates are 5 or less, otherwise
    ; carry is set if either row or column coordinates are greater than 5, or both row or column are zero
	rts

;--------------------------------------------------------------------------------------------------

check_if_screen_coords_are_on_8_pixel_boundary

    ; check if the snake head is currently sitting on the next 8-pixel stepping point 
    ; where movement/turn logic should be considered

    ; returns zero when both screen row and column are on the 8-pixel boundary
    ; after subtracting 6 (i.e. values matching (coord-6) & 7 == 0)
    ; some examples of row and column values which return zero in this function (both must be zero):
    ; 102, 110, 118, 126, 134, 142, 150

	ldx #2
.check_each_coord_on_8_pixel_boundary_loop
	lda screen_coords_table,x  ;points to $0e (screen_column), $0f (screen_row)
	sec
	sbc #6  ;row or column is on an 8-pixel boundary after an offset of 6
	and #%00000111  ;7
	bne .end_check_coords_on_8_pixel_boundary
	dex
	bne .check_each_coord_on_8_pixel_boundary_loop
.end_check_coords_on_8_pixel_boundary
	rts

;--------------------------------------------------------------------------------------------------

data_to_add_to_maze_index
	!byte 0, 11, 1, 0

;--------------------------------------------------------------------------------------------------

check_segment_direction_is_valid
	bit maze_cell_boundary_flag
	bpl .check_segment_movement_is_valid_in_maze_and_current_cell
.direction_allowed_for_maze_cell
	clc
	rts

.check_segment_movement_is_valid_in_maze_and_current_cell
    ldx current_segment_direction

check_movement_is_valid_in_maze_and_current_cell
    stx snake_direction_pointer_to_test
	jsr check_if_movement_direction_is_within_screen_bounds
	bit $04  ;if bit 7 is set then new coords are within screen bounds
	bmi .check_if_movement_direction_is_allowed_in_maze_cell  ;new coords are within screen bounds
.direction_not_allowed_for_maze_cell
    sec
	rts

.check_if_movement_direction_is_allowed_in_maze_cell
    ; determine maze index to check if direction is allowed for the current maze cell
    jsr convert_screen_row_column_to_maze_index
	ldx snake_direction_pointer_to_test
	clc
	adc data_to_add_to_maze_index-1,x  ;with X, gets 0, 11, 1 or 0
	sta maze_index  ;calculated
	jsr get_maze_part_from_maze_data  ;A is 0, 1, 2 or 3

    ; check A:
    ;   0 = open cell, any direction is allowed
    ;   1 = allows horizontal movement only
    ;   2 = allows vertical movement only
    ;   3 = blocked / impassable
	beq .direction_allowed_for_maze_cell
	cmp #3
	beq .direction_not_allowed_for_maze_cell
	cmp #1
	bne .check_vertical_movement_in_maze_cell
	lda snake_direction_pointer_to_test
	cmp #3
	bcs .direction_allowed_for_maze_cell
	bcc .direction_not_allowed_for_maze_cell  ;always branch

.check_vertical_movement_in_maze_cell
	lda snake_direction_pointer_to_test
	cmp #3
	bcs .direction_not_allowed_for_maze_cell
	bcc .direction_allowed_for_maze_cell  ;always branch

;--------------------------------------------------------------------------------------------------

check_if_direction_change_is_valid

    ldx desired_snake_direction
	bit maze_cell_boundary_flag
	bpl check_movement_is_valid_in_maze_and_current_cell
	jsr check_if_screen_coords_are_on_8_pixel_boundary
	bne .direction_not_valid  ;not on 8 pixel boundary

	ldx desired_snake_direction
	lda current_segment_direction
	cmp data_directions-1,x
	bne .direction_not_valid
	lda screen_column
	cmp #166  ;last segment is at the right edge column?
	bne .direction_allowed_for_maze_cell
	lda screen_row
    cmp #126  ;last segment is outside front of home door row?
	bne .direction_allowed_for_maze_cell
.direction_not_valid
    sec
	rts

;--------------------------------------------------------------------------------------------------

move_body_segment_on_screen

    jsr get_screen_coordinates_for_sprite
	jsr clear_block_at_screen_coordinates
	jsr prepare_snake_body_sprite_to_use

update_row_column_and_plot_bitmap_on_screen
    lda pending_direction_change
	beq .skip_pending_direction_change_update  ;direction change indicator still zero?
	ldy current_segment_direction
	sta current_segment_direction
	sty pending_direction_change
.skip_pending_direction_change_update
    jsr update_screen_row_column
	jsr plot_bitmap_on_screen
	jsr set_screen_coordinates_for_sprite

add_3_to_point_to_next_segment
    lda temp_snake_data_pointer2
	clc
	adc #3
	sta temp_snake_data_pointer2
	rts

;--------------------------------------------------------------------------------------------------
; snake head and body sprite addresses

data_body_sprite_addresses_low
    !byte <player_snake_body_sprite
	!byte <enemy_snake_body_sprite
	!byte <enemy_weak_snake_body_sprite

data_body_sprite_addresses_high
    !byte >player_snake_body_sprite
	!byte >enemy_snake_body_sprite
    !byte >enemy_weak_snake_body_sprite

data_head_sprite_addresses_low
	!byte <player_snake_head_up_sprite
	!byte <player_snake_head_down_sprite
	!byte <player_snake_head_right_sprite
	!byte <player_snake_head_left_sprite
	!byte <enemy_snake_head_up_sprite
	!byte <enemy_snake_head_down_sprite
	!byte <enemy_snake_head_right_sprite
	!byte <enemy_snake_head_left_sprite
	!byte <enemy_weak_snake_head_up_sprite
	!byte <enemy_weak_snake_head_down_sprite
	!byte <enemy_weak_snake_head_right_sprite
    !byte <enemy_weak_snake_head_left_sprite

data_head_sprite_addresses_high
	!fill 7, >player_snake_head_up_sprite
	!fill 5, >enemy_snake_head_left_sprite

;--------------------------------------------------------------------------------------------------

data_directions_right_up
	!byte DIRECTION_RIGHT, DIRECTION_RIGHT, DIRECTION_UP, DIRECTION_UP
data_directions_left_down
	!byte DIRECTION_LEFT, DIRECTION_LEFT, DIRECTION_DOWN, DIRECTION_DOWN

;--------------------------------------------------------------------------------------------------

prepare_snake_body_sprite_to_use

    ldx snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	lda data_body_sprite_addresses_low,x  ;body sprites are in 3 different colours
	sta pixel_data_low
	lda data_body_sprite_addresses_high,x
	sta pixel_data_high
	rts

;--------------------------------------------------------------------------------------------------

set_snake_head_sprite_to_use_from_direction

    ;determine address for player snake or enemy snake normal, or weak, and include their direction
    lda snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	asl
	asl  ;asl x 2 = multiply by 4
	adc current_segment_direction
	tax

	lda data_head_sprite_addresses_low-1,x
	sta pixel_data_low
	lda data_head_sprite_addresses_high-1,x
	sta pixel_data_high
	rts

;--------------------------------------------------------------------------------------------------

handle_player_movement

    ldy #0
	dec player_snake_speed_counter
    ; skip movement action when speed counter is zero
    ; the lower the reload value, the more movement skips occur and the snake is slower
	bne perform_player_or_enemy_snake_movement
	lda player_snake_speed_reload
	sta player_snake_speed_counter  ;reset back to the control value
	rts

;--------------------------------------------------------------------------------------------------
perform_player_or_enemy_snake_movement

    sty temp_snake_data_pointer2  ;value in snake_data_pointer or #0 (player)
	sty temp_snake_data_pointer1

	ldx #0
	stx pending_direction_change
.set_snake_main_variables_loop
    lda player_and_enemy_table_word,y  ;player_and_enemy_table with offset for sprite in Y
	sta body_segments,x  ;update $0b (snake active indicator), $0a (snake_in_home_or_maze), $09 (snake_direction), $08 (snake_colour), $07 (body_segments)
	iny
	inx
	cpx #5
	bcc .set_snake_main_variables_loop

	iny
	iny
	sty temp_snake_data_pointer2  ;points to player or enemy snake head (Y is 7 or enemy snake pointer + 7)
	jsr get_screen_coordinates_for_sprite
	jsr check_snake_head_maze_cell_alignment  ;decide if snake head is at a position to check movement rules
	jsr choose_enemy_snake_direction
	jsr check_if_screen_coords_are_on_8_pixel_boundary
	bne .coords_not_on_8_pixel_boundary  ;no direction change

    ; consider a direction change
	lda current_segment_direction
	sta pending_direction_change

.coords_not_on_8_pixel_boundary
    lda desired_snake_direction
	beq .no_snake_direction_change
	jsr check_if_direction_change_is_valid
	bcc .move_in_the_direction  ;direction change is allowed
.no_snake_direction_change
    jsr check_segment_direction_is_valid
	bcc .plot_snake_head_for_direction
	ldy snake_in_home_or_maze
	bpl .apply_direction_for_enemy_snake
	ldx temp_snake_data_pointer1
	lda #0
	sta player_and_enemy_table+3,x  ;update snake in home or maze to #0 (left home, in maze)
	cpy #128
	beq .plot_snake_head_for_direction
	bne .move_in_the_direction  ;always branch

.apply_direction_for_enemy_snake
    lda snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	bne .choose_enemy_snake_direction
	jmp plot_entire_snake_on_screen_with_prepared_coordinates

.choose_enemy_snake_direction
    lsr $9114  ;set carry flag from timer
	bcs .carry_is_set_from_timer
.find_valid_snake_direction_loop
    ldy current_segment_direction
	lda data_directions_right_up-1,y
	sta desired_snake_direction  ;right or up
	jsr check_if_direction_change_is_valid
	bcc .move_in_the_direction  ;direction change is allowed
.carry_is_set_from_timer
    ldy current_segment_direction
	lda data_directions_left_down-1,y
	sta desired_snake_direction  ;left or down
	jsr check_if_direction_change_is_valid
	bcs .find_valid_snake_direction_loop  ;direction change is allowed

.move_in_the_direction
    lda desired_snake_direction
	sta pending_direction_change
	ldx temp_snake_data_pointer1
	lda #0
	sta player_and_enemy_table+2,x  ;snake direction
.plot_snake_head_for_direction
    jsr clear_block_at_screen_coordinates
	jsr set_snake_head_sprite_to_use_from_direction
	jsr update_row_column_and_plot_bitmap_on_screen
	dec body_segments
.move_body_segment_loop
    jsr move_body_segment_on_screen
	dec body_segments
	bne .move_body_segment_loop
	ldx temp_snake_data_pointer1
	lda #8
	sec
	sbc player_and_enemy_table,x
	tay
	jsr delay_using_Y

	bit snake_active_indicator
	bpl .end_perform_movement
	lda snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	bne .close_enemy_snake_door

    ; close player snake door after leaving home
	ldy screen_row
	cpy #118  ;outside player snake home door row?
	bne .end_perform_movement
	jsr .mark_snake_as_left_home_and_active
	jmp open_or_close_snake_entrance_door  ;close door (player snake)

.close_enemy_snake_door
    ; close enemy snakes door after leaving home
    ldy screen_row
	cpy #102  ;outside enemy snake home door row?
	bne .end_perform_movement
	jsr .mark_snake_as_left_home_and_active
	ldx #6  ;left edge column
	ldy #112  ;enemy snake home door row
	jmp open_or_close_snake_entrance_door_with_X_Y_coordinates  ;close door (enemy snakes)

.mark_snake_as_left_home_and_active
    lda #0
	ldx temp_snake_data_pointer1
	sta player_and_enemy_table+4,x  ;snake active indicator
	sec  ;to set the door closed
.end_perform_movement
    rts

;--------------------------------------------------------------------------------------------------
; snake head and body sprites

player_snake_body_sprite
    !byte %00010100
    !byte %00010100
    !byte %01010101
    !byte %01111101
    !byte %01111101
    !byte %01010101
    !byte %00010100
    !byte %00010100

enemy_snake_body_sprite  ;red normal enemy snake body colour
    !byte %00111100
    !byte %00111100
    !byte %11111111
    !byte %11010111
    !byte %11010111
    !byte %11111111
    !byte %00111100
    !byte %00111100

enemy_weak_snake_body_sprite  ;green vulnerable body, snake can be eaten head first
    !byte %00101000
    !byte %00101000
    !byte %10101010
    !byte %10010110
    !byte %10010110
    !byte %10101010
    !byte %00101000
    !byte %00101000

player_snake_head_up_sprite
    !byte %00010100
    !byte %00010100
    !byte %10010110
    !byte %10010110
    !byte %01010101
    !byte %01010101
    !byte %11111111
    !byte %11111111

player_snake_head_down_sprite
    !byte %11111111
    !byte %11111111
    !byte %01010101
    !byte %01010101
    !byte %10010110
    !byte %10010110
    !byte %00010100
    !byte %00010100

player_snake_head_right_sprite
    !byte %11011000
    !byte %11011000
    !byte %11010101
    !byte %11010101
    !byte %11010101
    !byte %11010101
    !byte %11011000
    !byte %11011000

player_snake_head_left_sprite
    !byte %00100111
    !byte %00100111
    !byte %01010111
    !byte %01010111
    !byte %01010111
    !byte %01010111
    !byte %00100111
    !byte %00100111

    ;red normal enemy snake head colour
enemy_snake_head_up_sprite
    !byte %00111100
    !byte %00111100
    !byte %10111110
    !byte %10111110
    !byte %11111111
    !byte %11111111
    !byte %01010101
    !byte %01010101

enemy_snake_head_down_sprite
    !byte %01010101
    !byte %01010101
    !byte %11111111
    !byte %11111111
    !byte %10111110
    !byte %10111110
    !byte %00111100
    !byte %00111100

enemy_snake_head_right_sprite
    !byte %01111000
    !byte %01111000
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111000
    !byte %01111000

enemy_snake_head_left_sprite
    !byte %00101101
    !byte %00101101
    !byte %11111101
    !byte %11111101
    !byte %11111101
    !byte %11111101
    !byte %00101101
    !byte %00101101

    ;green vulnerable head, snake can be eaten head first
enemy_weak_snake_head_up_sprite
    !byte %00101000
    !byte %00101000
    !byte %11101011
    !byte %11101011
    !byte %10101010
    !byte %10101010
    !byte %01010101
    !byte %01010101

enemy_weak_snake_head_down_sprite
    !byte %01010101
    !byte %01010101
    !byte %10101010
    !byte %10101010
    !byte %11101011
    !byte %11101011
    !byte %00101000
    !byte %00101000

enemy_weak_snake_head_right_sprite
    !byte %10111100
    !byte %10111100
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111100
    !byte %10111100

enemy_weak_snake_head_left_sprite
    !byte %00111001
    !byte %00111001
    !byte %10101001
    !byte %10101001
    !byte %10101001
    !byte %10101001
    !byte %00111001
    !byte %00111001

;--------------------------------------------------------------------------------------------------

initialise_system_registers

    ; Not apparently needed
    lda #$a4
	sta bitmap_screen_address_low
	lda #$c0
	sta bitmap_screen_address_high

	jsr init_system_registers_and_timers

    ; Not apparently needed
	lda #2
	ldy #0
	sta (bitmap_screen_address_low),y
	rts

;--------------------------------------------------------------------------------------------------

data_maze_1
	!byte $d5, $55, $56, $44, $a4, $49, $4a, $a5
	!byte $31, $00, $11, $a4, $44, $52, $25, $14
	!byte $4e, $31, $11, $2a, $2a, $cb, $a4, $88
	!byte $4a, $90, $84, $c0

data_maze_2
	!byte $d5, $55, $56, $51, $51, $4b, $19, $11
	!byte $62, $8a, $9a, $aa, $a2, $82, $08, $a8
	!byte $ae, $88, $04, $28, $84, $53, $a4, $44
	!byte $4a, $94, $44, $c0

data_maze_3
	!byte $d5, $77, $56, $52, $21, $2c, $62, $25
	!byte $24, $22, $24, $b4, $2a, $16, $11, $24
	!byte $4e, $94, $94, $28, $50, $53, $a9, $14
	!byte $4a, $89, $14, $c0

data_maze_4
	!byte $d7, $55, $56, $63, $44, $6c, $41, $74
	!byte $29, $54, $14, $a6, $45, $46, $05, $35
	!byte $4f, $2a, $9b, $2b, $00, $8b, $a9, $4c
	!byte $ca, $89, $48, $c0

data_maze_5
	!byte $d5, $dd, $56, $98, $a9, $c9, $0a, $18
	!byte $71, $45, $0c, $92, $69, $62, $44, $0c
	!byte $1e, $a6, $4b, $2a, $64, $cb, $a6, $44
	!byte $ca, $85, $14, $c0

data_maze_6
	!byte $d5, $dd, $76, $52, $aa, $0d, $22, $25
	!byte $25, $14, $25, $d3, $11, $52, $51, $12
	!byte $5e, $46, $65, $2b, $22, $4b, $aa, $aa
	!byte $ca, $88, $88, $c0

data_maze_7
	!byte $d5, $d7, $56, $58, $43, $2c, $85, $40
	!byte $2c, $51, $44, $85, $11, $46, $51, $11
	!byte $4e, $51, $14, $2c, $51, $4b, $a4, $54
	!byte $4a, $94, $44, $c0

data_maze_8
	!byte $d5, $55, $d6, $99, $c8, $ca, $98, $4c
	!byte $a2, $94, $c4, $90, $94, $a6, $68, $d0
	!byte $4e, $8c, $59, $28, $cd, $1b, $ac, $45
	!byte $8a, $84, $90, $c0

data_maze_9
	!byte $d7, $55, $d6, $c3, $18, $68, $32, $98
	!byte $33, $31, $99, $91, $29, $12, $66, $0c
	!byte $ce, $66, $cc, $2a, $60, $cb, $a6, $6c
	!byte $ca, $82, $08, $c0

data_maze_10
	!byte $d5, $55, $56, $99, $b3, $29, $98, $33
	!byte $29, $9b, $32, $91, $01, $12, $4c, $a6
	!byte $6e, $cc, $66, $28, $ca, $63, $ac, $c6
	!byte $4a, $84, $44, $c0

data_maze_11
	!byte $d5, $55, $56, $cb, $26, $68, $49, $ca
	!byte $2c, $48, $44, $a9, $54, $9a, $34, $96
	!byte $8e, $15, $41, $29, $c9, $cb, $aa, $22
	!byte $ca, $81, $40, $c0

data_maze_12
	!byte $d5, $d5, $d6, $50, $50, $6a, $72, $72
	!byte $2c, $14, $14, $89, $c9, $ca, $50, $50
	!byte $6e, $c7, $1c, $28, $61, $8b, $a8, $20
	!byte $ca, $92, $48, $c0

data_maze_13
	!byte $d5, $75, $56, $52, $29, $49, $12, $11
	!byte $29, $a2, $b2, $a0, $a2, $0a, $50, $21
	!byte $4e, $52, $15, $2b, $1b, $1b, $a9, $01
    !byte $0a, $85, $14, $c0

data_maze_14
    !byte $d5, $55, $56, $c9, $24, $88, $c9, $c9
    !byte $b0, $48, $90, $b2, $49, $26, $1c, $71
	!byte $ce, $86, $30, $2a, $62, $33, $a6, $1c
	!byte $0a, $81, $04, $c0

data_maze_15
    !byte $d5, $d7, $56, $70, $41, $cc, $25, $50
    !byte $6c, $d4, $a6, $8a, $ba, $a2, $4a, $42
    !byte $4f, $01, $59, $2a, $55, $0b, $a6, $92
    !byte $ca, $82, $48, $c0

data_maze_16
    !byte $d5, $75, $56, $44, $11, $4a, $54, $59
    !byte $6a, $45, $b4, $aa, $5a, $16, $22, $23
    !byte $4e, $24, $2b, $2a, $44, $2b, $ac, $54
    !byte $0a, $89, $44, $c0

data_maze_17
    !byte $d5, $77, $56, $32, $2b, $29, $22, $81
    !byte $25, $a8, $51, $d0, $86, $52, $50, $82
    !byte $5e, $51, $2d, $2c, $52, $8b, $ac, $a8
    !byte $ca, $84, $88, $c0

data_maze_18
    !byte $d5, $55, $56, $b1, $51, $aa, $b1, $1a
    !byte $a2, $b1, $a8, $90, $10, $12, $6a, $4a
    !byte $ae, $a4, $4a, $2a, $44, $4b, $a4, $54
    !byte $4a, $94, $94, $c0

data_maze_19
    !byte $dd, $55, $d6, $2c, $9a, $4a, $0a, $82
    !byte $69, $a2, $cc, $8a, $22, $86, $62, $a3
    !byte $4e, $28, $a3, $2a, $88, $ab, $a8, $a8
    !byte $8a, $92, $24, $c0

data_maze_20
    !byte $d5, $55, $56, $c4, $a4, $68, $4a, $a4
    !byte $24, $a0, $a4, $c6, $10, $c6, $44, $a4
    !byte $4e, $4c, $64, $2a, $ca, $6b, $a8, $44
    !byte $0a, $94, $44, $c0

;--------------------------------------------------------------------------------------------------

data_maze_addresses_low
	!byte <data_maze_1
	!byte <data_maze_2
	!byte <data_maze_3
	!byte <data_maze_4
	!byte <data_maze_5
	!byte <data_maze_6
	!byte <data_maze_7
	!byte <data_maze_8
	!byte <data_maze_9
	!byte <data_maze_10
	!byte <data_maze_11
	!byte <data_maze_12
	!byte <data_maze_13
	!byte <data_maze_14
	!byte <data_maze_15
	!byte <data_maze_16
	!byte <data_maze_17
	!byte <data_maze_18
	!byte <data_maze_19
    !byte <data_maze_20

data_maze_addresses_high
	!fill 7, >data_maze_1
    !fill 9, 1+>data_maze_1
    !fill 4, 2+>data_maze_1

;--------------------------------------------------------------------------------------------------
; Use the maze level (the current maze to be played), lookup the maze layout and display it

draw_maze_on_screen

    ldx maze_level
	cpx #21  ;beyond max number of mazes available
	bcc .set_maze_build_from_address

    ; current maze level can exceed the 20 defined maze maps,
    ; so subtract 10 from current maze level to get one of the 20 maze maps
	txa
.decide_maze_to_use
    sbc #10
	cmp #21  ;beyond max number of mazes available
	bcs .decide_maze_to_use
	tax
.set_maze_build_from_address
    lda data_maze_addresses_low-1,x
	sta maze_address_low
	lda data_maze_addresses_high-1,x
	sta maze_address_high

    ;----------------------------------------------------------------------------------------------
    ; draw the maze (which leaves unwanted maze parts on the top row and left column of the maze)
	lda #0
	sta maze_index  ;is 0
.draw_maze_loop_1
    jsr convert_maze_index_to_screen_row_column

    ; get the maze part to draw
    jsr get_maze_part_from_maze_data  ;A is 0, 1, 2 or 3 (WALL_xxx)
	tax
	cpx #WALL_VERTICAL_AND_HORIZONTAL
	bcc .skip_plot_double_wall_section

	dex  ;draw vertical section first
	jsr plot_maze_parts_on_screen
	jsr convert_maze_index_to_screen_row_column
	ldx #WALL_HORIZONTAL

.skip_plot_double_wall_section
    ; draw maze parts for X = 0, 1, 2 (WALL_xxx)
    jsr plot_maze_parts_on_screen
	inc maze_index
	lda maze_index
	cmp #110  ;10 rows x 11 columns of parts needed to plot maze throughout the screen
	bcc .draw_maze_loop_1

    ;----------------------------------------------------------------------------------------------
    ; tidy top line of maze (loops 2 and 3)
	lda #10
	sta maze_index  ;is 10
	lda #<data_maze_part_1  ;"horizontal wall section with green square on left"
	sta pixel_data_low
	lda #>data_maze_part_1  ;"horizontal wall section with green square on left"
	sta pixel_data_high
.draw_maze_loop_2
    jsr convert_maze_index_to_screen_row_column
	jsr erase_bitmap_on_screen
	dec maze_index
	bpl .draw_maze_loop_2

	lda #10
	sta maze_index  ;is 10
	lda #<data_maze_part_2  ;"horizontal wall section"
	sta pixel_data_low
	lda #>data_maze_part_2  ;"horizontal wall section"
	sta pixel_data_high
.draw_maze_loop_3
    jsr convert_maze_index_to_screen_row_column
	jsr plot_bitmap_on_screen
	dec maze_index
	bpl .draw_maze_loop_3

    ;----------------------------------------------------------------------------------------------
    ; tidy left column of maze (loops 4 and 5)
	lda #99
	sta maze_index  ;is 99
	lda #<data_maze_part_3  ;"vertical wall section with green spare on top"
	sta pixel_data_low
	lda #>data_maze_part_3  ;"vertical wall section with green spare on top"
	sta pixel_data_high
.draw_maze_loop_4
    jsr convert_maze_index_to_screen_row_column
	jsr erase_bitmap_on_screen
	lda maze_index
	sec
	sbc #11
	sta maze_index  ;calculated
	bne .draw_maze_loop_4

	lda #<data_maze_part_4  ;"vertical wall section"
	sta pixel_data_low
	lda #>data_maze_part_4  ;"vertical wall section"
	sta pixel_data_high
	lda #99
	sta maze_index  ;is 99
.draw_maze_loop_5
    jsr convert_maze_index_to_screen_row_column
	jsr plot_bitmap_on_screen
	lda maze_index
	sec
	sbc #11
	sta maze_index  ;calculated
	bne .draw_maze_loop_5
	rts

;--------------------------------------------------------------------------------------------------
; maze part data

data_maze_part_0
    ;single green square
    !byte %10100000
    !byte %10100000
    !byte %10100000
    !byte %10100000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

data_maze_part_1
    ;horizontal wall section with green square on left
    !byte %10100101
    !byte %10100101
    !byte %10100101
    !byte %10100101
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

data_maze_part_2
    ;horizontal wall section
    !byte %01010101
    !byte %01010101
    !byte %01010101
    !byte %01010101
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

data_maze_part_3
    ;vertical wall section with green spare on top
    !byte %10100000
    !byte %10100000
    !byte %10100000
    !byte %10100000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000

data_maze_part_4
    ;vertical wall section
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000

;--------------------------------------------------------------------------------------------------
; maze part addresses

data_maze_parts_low
    !byte <data_maze_part_0  ;single green square
	!byte <data_maze_part_1  ;horizontal wall section with green square on left
	!byte <data_maze_part_3  ;vertical wall section with green spare on top

data_maze_parts_high
    !byte >data_maze_part_0  ;single green square
	!byte >data_maze_part_1  ;horizontal wall section with green square on left
    !byte >data_maze_part_3  ;vertical wall section with green spare on top

;--------------------------------------------------------------------------------------------------

data_draw_maze_part_horizontal_offset
	!byte $08, $00

data_draw_maze_part_vertical_offset
	!byte $00, $08

;--------------------------------------------------------------------------------------------------

plot_maze_parts_on_screen

    ; plot maze part on screen for the X value (0, 1, 2)
    stx maze_part_to_plot
	lda data_maze_parts_low,x
	sta pixel_data_low
	lda data_maze_parts_high,x
	sta pixel_data_high
	jsr plot_bitmap_on_screen

	ldx maze_part_to_plot  ;0, 1, 2
	beq .end_data_maze_part  ;skip plot of second section of maze part when X is 0
    ; this skips when maze part above was "single green square" (WALL_SINGLE_GREEN_SQUARE)

    ; whenever the maze parts (below) are plotted, complete it with the second section
    ;   horizontal wall is: "horizontal wall section with green square on left"
    ;                   and "horizontal wall section"
    ;     vertical wall is: "vertical wall section with green spare on top"
    ;                   and "vertical wall section"

    ; update screen coordinates for the next maze part using the offset table to add to screen column and row
	lda screen_column
	clc
	adc data_draw_maze_part_horizontal_offset-1,x
	sta screen_column
	lda screen_row
	adc data_draw_maze_part_vertical_offset-1,x
	sta screen_row

    ; update the pointers to the next maze data byte and plot that maze part
	lda pixel_data_low
	clc
	adc #8
	sta pixel_data_low
    bcc *+4  ;skip high byte update
	inc pixel_data_high
    jmp plot_bitmap_on_screen

.end_data_maze_part
    rts

;--------------------------------------------------------------------------------------------------

convert_maze_index_to_screen_row_column

    lda maze_index
	ldx #0
	sec
.subtract_11_loop  ;divide A by 11 rows in a column
    inx  ;count rows
	sbc #11
	bcs .subtract_11_loop

    ; remainder in A is the column number, convert to bitmap position
	adc #11
	asl
	asl
	asl
	asl  ;asl x 4 = multiply by 16 (columns are 2 8-bit characters apart)
	sta screen_column

	txa  ;X is from the division above
	asl
	asl
	asl
	asl  ;asl x 4 = multiply by 16 (16-pixel tall characters)
	sta screen_row
	rts

;--------------------------------------------------------------------------------------------------

convert_screen_row_column_to_maze_index

    ; convert row component
    lda screen_row
	lsr
	lsr
	lsr
	lsr  ;lsr x 4 to divide screen_row by 16 (16-pixel tall characters) for a cell-row index
	sec
	sbc #1  ;amend cell-row index to be row-1
	sta maze_index  ;update maze index
	asl maze_index
	adc maze_index
	asl maze_index
	asl maze_index
	adc maze_index
	sta maze_index  ;asl and adc instructions above multiply updated maze index by 13

    ; convert column component
	lda screen_column
	lsr
	lsr
	lsr
	lsr  ;lsr x 4 to divide screen_column by 16 (columns are 2 8-bit characters apart) for a cell-column index

	clc
	adc maze_index  ;add the row component
	sta maze_index  ;result is 13 * (screen_row/16 - 1) + (screen_column/16)
	rts

;--------------------------------------------------------------------------------------------------
; Called from draw_maze_on_screen, this function decides which maze graphic piece to draw

get_maze_part_from_maze_data

    ; convert maze index address value to X for division loop below
    lda maze_index
	and #%00000011  ;3
	tax  ;X is 0, 1, 2 or 3

    ; convert maze index address value to Y for maze data offset
	lda maze_index
	lsr
	lsr  ;divide maze index address value by 4 (2 x lsr)
	tay  ;Y is 0 to 27

    ; get maze part byte from table (the same byte is read 4 times)
    ; each maze part byte holds 4 maze parts (2 bits each)
    ; for example $1e (00011110) is:
    ;   00 = WALL_SINGLE_GREEN_SQUARE
    ;   01 = WALL_HORIZONTAL
    ;   11 = WALL_VERTICAL_AND_HORIZONTAL
    ;   10 = WALL_VERTICAL
	lda (maze_address_low),y

    ; the X value behaves like a sub-index to get the maze part (2 bits) to use
.decide_maze_part_loop
    cpx #3
	bcs .end_decide_maze_part  ;branch if X is 3
	lsr
	lsr  ;isolate the two maze part bits to use by shifting to the right twice (with AND below)
	inx
	bne .decide_maze_part_loop  ;always branch

.end_decide_maze_part
    and #%00000011  ;3, so A is 0, 1, 2 or 3 (WALL_xxx)
	rts

;--------------------------------------------------------------------------------------------------

data_for_snake_entrance_door
    !byte %01010101
    !byte %01010101
    !byte %01010101
    !byte %01010101
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

;--------------------------------------------------------------------------------------------------

plot_player_snake_and_open_entrance_door

	lda #0
	sta snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	lda player_body_segments
	sta body_segments  ;points to player snake number of segments
	lda #7
	jsr plot_entire_snake_on_screen
	clc

;--------------------------------------------------------------------------------------------------

open_or_close_snake_entrance_door

    ldx #166  ;right edge column
	ldy #128  ;home door row
open_or_close_snake_entrance_door_with_X_Y_coordinates
    stx screen_column
	sty screen_row
	lda #<data_for_snake_entrance_door
	sta pixel_data_low
	lda #>data_for_snake_entrance_door
	sta pixel_data_high
	bcs .goto_plot_bitmap_on_screen_1
	jmp erase_bitmap_on_screen

.goto_plot_bitmap_on_screen_1
    jmp plot_bitmap_on_screen

;--------------------------------------------------------------------------------------------------

plot_entire_snake_on_screen

    sta temp_snake_data_pointer2  ;points to player or enemy snake head
	jsr get_screen_coordinates_for_sprite
plot_entire_snake_on_screen_with_prepared_coordinates
    jsr set_snake_head_sprite_to_use_from_direction
	jmp .plot_snake_part_on_screen

.plot_snake_body_loop
    jsr get_screen_coordinates_for_sprite
	jsr prepare_snake_body_sprite_to_use
.plot_snake_part_on_screen
    jsr plot_bitmap_on_screen
	jsr add_3_to_point_to_next_segment  ;coordinates of next segment
	dec body_segments  ;points to player or enemy snake number of segments
	bne .plot_snake_body_loop
	rts

;--------------------------------------------------------------------------------------------------
; Given the starting screen coordinates and start of text data address, plot the
; text in the top heading lines on the screen

plot_heading_on_screen

    stx screen_column
	sty screen_row

	ldy #0
	sty data_index
.plot_heading_loop

    jsr plot_block_at_screen_coordinates

	lda #0
	sta pixel_data_high
	ldy data_index
	lda (text_data_low),y  ;read text data using index
	beq .end_plot_heading  ;data terminates with a zero

    ; Get the memory address where the bitmap of a digit in A is held, also see plot_A_on_screen
	sec
	sbc #64

	ldy #3
.convert_to_address_loop
    asl
	rol pixel_data_high
	dey
	bne .convert_to_address_loop

	sta pixel_data_low
	lda #128
	clc
	adc pixel_data_high

    ; Plot the pixel data in address pixel_data_low / high and move to the next screen position
	jsr reverse_plot_pixel_data_and_increment_screen_coords

	inc data_index
	bne .plot_heading_loop  ;always branch (in this case)

.end_plot_heading
    rts

;--------------------------------------------------------------------------------------------------

plot_block_at_screen_coordinates

    ; word in $10, $11 is $8500 (34048) which is a block character (8 bytes of $ff)
    ; $8400 to $87FF (33792 to 33815) is the reversed upper case and graphics area
    lda #0
	sta pixel_data_low
	lda #133  ;$85
	sta pixel_data_high
	jmp plot_bitmap_on_screen

;--------------------------------------------------------------------------------------------------

clear_block_at_screen_coordinates

    ; word in $10, $11 is $8500 (34048) which is a block character (8 bytes of $ff)
    ; $8400 to $87FF (33792 to 33815) is the reversed upper case and graphics area
    lda #0
	sta pixel_data_low
	lda #133  ;$85
	sta pixel_data_high
	jmp erase_bitmap_on_screen

;--------------------------------------------------------------------------------------------------

plot_A_on_screen

    ; Get the memory address where the bitmap of a digit in A is held
    ; and store this address in word in $10, $11
    ; So: 0 is in address $8180 to $8187, 1 is in $8188 to $818f, 
    ;     2 is in $8190 to $8197, ... 9 is in $81c8 to $81cf
    ; Example: if A = 2, asl x 3, ora #128, A = 144 ($90) giving the low byte bitmap address
    ; The high byte is always $81, so the complete address is $8190

    asl
	asl
	asl
	ora #%10000000  ;128
	sta pixel_data_low
	lda #129  ;$81

;--------------------------------------------------------------------------------------------------

reverse_plot_pixel_data_and_increment_screen_coords

    sta pixel_data_high

    ; unplot the pixel data on the blocked out heading lines making it appear reversed
	jsr erase_bitmap_on_screen

    ; update the screen column
	lda screen_column
	clc
	adc #8
	sta screen_column
	rts

;--------------------------------------------------------------------------------------------------

data_score_heading
	!pet "score"
	!fill 8, $60
    !pet "hi"
	!byte $00

data_level_heading
	!pet "level"
	!byte $60
	!byte $60
	!byte $60
	!byte $60
	!pet "serpents"
	!byte $00

;--------------------------------------------------------------------------------------------------

plot_level_and_headings_on_screen

    lda #<data_score_heading
	sta text_data_low
	lda #>data_score_heading
	sta text_data_high
	ldx #4
	ldy #0
	jsr plot_heading_on_screen

	lda #<data_level_heading
	sta text_data_low
	lda #>data_level_heading
	sta text_data_high
	ldx #4
	ldy #8
	jsr plot_heading_on_screen

	lda #48
	sta screen_column
	lda #8
	sta screen_row
	lda maze_level
	cmp #10
	bcc .plot_last_level_digit
	ldx #255
.plot_first_level_digits
    sbc #10
	inx
	bcs .plot_first_level_digits
	adc #10
	pha
	txa
	jsr plot_A_on_screen
    pla
.plot_last_level_digit
	jmp plot_A_on_screen

;--------------------------------------------------------------------------------------------------
; Initialise player and high score

zero_player_and_high_score

    ldx #5
zero_player_score
    lda #0
.zero_player_score_loop
    sta player_score,x
	dex
	bpl .zero_player_score_loop
	rts

;--------------------------------------------------------------------------------------------------

update_player_score_low_amount

    sed  ;set decimal
	clc
	adc player_score+2
	sta player_score+2
	bcc .clear_decimal_and_end
	lda #0

update_player_score
    sed  ;set decimal
	adc player_score+1
	sta player_score+1
	bcc .clear_decimal_and_end
	lda #0
	adc player_score
	sta player_score
	dec $5a
	bne .clear_decimal_and_end
	ldx #3
	cmp #5  ;if score reaches 60000, get another life
	bcc *+4  ;skip next instruction
	ldx #5
    stx $5a  ;X is 3 or 5
	jsr add_one_to_player_lives
.clear_decimal_and_end
    cld  ;clear decimal
	rts

;--------------------------------------------------------------------------------------------------

plot_player_score_on_screen

    ldx #0
	lda #0
	ldy #48
plot_score_on_screen
    sty screen_column
	sta screen_row
	lda #3  ;3 score bytes
	sta $61
	lda #128  ;bit 7 is on
	sta zero_digit_control_flag  ;used to prevent score with a leading zero digit being displayed e.g. 04500
.plot_each_score_byte_loop
    lda player_score,x
	bne .plot_score_digits
	inx
	dec $61
	bne .plot_each_score_byte_loop
	rts

.plot_score_digits
    ; The score bytes are calculated and stored in decimal mode (with the sed instruction)
    ; which means for example, a score of 32500 will be held as bytes $03, $25, $00
    ; Consider the second byte $25 broken down into first digit A = 2, and second digit A = 5
    ; with each digit plotted on screen via plot_A_on_screen. The same applies to the other bytes

    ; break each score byte into the digits to plot on screen
    stx data_index
.plot_each_score_digit_loop
    ldx data_index
	lda player_score,x
	pha  ;put the score on the stack
	and #%11110000  ;240 mask off the nibble with the first digit
	bne .plot_first_score_digit
	bit zero_digit_control_flag  ;score digit is zero, check zero digit flag
	bpl .plot_first_score_digit  ;branch if bit 7 is off, ok to plot zero digit
	asl zero_digit_control_flag  ;bit 7 is off
	beq .plot_second_score_digit  ;the zero digit flag is off, first digit is skipped and second one is plotted
.plot_first_score_digit
    asl zero_digit_control_flag  ;bit 7 is off
	lsr
	lsr
	lsr
	lsr  ;lsr x 4 to convert the first digit into A in range 0 to 9
	pha  ;temporarily store A on stack
	jsr plot_block_at_screen_coordinates  ;plot a block so that the score digit can be 'unplotted' on top of it (appears reversed)
	pla  ;get A back off the stack for plotting
	jsr plot_A_on_screen
.plot_second_score_digit
    jsr plot_block_at_screen_coordinates  ;plot a block so that the score digit can be 'unplotted' on top of it (appears reversed)
	pla  ;get the score off the stack
	and #%00001111  ;15 mask off the nibble with the second digit to get A in range 0 to 9
	jsr plot_A_on_screen
	inc data_index
	dec $61
	bne .plot_each_score_digit_loop
	rts

;--------------------------------------------------------------------------------------------------

plot_high_score_on_screen

	ldx #3
	lda #0
	ldy #128
	jmp plot_score_on_screen

;--------------------------------------------------------------------------------------------------

check_for_new_high_score

    ldx #0
.check_new_high_score_loop
    lda player_score,x
	cmp high_score,x
	bne .update_high_score
	inx
	cpx #3
	bcc .check_new_high_score_loop
	rts

.update_high_score
    bcc .subroutine_return
	ldx #2
.update_high_score_loop
    lda player_score,x
	sta high_score,x
	dex
	bpl .update_high_score_loop
.subroutine_return
    rts

;--------------------------------------------------------------------------------------------------

add_one_to_player_lives

    ldx player_lives
	cpx #9  ;max lives
	bcs .subroutine_return
	inx
	stx player_lives

plot_player_lives_on_screen
    lda #144
	sta screen_column
	lda #8
	sta screen_row
	jsr plot_block_at_screen_coordinates
	lda player_lives
	jmp plot_A_on_screen

update_player_loses_life
    ldx player_lives
	dex
	stx player_lives
	jsr plot_player_lives_on_screen
	sec
	ldx player_lives
	beq .skip_lose_life_clear_carry
	clc
.skip_lose_life_clear_carry
    rts

;--------------------------------------------------------------------------------------------------

play_sounds

    ; For each channel, find if there is a sound to play and play it for the duration
    ; in the sound data. A duration value of 0 performs sound set-up where the actual
    ; sound duration is set and note is played. This note continues until duration is
    ; 0 again which goes onto set-up the next duration and plays the next note.
    ; When duration is #255, the sound on the channel is cleared and stopped.
    ;
    ; Sound clip data is organised:
    ;   Repeating 2 bytes of duration, frequency (note), with duration = #255 to end

    ldx #4
.play_sounds_loop
    lda sound_clip_address_low-1,x  ;sound clip data address low for sound channel
	sta sound_data_low
	lda sound_clip_address_high-1,x  ;sound clip data address high for sound channel
	sta sound_data_high
	ldy sound_clip_data_pointer_for_channel-1,x  ;initially 254 from prepare_sound_data
	lda sound_clip_duration_for_channel-1,x  ;initially 0 from prepare_sound_data, #255 from clear_all_sound_channels
	beq .play_sound_on_channel
	cmp #255  ;end of sound
	bne .continue_sound_and_decrease_duration_counter
.clear_sound_channel
    lda #0
	sta _VIC_SOUND_BASS-1,x
	beq .next_sound_channel  ;always branch

.play_sound_on_channel
    iny
	iny  ;Y when 254 initially becomes 0
	lda (sound_data_low),y  ;sound clip duration
	beq .play_sound_on_channel

	sta sound_clip_duration_for_channel-1,x  ;store sound duration on channel
	cmp #255  ;end of sound when #255
	beq .clear_sound_channel
	tya
	sta sound_clip_data_pointer_for_channel-1,x  ;update data pointer to point to the next duration data position
	iny  ;point to the sound frequency
	lda (sound_data_low),y  ;get sound frequency and play it on channel
	sta _VIC_SOUND_BASS-1,x
.continue_sound_and_decrease_duration_counter
    dec sound_clip_duration_for_channel-1,x  ;decrease the duration of the sound being played on channel
.next_sound_channel
    dex
	bne .play_sounds_loop
	rts

;--------------------------------------------------------------------------------------------------

prepare_sound_data

    ; Use the given sound address table (low high in X Y) to prepare zero page addresses
    ; with the starting addresses of sound clip data (where sound duration and frequencies are)
    ;
    ; For each sound, the sound address table data is organised:
    ;   3 bytes for sound channel, sound clip address low, high
    ;   repeating per channel until #255 is reached to close the sound setup
    ;
    ; In zero page the sound channel addresses for playing the sound clip data are:
    ;   $6d to $70 sound clip address low for _VIC_SOUND_BASS / ALTO / SOPRANO / NOISE
    ;   $72 to $75 sound clip address high for _VIC_SOUND_BASS / ALTO / SOPRANO / NOISE
    ;
    ; The initial sound duration and data pointers are also set:
    ;   $68 to $6b = 0 is the sound duration per sound channel
    ;   $63 to $66 = 254 is the sound clip data pointer per sound channel

    stx sound_data_low
	sty sound_data_high
	ldy #0
.init_sound_data_loop

    lda (sound_data_low),y
	cmp #255  ;end of sound
	beq .end_of_sound_data_byte_reached
	tax  ;first byte is the sound channel (1 to 4) and used as the zero page offset

	iny
	lda (sound_data_low),y
	sta sound_clip_address_low-1,x

	iny
	lda (sound_data_low),y
	sta sound_clip_address_high-1,x

	lda #0
	sta sound_clip_duration_for_channel-1,x

	lda #254
	sta sound_clip_data_pointer_for_channel-1,x

	iny
	bne .init_sound_data_loop

.end_of_sound_data_byte_reached
    rts

;--------------------------------------------------------------------------------------------------

data_clear_all_sound_channels
    !byte SOUND_BASS, <data_sound_end, >data_sound_end
    !byte SOUND_ALTO, <data_sound_end, >data_sound_end
    !byte SOUND_SOPRANO, <data_sound_end, >data_sound_end
    !byte SOUND_NOISE, <data_sound_end, >data_sound_end
data_sound_end
    !byte $ff

;--------------------------------------------------------------------------------------------------

clear_all_sound_channels

    ; clear sounds on each channel
    lda #%00101010  ;aux colour red, volume 10
	sta _VIC_VOLUME
	ldx #<data_clear_all_sound_channels
	ldy #>data_clear_all_sound_channels
	jsr prepare_sound_data
	jmp play_sounds

;--------------------------------------------------------------------------------------------------

set_enemy_snake_start_position

    lda maze_level
	cmp #1  ;first maze
	bne .not_maze_number_one
	lda #5  ;head plus 4 body parts, easier for the first maze, changes to 6 for the others
	sta snake_1_body_segments
	sta snake_2_body_segments
	sta snake_3_body_segments
.not_maze_number_one
    ; change the delay for snakes 1 and 3 to enter cave, the default value is 60 applied to snake 2
    lda #0
	sta enemy_snake_table+30  ;delay for snake 1 to enter cave
	lda #120
	sta enemy_snake_table+90  ;delay for snake 3 to enter cave

	ldx #31  ;point to first snake table data
perform_snake_entrance
    lda enemy_snake_table,x  ;enemy snake number of segments
	sta body_segments  ;points to player or enemy snake number of segments
	lda #1  ;enemy snake is red (normal) colour
	sta snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	txa
	clc
	adc #7
	jsr plot_entire_snake_on_screen
	ldx #6  ;left edge column
	ldy #112  ;enemy snake home door row
	clc  ;to clear space and open door
    jmp open_or_close_snake_entrance_door_with_X_Y_coordinates   ;door open

;--------------------------------------------------------------------------------------------------

data_directions
	!byte DIRECTION_DOWN, DIRECTION_UP, DIRECTION_LEFT, DIRECTION_RIGHT

;--------------------------------------------------------------------------------------------------

data_random_state_comparison_values
	!byte 50, 80, 110, 140, 170, 190, 210, 225, 240, 250

;--------------------------------------------------------------------------------------------------

handle_enemy_snake_movement

    dec enemy_snake_speed_counter
    ; skip movement action when speed counter is zero
    ; the higher the reload value, fewer movement skips occur and the snake is faster
	bne perform_enemy_snake_movement
	lda enemy_snake_speed_reload
	sta enemy_snake_speed_counter  ;reset back to the control value
	rts

;--------------------------------------------------------------------------------------------------

perform_enemy_snake_movement

    lda #0
	sta temp3
	ldx #31  ;point to first snake table data
.each_snake_loop
    stx snake_data_pointer
	ldy temp3  ;0, 1, 2
	lda snake_tick_table_word,y  ;$30, $2f, $2e
	bpl .check_if_snake_should_enter_maze
	cmp #128
	beq .goto_delay_and_onto_next_snake
	jsr dead_snake_animation
	jmp .goto_next_snake

.check_if_snake_should_enter_maze
    ldy enemy_snake_table-1,x  ;delay for snake to enter cave
	beq .allow_snake_to_enter_maze
	dey  ;decrease the delay by 1
	tya  ;and store it
	sta enemy_snake_table-1,x  ;delay for snake to enter cave
	beq .goto_perform_snake_entrance
.goto_delay_and_onto_next_snake
    ldy #7
	jsr delay_using_Y
	jmp .goto_next_snake

.goto_perform_snake_entrance
    jsr perform_snake_entrance
.allow_snake_to_enter_maze
    ldy snake_data_pointer
	jsr perform_player_or_enemy_snake_movement  ;enemy snake
.goto_next_snake
    inc temp3
	lda snake_data_pointer
	clc
	adc #30  ;offset to next snake data
	tax
	cpx #92  ;last enemy snake offset
	bcc .each_snake_loop
	rts

;--------------------------------------------------------------------------------------------------
; Check if the enemy snake is at a valid maze-cell boundary, and decide whether to continue
; current direction or change it based on a random choice or advanced AI
; The result is stored in desired_snake_direction

choose_enemy_snake_direction

    ldx snake_colour  ;0: player snake, 1: dangerous enemy snake, 2: weak enemy snake
	bne .continue_enemy_snake_direction  ;branch for an enemy snake only
.end_enemy_snake_direction
    rts

.continue_enemy_snake_direction
    bit maze_cell_boundary_flag
	bmi .end_enemy_snake_direction  ;not at a point in maze cell to check for a direction change
	jsr advance_random_state  ;pseudo-random value in A
	cmp #128
	bcc .end_enemy_snake_direction
	jsr advance_random_state  ;pseudo-random value in A

	ldy maze_level
	cpy #11
	bcc .use_maze_level_for_Y
	ldy #10  ;limit Y if maze level is too big
.use_maze_level_for_Y
    ; increasingly as the maze level increases, perform a move advanced direction choice
    ; by targeting the player egg when the enemy snake is weak (needs more segments to become dangerous again)
    cmp data_random_state_comparison_values-1,y
	bcc .perform_advanced_direction_turn

.perform_random_direction_turn
    jsr advance_random_state  ;pseudo-random value in A
	and #%00000011  ;3
	clc
	adc #1  ;direction value down, up, left, right in A
	ldy current_segment_direction
	cmp data_directions-1,y
	bne *+3  ;skip next instruction
	tya  ;keep current_segment_direction
    sta desired_snake_direction  ;store current_segment_direction or new direction in A
	rts

.perform_advanced_direction_turn
    lda current_segment_direction
	cpx #2  ;2 = weak enemy snake
	beq .move_toward_player_egg
	bit $77
	bpl .try_horizontal_movement

.try_vertical_movement
    ldx #DIRECTION_UP
	ldy screen_row
    cpy player_body_segments+7  ;snake head row
	beq .try_horizontal_movement
	bcs .save_snake_direction
	ldx #DIRECTION_DOWN

.save_snake_direction
    cmp data_directions-1,x
	beq *+4  ;skip next instruction
	stx desired_snake_direction  ;down, up, left, right
    rts

.try_horizontal_movement
    ldx #DIRECTION_LEFT
	ldy screen_column
	cpy player_body_segments+6  ;snake head column
	beq .retry_vertical_movement_or_exit
	bcs .save_snake_direction
	ldx #DIRECTION_RIGHT
	bne .save_snake_direction  ;always branch

.retry_vertical_movement_or_exit
    ldy screen_row
	cpy player_body_segments+7  ;snake head row
	bne .try_vertical_movement

.exit_enemy_snake_direction
    rts

.move_toward_player_egg
    ldx #DIRECTION_RIGHT
	ldy player_egg_location_column
	beq .perform_random_direction_turn  ;branch to random direction if there is no player egg
	cpy screen_column
	beq .check_egg_vertical_position  ;same column, check vertical position
	bcs .save_snake_direction  ;egg is on the right, turn right
	ldx #DIRECTION_LEFT  ;otherwise turn left
	bne .save_snake_direction  ;always branch

.check_egg_vertical_position
    ldx #DIRECTION_DOWN
	ldy player_egg_location_row
	cpy screen_row
	beq .exit_enemy_snake_direction  ;same row, keep current direction
	bcs .save_snake_direction  ;egg is below, turn down
	ldx #DIRECTION_UP  ;otherwise turn up
	bne .save_snake_direction  ;always branch

;--------------------------------------------------------------------------------------------------
;   Pseudo-random number generator 
;   Used for frog placement, enemy decisions, egg/timer variation, etc.
;   Updates the 4-byte pseudo-random state in zero page $77..$7a

advance_random_state

    stx $7c  ;save X

    ; re-calculate new $77 = old $77 + old $7a + old $7b
	lda $77
	sec
	adc $7a
	adc $7b
	sta $77

    ; rotate the old bytes through $78..$7b
	ldx #3
.advance_random_state_loop
    lda $77,x  ;$7a, $79, $78, $77
	sta $78,x  ;$7b, $7a, $79, $78
	dex
	bpl .advance_random_state_loop

    ; leaves A as the old $7a value
	ldx $7c  ; restore X
	rts

;--------------------------------------------------------------------------------------------------
; Initialise pseudo-random starting values

initialise_pseudo_random_values

    lda $9114  ;timer
	sta $78
	lda $9124  ;timer
	sta $7a
	lda #139
	sta $77
	sta $79
	lda #19
	sta $7b
	rts

;--------------------------------------------------------------------------------------------------

update_snake_tick_counters

    ldx #5
.reduce_ticks_by_1_loop
    ldy snake_tick_table,x  ;$33, $32, $31, $30, $2f, $2e
	beq .next_tick_address  ;skip to next tick counter when #0
	cpy #128
	beq .next_tick_address  ;skip to next tick counter when #128
	dey
	sty snake_tick_table,x  ;$33, $32, $31, $30, $2f, $2e reduced by 1
.next_tick_address
    dex
	bpl .reduce_ticks_by_1_loop
	rts

;--------------------------------------------------------------------------------------------------
; disintegrating snake sprites

dead_snake_part_1
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00110000
    !byte %00110000
    !byte %00000000
    !byte %00000000
    !byte %00000000

dead_snake_part_2
    !byte %00000000
    !byte %00000000
    !byte %00101000
    !byte %00111100
    !byte %00111100
    !byte %00101000
    !byte %00101000
    !byte %00000000

dead_snake_part_3
    !byte %00000000
    !byte %00101000
    !byte %00101000
    !byte %00111100
    !byte %00111100
    !byte %00101000
    !byte %00101000
    !byte %00000000

dead_snake_part_4
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00010000
    !byte %00010000
    !byte %00000000
    !byte %00000000
    !byte %00000000

dead_snake_part_5
    !byte %00000000
    !byte %00000000
    !byte %00010100
    !byte %00111100
    !byte %00111100
    !byte %00010100
    !byte %00000000
    !byte %00000000

dead_snake_part_6
    !byte %00000000
    !byte %00010100
    !byte %00010100
    !byte %00111100
    !byte %00111100
    !byte %00010100
    !byte %00010100
    !byte %00000000

;--------------------------------------------------------------------------------------------------
; dead snake animation addresses

dead_snake_part_address_low
	!byte <dead_snake_part_1
	!byte <dead_snake_part_2
	!byte <dead_snake_part_3
	!byte <dead_snake_part_4
    !byte <dead_snake_part_5
	!byte <dead_snake_part_6

dead_snake_part_address_high
	!byte >dead_snake_part_1
	!byte >dead_snake_part_2
	!byte >dead_snake_part_3
	!byte >dead_snake_part_4
	!byte >dead_snake_part_5
	!byte >dead_snake_part_6

;--------------------------------------------------------------------------------------------------

dead_snake_animation

    ldx snake_data_pointer
	sta temp4
	lda player_and_enemy_table,x  ;player or enemy snake number of segments
	sta body_segments
	txa
	clc
	adc #7
	sta temp_snake_data_pointer2  ;points to player or enemy snake head row

.dead_snake_animate_loop
    jsr get_screen_coordinates_for_sprite
	jsr clear_block_at_screen_coordinates

	lda temp4
	and #%00000111  ;7
	lsr
	cmp #2
	bcc .skip_to_next_segment
	tax
	lda dead_snake_part_address_low-2,x
	sta pixel_data_low
	lda dead_snake_part_address_high-2,x
	sta pixel_data_high
	jsr plot_bitmap_on_screen
.skip_to_next_segment
    jsr add_3_to_point_to_next_segment
	dec body_segments
	bne .dead_snake_animate_loop
	rts

;--------------------------------------------------------------------------------------------------

calculate_score_values_for_maze

    lda maze_level
	cmp #21  ;beyond max number of mazes available
	bcc .maze_less_than_21
	lda #20  ; cap maze to 20 for calculating score values
.maze_less_than_21
    pha
	lsr  ;divide maze level by two
	tax  ;becomes X
	tay  ;and Y

    ; calculate score for eating snake head
	lda #0
	sed  ;set to decimal
	clc
.increase_eat_snake_head_score_loop
    adc #2  ;represents increment of 200 points varied by maze level divided by two
	dex
	bpl .increase_eat_snake_head_score_loop
	sta score_for_eat_snake_head

    ; calculate score for eating snake body segment
	clc
	lda #0
.increase_eat_snake_body_score_loop
    adc #1  ;represents increment of 100 points varied by maze level divided by two
	dey
	bpl .increase_eat_snake_body_score_loop
	sta score_for_eat_snake_body

	pla  ;get maze level again
	tax
	lda #0
	sta score_for_eat_egg_high
	sta score_for_eat_egg_low
.increase_eat_egg_score_by_150_per_level_loop
    clc
	lda #80  ;$50 in decimal mode is 50
	adc score_for_eat_egg_low
	sta score_for_eat_egg_low
	lda #1
	adc score_for_eat_egg_high
	sta score_for_eat_egg_high
	dex
	bpl .increase_eat_egg_score_by_150_per_level_loop
	cld  ;clear decimal
	rts

;--------------------------------------------------------------------------------------------------

add_segment_to_player_body

    ldx #5
add_segment_to_player_or_enemy_snake_body
    lda player_and_enemy_table-5,x  ;player or enemy snake number of segments
	cmp #6  ;max segments
	bcs .end_add_segment_to_body

    ; point to the last segment
	asl
	adc player_and_enemy_table-5,x  ;player or enemy snake number of segments
	inc player_and_enemy_table-5,x  ;add 1 to player or enemy snake number of segments
	stx new_last_segment_pointer
	adc new_last_segment_pointer
	sta new_last_segment_pointer
	tax

    ; get the coordinates from the last segment
	lda #0
	sta player_and_enemy_table,x  ;player or enemy snake last segment direction
	lda player_and_enemy_table-2,x  ;player or enemy snake last segment column
	sta screen_column
	lda player_and_enemy_table-1,x  ;player or enemy snake last segment row
	sta screen_row

	jsr check_if_screen_coords_are_on_8_pixel_boundary
	bne .new_segment_coords_not_on_8_pixel_boundary

    ; update the new segment with the last segment coordinates
	ldx new_last_segment_pointer
	lda #0
	sta player_and_enemy_table-3,x  ;player or enemy snake new segment direction
	lda screen_row
	sta player_and_enemy_table+2,x  ;player or enemy snake new segment row
	lda screen_column
	sta player_and_enemy_table+1,x  ;player or enemy snake new segment column

.end_add_segment_to_body
    rts

.new_segment_coords_not_on_8_pixel_boundary
    ldx new_last_segment_pointer
	ldy player_and_enemy_table-3,x  ;player or enemy snake new segment direction
	jsr .update_last_segment_coord
	cpy #DIRECTION_LEFT
	jsr .update_new_segment_coord
	inx  ;switch to pointer to reference next coordinate
	jsr .update_last_segment_coord
	cpy #DIRECTION_UP

.update_new_segment_coord  ;perform check for column and row, save the update
    bne .store_new_segment_coord
	clc
	adc #8
.store_new_segment_coord
    sta player_and_enemy_table+1,x  ;player or enemy snake new segment column or row
	rts

.update_last_segment_coord
    lda player_and_enemy_table-2,x  ;player or enemy snake last segment column or row
	sec
	sbc #6
	and #%11111000  ;248
	clc
	adc #6
	rts

;--------------------------------------------------------------------------------------------------

handle_eat_snake_body_update

    ldx snake_data_pointer
perform_eat_snake_body_update
    jsr get_screen_coordinates_for_last_segment  ;enemy snake
	jsr clear_block_at_screen_coordinates
	ldx temp2  ;points to player or enemy snake
	dec player_and_enemy_table,x  ;player or enemy snake number of segments
	lda player_and_enemy_table,x  ;player or enemy snake number of segments
	cmp #2  ;are head and at least one body segment still left?
	bcs .end_eat_snake_body_update

    ; all body parts eaten, remove the snake head
	lda player_and_enemy_table+6,x  ;player or enemy snake head column
	sta screen_column
	lda player_and_enemy_table+7,x  ;player or enemy snake head row
	sta screen_row
	jsr clear_block_at_screen_coordinates
	clc  ;clear carry to indicate snake is dead
.end_eat_snake_body_update
    rts

;--------------------------------------------------------------------------------------------------

check_if_player_eats_enemy_snake_head

    ldy #2
	ldx snake_data_pointer
.check_player_eats_snake_head_loop
    lda player_and_enemy_table_word+5,y  ;player snake head row, column
	sec
	sbc player_and_enemy_table+7,x  ;enemy snake body row, column
	bcs .player_snake_head_coord_is_bigger
	eor #255
	adc #1
.player_snake_head_coord_is_bigger
    cmp #5
	bcs .end_player_eats_snake_head
	dex
	dey
	bne .check_player_eats_snake_head_loop
	clc  ;snake head is eaten
.end_player_eats_snake_head
    rts

;--------------------------------------------------------------------------------------------------

handle_player_and_enemy_snake_interactions

    ;----------------------------------------------------------------------------------------------
    ; clear the status variables which are set when player / enemy snakes each one another
    ; and used to add to score, and decide if a snake is dead or not
    ldx #11
	lda #0
.clear_interaction_status_loop
    sta $34,x  ;$34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f
	dex
	bpl .clear_interaction_status_loop
	sta $7c

    ;----------------------------------------------------------------------------------------------
    ; check if player snake eats any enemy snake body segments
	ldx #31  ;point to first snake table data
	txa
.check_each_enemy_for_eaten_segments_loop
    sta temp_snake_data_pointer1
	stx snake_data_pointer
	lda enemy_snake_table-1,x  ;delay for snake to enter cave
	bne .exit_check_for_eaten_segments

    ;----------------------------------------------------------------------------------------------
    ; check if player snake eats an enemy body segment
	lda enemy_snake_table,x  ;enemy snake number of segments
	sta body_segments
	ldx snake_data_pointer
	ldy #2
.check_if_player_eats_a_segment_loop
    lda player_and_enemy_table_word+5,y  ;player snake head row, column
	sec
	sbc enemy_snake_table+7,x  ;enemy snake body row, column
	bcs .player_snake_head_coord_is_bigger_2
	eor #255
	adc #1
.player_snake_head_coord_is_bigger_2
    cmp #48
	bcc .get_next_enemy_segment_coordinate

    ;----------------------------------------------------------------------------------------------
    ; a segment can be eaten, update status table
	ldx $7c
	lda #128
	sta $3d,x
	bne .continue_to_next_snake  ;always branch

.get_next_enemy_segment_coordinate
    dex
	dey
	bne .check_if_player_eats_a_segment_loop

	ldx $7c
	lda snake_tick_table,x
	bne .continue_to_next_snake
	jsr check_if_player_eats_enemy_snake_head
	bcs .get_next_enemy_segment_pointer  ;snake head not eaten

    ;----------------------------------------------------------------------------------------------
    ; enemy snake head can be eaten, update status table
	ldx $7c
	lda #128
	sta $34,x
	bne .continue_to_next_snake

.get_next_enemy_segment_pointer
    lda snake_data_pointer
	clc
	adc #3
	sta snake_data_pointer
	dec body_segments
	beq .continue_to_next_snake

	jsr check_if_player_eats_enemy_snake_head
	bcs .get_next_enemy_segment_pointer  ;snake head not eaten

    ;----------------------------------------------------------------------------------------------
    ; enemy snake head can be eaten, update status table
	ldx $7c
	lda #128
	sta $37,x

.continue_to_next_snake
    inc $7c
	lda temp_snake_data_pointer1
	clc
	adc #30  ;offset to next snake data
	tax
	cmp #92  ;last enemy snake offset
	bcc .check_each_enemy_for_eaten_segments_loop

.exit_check_for_eaten_segments
    lda #0
	sta $7c

    ;----------------------------------------------------------------------------------------------
    ; check if any enemy snake eats player body segments
	ldx #31  ;point to first snake table data
.check_if_each_enemy_eats_segments_loop

    stx snake_data_pointer
	lda enemy_snake_table-1,x  ;delay for snake to enter cave
	bne .check_and_handle_snake_body_or_head_being_eaten

	ldx $7c
	lda $3d,x
	bne .skip_to_next_enemy_snake
	lda $31,x
	bne .skip_to_next_enemy_snake

    ;----------------------------------------------------------------------------------------------
    ; check if enemy snake eats any player body segments
	ldx player_body_segments
	dex
	stx body_segments
	ldx #9
.check_if_an_enemy_eats_any_segments_loop

    ;----------------------------------------------------------------------------------------------
    ; check if a player body segment is eaten
    stx temp_snake_data_pointer2
	ldy snake_data_pointer
	lda #2
	sta temp3
.check_if_an_enemy_eats_a_segment_loop
    lda enemy_snake_table+6,y  ;enemy snake head column, row
	sec
	sbc player_and_enemy_table,x  ;player snake body column, row
	bcs .enemy_snake_head_coord_is_bigger
	eor #255
	adc #1
.enemy_snake_head_coord_is_bigger
    cmp #5
	bcs .get_next_segment_pointer
	inx
	iny
	dec temp3
	bne .check_if_an_enemy_eats_a_segment_loop

    ;----------------------------------------------------------------------------------------------
    ; a segment can be eaten, update status table
	ldx $7c
	lda #128
	sta $3a,x
	bne .skip_to_next_enemy_snake  ;always branch

.get_next_segment_pointer
    lda temp_snake_data_pointer2
	clc
	adc #3  ;to point to next player snake body segment data
	tax
	dec body_segments
	bne .check_if_an_enemy_eats_any_segments_loop

.skip_to_next_enemy_snake
    inc $7c
	lda snake_data_pointer
	clc
	adc #30  ;offset to next snake data
	tax
	cmp #92  ;last enemy snake offset
	bcc .check_if_each_enemy_eats_segments_loop

    ;----------------------------------------------------------------------------------------------
    ; check the result of the player and enemy snake eating routines above
.check_and_handle_snake_body_or_head_being_eaten

    lda #0
	sta snake_index  ;0, 1, 2
	ldy #31  ;point to first snake table data
.check_next_snake_loop_2
    sty snake_data_pointer
	ldx snake_index
	lda snake_tick_table,x
	bne .continue_onto_next_snake
	lda $34,x
	beq .eat_snake_body_segment
	lda player_and_enemy_table_word,y  ;enemy snake number of segments
	cmp player_body_segments
	bcc .enemy_snake_is_smaller_than_player_so_eat_it
	jmp handle_player_dies  ;enemy snake is bigger so player dies

.enemy_snake_is_smaller_than_player_so_eat_it
    ldy #137
	sty snake_tick_table,x  ;is #137 (enemy snake is dead) with a tick countdown until it disintegrates

	sta $4f  ;enemy snake number of segments from above
.add_to_score_for_each_enemy_segment_loop
    lda score_for_eat_snake_head
	clc
	jsr update_player_score
	dec $4f
	bne .add_to_score_for_each_enemy_segment_loop

	jsr plot_player_score_on_screen
	jsr add_segment_to_player_body
	jsr reset_developing_egg_status_for_enemy_snake
	jsr prepare_eat_frog_egg_snake_head_sound

.continue_onto_next_snake
    inc snake_index
	lda snake_data_pointer
	clc
	adc #30  ;offset to next snake data
	tay
	cmp #92  ;last enemy snake offset
	bcc .check_next_snake_loop_2

	jmp .check_for_weak_enemy_snake

.eat_snake_body_segment
    lda $37,x
	beq .continue_eat_body_segment
	lda #3
	sta snake_tick_table,x  ;is #3
	lda score_for_eat_snake_body
	clc
	jsr update_player_score
	jsr plot_player_score_on_screen
	jsr reset_developing_egg_status_for_enemy_snake
	ldx #<data_eat_snake_body_1_sound_clip
	ldy #>data_eat_snake_body_1_sound_clip
	jsr prepare_sound_data

	jsr handle_eat_snake_body_update
	ldx snake_index
	bcs .continue_eat_body_segment

    ; all body parts eaten, enemy snake is dead
	lda #128
	sta snake_tick_table,x  ;is #128 (enemy snake is dead)
.continue_eat_body_segment
    lda $31,x
	bne .continue_onto_next_snake
	lda $3a,x
	beq .continue_onto_next_snake
	lda #5
	sta $31,x
	ldx #<data_eat_snake_body_2_sound_clip
	ldy #>data_eat_snake_body_2_sound_clip
	jsr prepare_sound_data

	ldx #0
	lda player_egg_status
	cmp #2  ;(lay egg)
	bne .remove_segment
	stx player_egg_status  ;set to zero (no egg)
	stx player_egg_location_column
.remove_segment
    jsr perform_eat_snake_body_update
	bcs .continue_onto_next_snake
	jmp handle_player_dies

.check_for_weak_enemy_snake
    ldx #31  ;point to first snake table data
.check_for_weak_next_snake_loop
    lda enemy_snake_table,x  ;enemy snake number of segments
	cmp player_body_segments
	bcc .enemy_snake_is_smaller_than_player
	lda #1  ;red colour snake
	!byte $2c  ; $2c is the bit (absolute) opcode
    ; This an intentional technique / trick and gives the code here two 'meanings'
    ; Meaning 1: when lda #1 is reached, the next instructions are bit $02A9 and sta enemy_snake_table+1,x ...
    ;            the bit instruction is meaningless but the next statement sta enemy_snake_table+1,x means #1 is stored
    ; Meaning 2: when the .enemy_snake_is_smaller_than_player branch is taken, the next instructions are
    ;            lda #2 and sta enemy_snake_table+1,x ... (leaving $2c the bit opcode 'stranded') and means #2 is stored
.enemy_snake_is_smaller_than_player
    lda #2  ;change to weak green colour snake
	sta enemy_snake_table+1,x  ;enemy snake colour number
	txa
	clc
	adc #30  ;offset to next snake data
	tax
	cmp #92  ;last enemy snake offset
	bcc .check_for_weak_next_snake_loop

	ldx #2
.check_eaten_all_enemy_snakes_loop
    lda snake_tick_table,x  ;$2e, $2f, $30
	bpl .end_has_not_eaten_all_enemy_snakes
	dex
	bpl .check_eaten_all_enemy_snakes_loop
	jmp player_has_eaten_all_enemy_snakes

.end_has_not_eaten_all_enemy_snakes
    rts

;--------------------------------------------------------------------------------------------------
; Junk bytes not used, they could be replaced with !fill 200,0 but are kept to allow
; a matching binary comparison with the original program
    !source "junk1.asm"

;--------------------------------------------------------------------------------------------------

enemy_snake_egg_sprite
    !byte %00000000
    !byte %00000000
    !byte %00111000
    !byte %11101110
    !byte %10111011
    !byte %11101110
    !byte %00111000
    !byte %00000000


player_snake_egg_sprite
    !byte %00000000
    !byte %00000000
    !byte %00010100
    !byte %11111111
    !byte %01010101
    !byte %11111111
    !byte %00010100
    !byte %00000000

developing_egg_sprite
    !byte %00000000
    !byte %00000000
    !byte %00111100
    !byte %11111111
    !byte %11111111
    !byte %11111111
    !byte %00111100
    !byte %00000000

data_enemy_snake_table_offsets
    !byte 31
	!byte 61
	!byte 91

;--------------------------------------------------------------------------------------------------

clear_egg_variables

    lda #0
	sta enemy_egg_status  ;set to zero (no egg)
	sta player_egg_status  ;set to zero (no egg)
	sta player_egg_location_column  ;set to zero
	rts

;--------------------------------------------------------------------------------------------------
; Set 16-bit egg countdown timer used for enemy / player egg state changes
; Used to delay enemy/player egg state changes (develop / lay / hatch)

set_egg_countdown_timer

    ; build a new 16-bit egg countdown in $21:$20
    lda #1
	lsr $9124  ;timer least significant byte (LSB) of count move to carry
	bcc .timer_carry_is_clear
	lda #0
.timer_carry_is_clear
    sta egg_countdown_high  ;set to 0 or 1 from the VIC timer LSB
	jsr advance_random_state  ;pseudo-random value in A
	and #%00111111  ;63
	ora #%00001111  ;15
	sta egg_countdown_low  ;set to a pseudo-random value in the range 15..63
	rts

;--------------------------------------------------------------------------------------------------

clear_developing_egg_sprite

    lda #<developing_egg_sprite
	sta pixel_data_low
	lda #>developing_egg_sprite
	sta pixel_data_high
	jmp erase_bitmap_on_screen

;--------------------------------------------------------------------------------------------------

update_egg_timers

    jsr advance_random_state  ;pseudo-random value in A
	pha
	ora #%00111111  ;63
	sta $28
	pla
	and #%00000011  ;3
	ora #%00000001  ;1
	sta $29
	lda player_egg_status
	cmp #2  ;lay egg
	bne .end_update_egg_timers
	lda #1
	sta $29
.end_update_egg_timers
    rts

;--------------------------------------------------------------------------------------------------

reset_developing_egg_status_for_enemy_snake

    lda snake_index
	cmp enemy_snake_with_egg
	bne .end_reset_developing_egg_status
	lda enemy_egg_status
	cmp #3  ;hatchable egg
	beq .end_reset_developing_egg_status
	lda #0
	sta enemy_egg_status  ;set to zero (no egg)
.end_reset_developing_egg_status
    rts

;--------------------------------------------------------------------------------------------------

handle_player_and_enemy_snake_eggs

    ldy enemy_egg_status
	bne perform_enemy_snake_egg_actions

    ; no egg, check if one should be developed
	ldx #2
.check_for_dead_snake_loop

    ; a snake must be dead for the other snakes to be able to lay a new egg replacement
    lda snake_tick_table,x  ;0, 1, 2
	cmp #128  ;is snake dead?
	bne .skip_to_another_snake  ;snake is alive, try another one

    ; dead snake candidate is available to replace with a laid egg
	stx reincarnate_dead_snake_with_egg  ;0, 1, 2

    ; check which (alive) snake can lay an egg
	ldx #2
.check_candidate_snake_to_lay_egg_loop

    ; check if a snake has died recently, need to wait a bit before an egg can be laid to replace it
    lda snake_tick_table,x  ;0, 1, 2
	bmi .skip_to_next_candidate_snake  ;can't lay a replacement egg immediately after snake has died

	ldy data_enemy_snake_table_offsets,x
	lda player_and_enemy_table_word,y  ;player or enemy snake number of segments
	cmp #3
	bcc .skip_to_next_candidate_snake  ;not enough segments to allow an egg to be laid

	lda player_and_enemy_table_word+4,y  ;snake active indicator
	bmi .skip_to_next_candidate_snake

    ; develop a new egg
	stx enemy_snake_with_egg  ;0, 1, 2
	inc enemy_egg_status  ;status is 1 (develop egg)
	jsr set_egg_countdown_timer

.goto_perform_player_egg_actions
    jmp perform_player_egg_actions

.skip_to_next_candidate_snake
    dex
	bpl .check_candidate_snake_to_lay_egg_loop
	bmi .goto_perform_player_egg_actions  ;always branch

.skip_to_another_snake
    dex
	bpl .check_for_dead_snake_loop
	bmi .goto_perform_player_egg_actions  ;always branch

;--------------------------------------------------------------------------------------------------

perform_enemy_snake_egg_actions

    dec egg_countdown_low
	bne .check_egg_status_for_next_actions
	dec egg_countdown_high
	bpl .check_egg_status_for_next_actions
	cpy #3  ;check if enemy_egg_status = 3 (hatchable egg)
	bne .egg_not_hatchable

    ; hatch the enemy snake egg and turn it into a snake
	ldy reincarnate_dead_snake_with_egg  ;0, 1, 2
	lda #0
	sta snake_tick_table_word,y  ;$30, $2f, $2e
	sta enemy_egg_status  ;set to zero (no egg)

    ; set the number of snake segments
	ldx data_enemy_snake_table_offsets,y
	lda #1
	tay
	sta enemy_snake_table,x  ;enemy snake number of segments (just a snake head to start with)

    ; set the snake colour
	lda #2
	cmp player_body_segments
	bcs *+3  ;skip next instruction
	iny  ;change to weak green colour snake
    tya  ;keep with normal red colour snake
	sta enemy_snake_table+1,x  ;enemy snake colour number

    ; update the snake head coordinates from the egg coordinates
	ldy #2
.update_snake_head_coords_from_egg_loop
    lda $0022,y  ;get $24 (enemy_egg_location_row), $23 (enemy_egg_location_column), $22 (segment_direction)
	sta enemy_snake_table+7,x  ;enemy snake head row, column, direction
	dex
	dey
	bpl .update_snake_head_coords_from_egg_loop

    ; add the body segment with its own coordinates
	txa
	clc
	adc #8
	tax
	jsr add_segment_to_player_or_enemy_snake_body  ;has the last segment coordinates at this point
	jmp .update_screen_coords_from_egg_location

.egg_not_hatchable
    cpy #1
	bne .egg_is_laid_and_detaches_from_mother_snake

    ; egg status is 1 (develop egg)
	jsr set_egg_countdown_timer
	inc enemy_egg_status  ;update 1 (develop egg) to 2 (lay egg)
	bne .point_to_last_segment_with_egg  ;always branch

.egg_is_laid_and_detaches_from_mother_snake

    ; egg status is 2 (lay egg)
    ldy enemy_snake_with_egg
	ldx data_enemy_snake_table_offsets,y
	jsr get_screen_coordinates_for_last_segment  ;enemy snake
	jsr check_if_screen_coords_are_on_8_pixel_boundary
	bne .mother_snake_lays_egg  ;not on 8 pixel boundary
	inc egg_countdown_high
	inc egg_countdown_low
	bne .check_egg_status_for_next_actions  ;always branch

.mother_snake_lays_egg

    ; detach egg from mother snake, is hatchable now
    jsr set_egg_countdown_timer
	inc enemy_egg_status  ;update 2 (lay egg) to 3 (hatchable egg)
	ldy enemy_snake_with_egg
	ldx data_enemy_snake_table_offsets,y
	jsr perform_eat_snake_body_update  ;removes segment from the mother snake

    ; set egg screen coordinates
	ldx #2
.update_enemy_egg_location_row_col_loop
    lda screen_coords_table,x  ;get $0f (screen_row), $0e (screen_column), $0d (segment_direction)
	sta $22,x  ;update $24 (enemy_egg_location_row), $23 (enemy_egg_location_column), $22 (segment_direction)
	dex
	bpl .update_enemy_egg_location_row_col_loop

.check_egg_status_for_next_actions
    ldy enemy_egg_status
	cpy #1  ;develop egg
	beq perform_player_egg_actions
	cpy #3  ;hatchable egg
	bne .point_to_last_segment_with_egg

    ; enemy egg is hatchable, check if it gets eaten by player snake!
	ldx #2
.check_if_player_snake_eat_egg_loop
    lda player_and_enemy_table+5,x  ;player snake head row, column
	sec
    sbc $22,x  ;subtract $24 (enemy_egg_location_row), $23 (enemy_egg_location_column)
	bcs .player_coord_is_bigger
	eor #255
	adc #1
.player_coord_is_bigger
    cmp #5  ;check if column or row is in range
	bcs .update_screen_coords_from_egg_location  ;egg not eaten
	dex
	bne .check_if_player_snake_eat_egg_loop

    ; both coordinates above are in range so egg is eaten
    ; clear egg from screen, add a segment to the player snake and add it to player score
	stx enemy_egg_status  ;X is zero (no egg) at this point
	lda enemy_egg_location_column
	sta screen_column
	lda enemy_egg_location_row
	sta screen_row
	jsr clear_block_at_screen_coordinates

	jsr add_segment_to_player_body
	lda score_for_eat_egg_low
	jsr update_player_score_low_amount
	lda score_for_eat_egg_high
	jsr update_player_score
	jsr plot_player_score_on_screen
	jsr prepare_eat_frog_egg_snake_head_sound
	jmp perform_player_egg_actions

.update_screen_coords_from_egg_location
    lda enemy_egg_location_column
	sta screen_column
	lda enemy_egg_location_row
	sta screen_row
	bne .plot_enemy_egg_on_screen

.point_to_last_segment_with_egg
    ; point to the last segment for the snake with a developing egg
    ldy enemy_snake_with_egg
	ldx data_enemy_snake_table_offsets,y
	stx temp_snake_data_pointer2
	lda enemy_snake_table,x  ;enemy snake number of segments
	asl
	adc enemy_snake_table,x  ;enemy snake number of segments
	adc temp_snake_data_pointer2
	adc #4
	sta temp_snake_data_pointer2
	jsr get_screen_coordinates_for_sprite

.plot_enemy_egg_on_screen
    ; clear the developing egg and plot a laid egg
    jsr clear_developing_egg_sprite
	lda #<enemy_snake_egg_sprite
	sta pixel_data_low
	lda #>enemy_snake_egg_sprite
	sta pixel_data_high
	jsr plot_bitmap_on_screen

;--------------------------------------------------------------------------------------------------

perform_player_egg_actions

    lda player_egg_status
	bne .player_egg_exists
	lda player_lives
	cmp #9  ;player lives
	bcs .no_player_eggs_at_max_lives

.update_player_egg_to_next_status
    inc player_egg_status  ;update to next egg status
	jmp update_egg_timers
.no_player_eggs_at_max_lives
    rts

; player egg is being developed, to be laid, is hatchable
.player_egg_exists
    cmp #3  ; (hatchable egg)
	bne .player_egg_not_hatchable_yet

    ; player egg is hatchable, check if it gets eaten!
	ldx #31  ;point to first snake table data
.check_if_enemy_snakes_eat_egg_loop
    ldy #2
	stx snake_data_pointer
.check_if_enemy_snake_eat_egg_loop
    lda enemy_snake_table+7,x  ;enemy snake head row
	sec
	sbc $002a,y
	bcs .enemy_snake_coord_is_bigger
	eor #255
	adc #1
.enemy_snake_coord_is_bigger
    cmp #5
	bcs .move_to_next_snake  ;player egg is not eaten by this enemy snake, try another one
	dex
	dey
	bne .check_if_enemy_snake_eat_egg_loop

    ; both enemy snake coordinates from one of the snakes above are in range so egg is eaten
    ; clear egg from screen and add a segment to the enemy snake
	lda player_egg_location_column
	sta screen_column
	lda player_egg_location_row
	sta screen_row
	lda #0
	sta player_egg_location_column
	sta player_egg_status  ;set to zero (no egg)
	jsr clear_block_at_screen_coordinates
	jsr prepare_eat_frog_egg_snake_head_sound

	lda snake_data_pointer
	clc
	adc #5
	tax  ;player or enemy snake number of segments
	jmp add_segment_to_player_or_enemy_snake_body

.move_to_next_snake
    lda snake_data_pointer
	clc
	adc #30  ;offset to next snake data
	tax
	cmp #92  ;last enemy snake offset
	bcc .check_if_enemy_snakes_eat_egg_loop
	bcs perform_plot_player_egg_on_screen  ;always branch, egg not eaten

.player_egg_not_hatchable_yet

    dec $28
	bne .check_for_laying_player_egg
	dec $29
	bpl .check_for_laying_player_egg
	ldx #0
	jsr get_screen_coordinates_for_last_segment  ;player snake
	jsr check_if_screen_coords_are_on_8_pixel_boundary
	bne .player_snake_lays_egg  ;not on 8 pixel boundary
	inc $29
	inc $28
	bne .check_for_laying_player_egg

.player_snake_lays_egg
    jsr .update_player_egg_to_next_status  ;update 1 (develop egg) to 2 (lay egg), or 2 (lay egg) to 3 (hatchable egg)
	lda player_egg_status
	cmp #2  ;(lay egg)
	beq .check_for_laying_player_egg

    ; detach egg from mother snake, is hatchable now
	ldx #0
	jsr perform_eat_snake_body_update  ;removes segment from the mother snake
	bcs .player_snake_survives_laying_egg

    ; player snake just had one body segment which was the egg, now removed, so the player snake dies
    ; the egg still hatches though and a player life is added back again later
	ldx #0
	jsr get_screen_coordinates_for_last_segment  ;player snake
	jsr set_egg_screen_column_row
	jmp clear_maze_objects_and_player_loses_life

.player_snake_survives_laying_egg
    jsr set_egg_screen_column_row
	bne perform_plot_player_egg_on_screen

.check_for_laying_player_egg
    lda player_egg_status
	cmp #3  ;hatchable egg
	beq perform_plot_player_egg_on_screen
	cmp #1  ;develop egg
	beq .end_screen_coordinates_for_last_segment

    ; lay the developing egg for the player
	lda player_body_segments
	asl
	adc player_body_segments
	adc #4
	sta temp_snake_data_pointer2  ;points to the segment holding the egg to be laid
	jsr get_screen_coordinates_for_sprite  ;get this screen coordinate for plotting on screen
	jmp .plot_player_egg_on_screen

;--------------------------------------------------------------------------------------------------

perform_plot_player_egg_on_screen

    lda player_egg_location_column
	sta screen_column
	lda player_egg_location_row
	sta screen_row
.plot_player_egg_on_screen
    jsr clear_developing_egg_sprite
	lda #<player_snake_egg_sprite
	sta pixel_data_low
	lda #>player_snake_egg_sprite
	sta pixel_data_high
	jmp plot_bitmap_on_screen

;--------------------------------------------------------------------------------------------------

get_screen_coordinates_for_last_segment

    lda player_and_enemy_table,x  ;player or enemy snake number of segments
	stx temp2
	asl
	adc player_and_enemy_table,x  ;player or enemy snake number of segments
	adc temp2
	tax  ;player or enemy snake pointer to last segment

	ldy #2
.get_last_segment_screen_coords_loop
    lda player_and_enemy_table+4,x  ;get player or enemy snake last segment row, column, direction
	sta screen_coords_table,y  ;update $0f (screen_row), $0e (screen_column), $0d (segment_direction)
	dex
	dey
	bpl .get_last_segment_screen_coords_loop
.end_screen_coordinates_for_last_segment
    rts

;--------------------------------------------------------------------------------------------------

set_egg_screen_column_row

    lda screen_column
	sta player_egg_location_column
	lda screen_row
	sta player_egg_location_row
	lda current_segment_direction
	sta $2a
	rts

;--------------------------------------------------------------------------------------------------
; frog sprite data

data_frog_top_left
    !byte %00001010
    !byte %00101010
    !byte %00111010
    !byte %00101010
    !byte %11101010
    !byte %11101010
    !byte %11101010
    !byte %00101010

data_frog_top_right
    !byte %00000000
    !byte %10000000
    !byte %11000000
    !byte %10000000
    !byte %10110000
    !byte %10110000
    !byte %10110000
    !byte %10000000

data_frog_bottom_left
    !byte %00011010
    !byte %10010000
    !byte %00010000
    !byte %10010000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

data_frog_bottom_right
    !byte %01000000
    !byte %01100000
    !byte %01000000
    !byte %01100000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

;--------------------------------------------------------------------------------------------------

data_frog_column_increments
    !byte 0
	!byte 240
	!byte 224
	!byte 240
	!byte 0
	!byte 16
	!byte 32
	!byte 16
	!byte 0
	!byte 240
	!byte 0
	!byte 16

data_frog_row_increments
    !byte 224
	!byte 240
	!byte 0
	!byte 16
	!byte 32
	!byte 16
	!byte 0
	!byte 240
	!byte 240
	!byte 0
	!byte 16
	!byte 0

data_to_switch_frog_increments
    !byte 2
	!byte 0
data_to_get_frog_column_increments
    !byte 8
	!byte 0
	!byte 9
	!byte 0
	!byte 10
	!byte 0
	!byte 11

;--------------------------------------------------------------------------------------------------

set_frog_to_display_on_screen

    lda #%10000000  ;128
	sta frog_display
goto_advance_random_state
    jsr advance_random_state  ;pseudo-random value in A
	and #%01111111  ;127
	ora #%00011111  ;31
	sta frog_display_duration
	rts

;--------------------------------------------------------------------------------------------------

check_if_frog_eats_egg

    stx screen_column
	sty screen_row

	ldx #1
.check_if_frog_eats_egg_loop
    lda screen_column,x
	sec
	sbc frog_location_column,x  ;subtracts $41 (frog_location_column), $42 (frog_location_row)
	bcs .egg_coord_is_bigger
	eor #255
	adc #1
.egg_coord_is_bigger
    cmp #9
	bcs .egg_not_eaten_keep_egg_status_as_is
	dex
	bpl .check_if_frog_eats_egg_loop

	jsr clear_block_at_screen_coordinates  ;egg is cleared from screen
	lda #0  ;egg is eaten, the new egg status (no egg) is returned in A
	rts

.egg_not_eaten_keep_egg_status_as_is
    lda #3  ;egg is not eaten, the egg status (hatchable egg) is returned in A (remains as hatchable egg)
	rts

;--------------------------------------------------------------------------------------------------

handle_frog_actions

    bit frog_display
	bpl .frog_is_on_screen
	jmp .continue_frog_actions

.frog_is_on_screen
    ldx #6
	stx snake_data_pointer
	dex  ;points to player snake head direction
	bne .check_if_player_eats_frog  ;always branch to check if player eats frog first

    ; check if frog is eaten by player snake or an enemy snake
.check_if_frog_is_eaten_by_any_snake_loop
    stx snake_data_pointer

.check_if_player_eats_frog
    ldy #1
.check_if_frog_is_eaten_loop
    lda player_and_enemy_table+2,x  ;player or enemy snake row, column
	sec
	sbc frog_location_column_word,y  ;$42 (frog_location_row), $41 (frog_location_column)
	bcs .player_or_enemy_snake_coord_is_bigger
	eor #255
	adc #1
.player_or_enemy_snake_coord_is_bigger
    cmp #7
	bcs .next_snake_and_loop
	dex
	dey
	bpl .check_if_frog_is_eaten_loop

	ldx snake_data_pointer
	cpx #6
	bne .skip_frog_is_eaten_by_player

    ; player eats frog, add to score
	lda #5  ;represents 500 points for eating a frog
	clc
	jsr update_player_score
	jsr plot_player_score_on_screen
	ldx #5
	bne .add_segment_to_snake_and_remove_frog  ;always branch

.skip_frog_is_eaten_by_player
    ldy #0  ;enemy snake 1
	cpx #36  ;enemy snake 1
	beq .check_tick_and_goto_next_snake
	iny  ;enemy snake 2
	cpx #66  ;enemy snake 2
	beq .check_tick_and_goto_next_snake
	iny  ;enemy snake 3
.check_tick_and_goto_next_snake

    ; determine if the enemy snake is able to eat snake (e.g. is alive)
    lda snake_tick_table_word,y  ;$30, $2f, $2e
	bmi .next_snake_and_loop

.add_segment_to_snake_and_remove_frog

    ;player or enemy snake eats frog
    jsr add_segment_to_player_or_enemy_snake_body  ;is player body in this case
	jsr plot_frog_sprite_on_screen
	jsr prepare_eat_frog_egg_snake_head_sound
	jmp set_frog_to_display_on_screen

.next_snake_and_loop
    lda snake_data_pointer
	clc
	adc #30  ;offset to next snake data
	tax
	cpx #97  ;last snake?
	bcc .check_if_frog_is_eaten_by_any_snake_loop

    ; check if frog eats a hatchable player egg or enemy snake egg
	lda player_egg_status
	cmp #3  ;hatchable egg
	bne .check_enemy_egg_is_hatchable

    ;check if frog eats player egg
	ldx player_egg_location_column
	ldy player_egg_location_row
	jsr check_if_frog_eats_egg
	bne .check_enemy_egg_is_hatchable  ;player egg remains as 3 (hatchable egg), so check enemy egg
	sta player_egg_status  ;is zero (no egg)
	sta player_egg_location_column

.check_enemy_egg_is_hatchable
    lda enemy_egg_status
	cmp #3  ;hatchable egg
	bne .continue_frog_actions

    ;check if frog eats enemy egg
	ldx enemy_egg_location_column
	ldy enemy_egg_location_row
	jsr check_if_frog_eats_egg
	sta enemy_egg_status  ;is zero (no egg) or 3 (hatchable egg)

.continue_frog_actions
    dec frog_display_duration
	beq .frog_appears_on_screen_with_sound
	bit frog_display
	bpl .goto_plot_frog_on_screen
	rts

.frog_appears_on_screen_with_sound
    ldx #<data_frog_ribbit_sound_clip
	ldy #>data_frog_ribbit_sound_clip
	jsr prepare_sound_data

	jsr goto_advance_random_state
	bit frog_display
	bpl .check_for_hatchable_egg_for_frog_to_eat

	asl frog_display  ;clear bit 7
	jsr advance_random_state  ;pseudo-random value in A
	ldy #20
	ldx #4
	and #3
	beq .hex_77_is_zero
	cmp #2
	bcs .hex_77_is_greater_than_2
	ldy #164
	ldx #0
.hex_77_is_zero
    sty frog_location_row
	stx $44
	jsr advance_random_state  ;pseudo-random value in A
	and #112
	clc
	adc #20
	sta frog_location_column
.goto_plot_frog_on_screen
    jmp .goto_start_plot_frog

.hex_77_is_greater_than_2
    ldx #4
	ldy #6
	cmp #2
	beq *+6  ;skip next two instructions
	ldx #164
	ldy #2
    stx frog_location_column
	sty $44
	jsr advance_random_state  ;pseudo-random value in A
	and #48
	clc
	adc #20
	sta frog_location_row
	bne .goto_plot_frog_on_screen

.check_for_hatchable_egg_for_frog_to_eat
    jsr plot_frog_sprite_on_screen
	ldx player_egg_location_column
	ldy player_egg_location_row
	lda player_egg_status
	cmp #3  ;hatchable egg
	beq .check_if_frog_eats_egg
	ldx enemy_egg_location_column
	ldy enemy_egg_location_row
	lda enemy_egg_status
	cmp #3  ;hatchable egg
	bne .no_hatchable_egg_for_frog_to_eat

.check_if_frog_eats_egg

    ; check if frog eats player or enemy snake egg (tries player egg first)
    stx screen_column
	sty screen_row

	ldx #1
.check_if_frog_is_eats_egg_loop
    ldy data_to_switch_frog_increments,x  ;Y is 0 or 2
	lda frog_location_column,x
	sec
	sbc screen_column,x
	bcs .frog_coord_is_bigger
	eor #255
	adc #1
	iny
	iny
	iny
	iny  ;Y is 4 or 6 at this point
.frog_coord_is_bigger
    cmp #25
	bcs .frog_does_not_eat_egg
	pha
	lda data_to_get_frog_column_increments,y  ;Y could be 0, 2, 4, 6
	tay  ;new Y from data
	pla
	cmp #9
	bcs .frog_does_not_eat_egg
	dex
	bpl .check_if_frog_is_eats_egg_loop

.no_hatchable_egg_for_frog_to_eat
    ldy #255
	jsr advance_random_state  ;pseudo-random value in A
	cmp #85
	bcc .calculate_frog_column_row_increment_pointer
	iny
	cmp #170
	bcc *+3  ;skip next instruction
	iny
.calculate_frog_column_row_increment_pointer
    tya
	clc
	adc $44
	and #7
	sta $44
	tay

.frog_does_not_eat_egg
    lda frog_location_column
	clc
	adc data_frog_column_increments,y
	cmp #165
	bcc *+5  ;skip next instruction
.goto_set_frog_to_display_on_screen
    jmp set_frog_to_display_on_screen

    sta frog_location_column
	lda frog_location_row
	clc
	adc data_frog_row_increments,y
	cmp #165
	bcs .goto_set_frog_to_display_on_screen
	cmp #20
	bcc .goto_set_frog_to_display_on_screen
	sta frog_location_row
.goto_start_plot_frog
    lda #0
	!byte $2c  ; $2c is the bit (absolute) opcode
    ; This an intentional technique / trick and gives the code here two 'meanings'
    ; Meaning 1: when lda #0 is reached, the next instructions are bit $80a9 and sta $45 ...
    ;            the bit instruction is meaningless but the next statement sta $45 means #0 is stored
    ; Meaning 2: when the plot_frog_sprite_on_screen branch is taken, the next instructions are
    ;            lda #128 and sta $45 ... (leaving $2c the bit opcode 'stranded') and means #128 is stored
plot_frog_sprite_on_screen
    lda #128
	sta $45
	lda frog_location_column
	sta screen_column
	lda frog_location_row
	sta screen_row
	lda #<data_frog_top_left
	ldx #>data_frog_top_left
	jsr .goto_prepare_and_plot_bitmap_on_screen
	lda screen_column
	clc
	adc #8
	sta screen_column
	lda #<data_frog_top_right
	ldx #>data_frog_top_right
	jsr .goto_prepare_and_plot_bitmap_on_screen
	lda screen_row
	clc
	adc #8
	sta screen_row
	lda #<data_frog_bottom_right
	ldx #>data_frog_bottom_right
	jsr .goto_prepare_and_plot_bitmap_on_screen
	lda screen_column
	sec
	sbc #8
	sta screen_column
	lda #<data_frog_bottom_left
	ldx #>data_frog_bottom_left
.goto_prepare_and_plot_bitmap_on_screen
    sta pixel_data_low
	stx pixel_data_high
	bit $45
	bpl .goto_plot_bitmap_on_screen_2
	jmp erase_bitmap_on_screen

.goto_plot_bitmap_on_screen_2
    jmp plot_bitmap_on_screen

;--------------------------------------------------------------------------------------------------

data_vic_system_registers
    !byte %00001100  ;_VIC_SCREEN_LEFT_EDGE = $9000  ;36864 bits 0-6 horizontal centering, bit 7 sets interlace scan
	!byte %00100110  ;_VIC_SCREEN_TOP_EDGE = $9001  ;36865 vertical centering
	!byte %10010110  ;_VIC_CR2 = $9002  ;36866, used for setting number of columns displayed
                     ;  bit 7: see _VIC_CR5 below
                     ;  bit 6-0: 22 means 22 characters per column
	!byte %00010111  ;_VIC_CR3 = $9003  ;36867, used for setting number of rows displayed
                     ;  bit 7: raster beam location bit 0 (n/a here)
                     ;  bit 6-1: 22 means 11 character lines / rows
                     ;  bit 0: 1 tall characters (16-pixels tall by 8 pixels wide)
	!byte 0  ;_VIC_CR4 = $9004  ;36868, raster beam location bits (n/a here)

	!byte %10001100  ;_VIC_CR5 = $9005  ;36869 provides the screen and pixel bitmap memory addresses
                     ;  bit 7-4: 1000. Bit 7 needs to viewed as 0 (see COMPUTE! Mapping the VIC page 129) so these bits
                     ;  are now 0000. To complete the 14-bit screen map address location, _VIC_CR2 bit 7 is added (is 1)
                     ;  and completes with bits 0 0000 0000. The result is 0000 10 0000 0000 which means the
                     ;  screen matrix is located at $0200 (512), and colour map at $9600 (38400)
                     ;  bit 3-0: 1100 means the 8-byte pixel bitmaps are located at $1000 (4096)
                     ;  also see explanations at _BITMAP_GRID and initialise_bitmap_grid_index

	!byte 0  ;_VIC_CR6 = $9006  ;36870  light pen horizontal screen location (n/a here)
	!byte 0  ;_VIC_CR7 = $9007  ;36871  light pen vertical screen location (n/a here)
	!byte 255  ;_VIC_CR8 = $9008  ;36872  paddle X location (n/a here)
	!byte 255  ;_VIC_CR9 = $9009  ;36873  paddle Y location (n/a here)
	!byte 0  ;_VIC_SOUND_BASS = $900a  ;36874
	!byte 0  ;_VIC_SOUND_ALTO = $900b  ;36875
	!byte 0  ;_VIC_SOUND_SOPRANO = $900c  ;36876
	!byte 0  ;_VIC_SOUND_NOISE = $900d  ;36877
	!byte %00100000  ;_VIC_AUX_COLOUR = $900e  ;36878 bit 7-4 aux colour is 2 for red
                     ;_VIC_VOLUME = $900e  ;36878 bit 3-0 is 0 for no volume
	!byte %00001110  ;_VIC_BG_BORDER_COL = $900f  ;36879
                     ;  bit 7-4 is 0 for black background
                     ;  bit 3-0 is 14 for blue border

;--------------------------------------------------------------------------------------------------
; Initialise Vic system registers and timers

init_system_registers_and_timers

    ldy #15
.init_data_loop
    lda data_vic_system_registers,y
	sta $9000,y  ;store in $9000 to $900f
	dey
	bpl .init_data_loop

    ; set auxiliary timers
	lda #64
	sta $911b
	sta $912b

    ; set timers
	lda #255
	sta $9116
	sta $9117
	sta $9126
	sta $9127
	rts

;--------------------------------------------------------------------------------------------------

draw_maze_and_set_enemy_snake_start_position

    jsr initialise_zero_page
	jsr draw_maze_on_screen
	jmp set_enemy_snake_start_position

;--------------------------------------------------------------------------------------------------
; Start game by pressing joystick fire button or align screen position with joystick direction

read_joystick_to_start_game

    jsr read_joystick
	bcc .handle_joystick_action  ;valid joystick action can be handled
	rts

.handle_joystick_action
    cmp #JOY_FIRE
	bne .handle_joystick_movement_for_screen_alignment
    
    ; fire button pressed, start the game
	jsr clear_all_sound_channels
	jmp start_game_play

.handle_joystick_movement_for_screen_alignment

    ; allow the screen to be centered vertically and horizontally
    ldx _VIC_SCREEN_LEFT_EDGE
	ldy _VIC_SCREEN_TOP_EDGE
	cmp #JOY_UP
	bne .check_screen_align_down
	dey
.save_screen_alignment
    stx _VIC_SCREEN_LEFT_EDGE
	sty _VIC_SCREEN_TOP_EDGE
	rts

.check_screen_align_down
    cmp #JOY_DOWN
	bne .check_screen_align_right
	iny
	jmp .save_screen_alignment

.check_screen_align_right
    cmp #JOY_RIGHT
	bne .set_screen_align_left
	inx
	jmp .save_screen_alignment

.set_screen_align_left
    dex
	jmp .save_screen_alignment

;--------------------------------------------------------------------------------------------------

data_scrolling_heading_message

    !pet "licensed"
	!byte $60
	!pet "from"
	!byte $60
	!pet "broderbund"
	!byte $60
	!pet "software"
	!byte $60
	!byte $60
	!pet "copyright"
	!byte $60
	!byte $71
	!byte $79
	!byte $78
	!byte $72
	!byte $60
	!pet "by"
	!byte $60
	!pet "antirom"
	!byte $60
	!byte $60
	!pet "software"
	!byte $60
	!byte $60
	!byte $60
	!byte 0

;--------------------------------------------------------------------------------------------------

prepare_scroll_message

    ; set the message storage area and initial index
    lda #<scroll_message_store
	sta text_data_low
	lda #>scroll_message_store
	sta text_data_high

	lda #255
	sta scroll_message_index

    ; store the first part of the scroll message
	bne .store_scroll_message_line  ;always branch

;--------------------------------------------------------------------------------------------------

display_scroll_message

    ldx scroll_X_position
	ldy #8
	jsr plot_heading_on_screen  ;uses the scroll_message_store for the heading scroll message

	ldx #168
	stx screen_column
	jsr plot_block_at_screen_coordinates

    ; move the screen position on 2 pixels
	ldx scroll_X_position
	dex
	dex
	beq .prepare_more_scroll_data_for_message  ;8 bits has been scrolled, get next message characters (line)
	stx scroll_X_position
	rts

.prepare_more_scroll_data_for_message

    ldx #0
	stx screen_column
	jsr plot_block_at_screen_coordinates

    ;----------------------------------------------------------------------------------------------
    ; store 20 characters of the message line in the scroll_message_store
    ; starting from the last index position to display later via display_scroll_message
.store_scroll_message_line

    ldx #8
	stx scroll_X_position
	ldy #0
	ldx scroll_message_index
	inx
	cpx #73  ;length of scroll message
	bcc .continue_scroll_message

	ldx #0  ;reset scroll message index
.continue_scroll_message
    stx scroll_message_index

    ; store one line of the scroll message starting from the scroll message index
.store_scroll_message_loop

    lda data_scrolling_heading_message,x  ;read scroll message data using index
	bne .store_scroll_message  ;message terminates with a zero
	ldx #0  ;reset scroll message index if message ends in the plot message loop
	lda data_scrolling_heading_message,x  ;read scroll message data from start using index
.store_scroll_message
    sta scroll_message_store,y

	inx  ;next message data index
	iny  ;next storage position for message character
	cpy #20  ; 20 message characters stored at a time (with terminator below)
	bcc .store_scroll_message_loop

    ; add terminator to the end of the stored message
	lda #0
	sta scroll_message_store,y
	rts

;--------------------------------------------------------------------------------------------------

data_heading_publisher
	!pet "creative"
	!byte $60
	!byte $60
	!byte $60
	!pet "software"
	!byte $00

data_heading_presents_title
	!pet "presents"
	!byte $00

data_heading_game_title
	!pet "serpentine"
	!byte $00

;--------------------------------------------------------------------------------------------------

display_opening_title_screen

    jsr set_screen_base_colours
	jsr initialise_bitmap_grid_index  ;the first and the only necessary call to this routine
	jsr clear_screen_and_add_heading_block

    ; prepare start up sound
	jsr clear_all_sound_channels
	lda #%00101010  ;aux colour red, volume 10
	sta _VIC_VOLUME
	ldx #<data_starting_game_on_sound_clip
	ldy #>data_starting_game_on_sound_clip
	jsr prepare_sound_data

    ; display "creative software" in heading
	lda #<data_heading_publisher
	sta text_data_low
	lda #>data_heading_publisher
	sta text_data_high
	ldx #12
	ldy #0
	jsr plot_heading_on_screen

    ; play opening short tune on game start
	lda #38
	sta sound_loop_counter
.play_opening_tune_loop
    jsr play_sounds
	ldy #25
	jsr delay_using_Y
	dec sound_loop_counter
	bne .play_opening_tune_loop

    ; display "presents" text in heading
	lda #<data_heading_presents_title
	sta text_data_low
	lda #>data_heading_presents_title
	sta text_data_high
	ldx #56
	ldy #8
	jsr plot_heading_on_screen

    ; continue opening short tune on game start
	lda #39
	sta sound_loop_counter
.play_short_tune_loop
    jsr play_sounds
	ldy #25
	jsr delay_using_Y
	dec sound_loop_counter
	bne .play_short_tune_loop

    ; delay before continuing
	ldx #4
.delay_using_X_4_2
    ldy #255
	jsr delay_using_Y
	dex
	bne .delay_using_X_4_2

	jsr draw_blocked_out_heading_lines

    ; display "serpentine" in heading
	lda #<data_heading_game_title
	sta text_data_low
	lda #>data_heading_game_title
	sta text_data_high
	ldx #48
	ldy #0
	jsr plot_heading_on_screen

	jsr draw_maze_and_set_enemy_snake_start_position
	jsr prepare_scroll_message

.play_main_theme_tune

    ; prepare theme tune sound
    ldx #<data_main_theme_tune_sound_clip
	ldy #>data_main_theme_tune_sound_clip
	jsr prepare_sound_data

	lda #128
	sta sound_loop_counter
.scroll_and_play_main_theme_loop

    jsr display_scroll_message
	jsr handle_enemy_snake_movement
	jsr read_joystick_to_start_game  ;exits loop to start game, see start_game_play
	jsr play_sounds

	dec sound_loop_counter
	bne .scroll_and_play_main_theme_loop

	beq .play_main_theme_tune  ;always branch

;--------------------------------------------------------------------------------------------------

data_eat_frog_egg_enemy_head_sound_clip_extra
    !byte $01, $ca, $01, $cc, $01, $ce, $01, $d0
    !byte $01, $d2, $01, $d4, $01, $d6, $01, $d8
    !byte $01, $da, $01, $de, $01, $e2, $01, $e6
    !byte $01, $eb, $01, $f0, $01, $f5, $01, $fa
    !byte $01, $fc, $01, $fd, $ff

data_eat_frog_egg_enemy_head_sound_clip
	!byte SOUND_NOISE
	!byte <data_eat_frog_egg_enemy_head_sound_clip_extra
	!byte >data_eat_frog_egg_enemy_head_sound_clip_extra
	!byte $ff

data_frog_ribbit_sound_clip_extra
	!byte $03, $8c, $01, $8d, $01, $00, $01, $8c
	!byte $01, $8d, $ff

data_frog_ribbit_sound_clip
	!byte SOUND_BASS
	!byte <data_frog_ribbit_sound_clip_extra
	!byte >data_frog_ribbit_sound_clip_extra
	!byte $ff

data_player_dies_sound_clip_extra
	!byte $04, $dc, $01, $00, $04, $d2, $01, $00
	!byte $04, $c8, $01, $00, $04, $c3, $01, $00
	!byte $06, $be, $01, $00, $06, $b4, $01, $00
	!byte $06, $aa, $01, $00, $06, $a0, $01, $00
	!byte $0a, $96, $ff

data_player_dies_sound_clip
	!byte SOUND_ALTO
	!byte <data_player_dies_sound_clip_extra
	!byte >data_player_dies_sound_clip_extra
	!byte $ff

data_starting_game_on_sound_clip_extra
	!byte $06, $e1, $01, $00, $06, $e8, $01, $00
	!byte $06, $ed, $01, $00, $0f, $f0, $03, $00
	!byte $06, $ed, $01, $00, $1e, $f0, $ff

data_starting_game_on_sound_clip
	!byte SOUND_BASS
	!byte <data_starting_game_on_sound_clip_extra
	!byte >data_starting_game_on_sound_clip_extra
	!byte SOUND_ALTO
	!byte <data_starting_game_on_sound_clip_extra
	!byte >data_starting_game_on_sound_clip_extra
	!byte $ff

data_main_theme_tune_sound_clip_extra
	!byte $03, $c8, $01, $00, $03, $ce, $01, $00
	!byte $07, $d1, $01, $00, $07, $ce, $01, $00
	!byte $07, $c8, $01, $00, $03, $c8, $01, $00
	!byte $03, $ce, $01, $00, $03, $d1, $01, $00
	!byte $03, $db, $01, $00, $03, $ce, $01, $00
	!byte $03, $d1, $01, $00, $07, $c8, $01, $00
	!byte $03, $d1, $01, $00, $03, $d7, $01, $00
	!byte $01, $db, $01, $00, $01, $db, $01, $00
	!byte $01, $db, $01, $00, $01, $db, $01, $00
	!byte $05, $db, $01, $00, $01, $dd, $01, $00
	!byte $03, $db, $01, $00, $03, $d7, $01, $00
	!byte $03, $ce, $01, $00, $03, $d1, $01, $00
	!byte $01, $d7, $01, $00, $01, $d7, $01, $00
	!byte $01, $d7, $01, $00, $01, $d7, $01, $00
	!byte $05, $d7, $01, $00, $01, $db, $01, $00
	!byte $03, $d7, $01, $00, $03, $d1, $01, $00
	!byte $ff

data_main_theme_tune_sound_clip
	!byte SOUND_BASS
	!byte <data_main_theme_tune_sound_clip_extra
	!byte >data_main_theme_tune_sound_clip_extra
	!byte SOUND_SOPRANO
	!byte <data_main_theme_tune_sound_clip_extra
	!byte >data_main_theme_tune_sound_clip_extra
	!byte $ff

data_start_maze_sound_clip_extra
	!byte $06, $b4, $01, $00, $06, $c8, $01, $00
	!byte $06, $d2, $01, $00, $07, $da, $04, $00
	!byte $03, $da, $01, $00, $03, $da, $01, $00
	!byte $07, $d2, $04, $00, $03, $d2, $01, $00
	!byte $03, $d2, $01, $00, $06, $c8, $01, $00
	!byte $06, $d2, $01, $00, $06, $c8, $01, $00
	!byte $24, $b4, $ff

data_start_maze_sound_clip
	!byte SOUND_BASS
	!byte <data_start_maze_sound_clip_extra
	!byte >data_start_maze_sound_clip_extra
	!byte SOUND_ALTO
	!byte <data_start_maze_sound_clip_extra
	!byte >data_start_maze_sound_clip_extra
	!byte SOUND_SOPRANO
	!byte <data_start_maze_sound_clip_extra
	!byte >data_start_maze_sound_clip_extra
	!byte $ff

data_eat_snake_body_1_sound_clip_extra
	!byte $01, $dc, $01, $00, $01, $b4, $ff

data_eat_snake_body_1_sound_clip
	!byte SOUND_ALTO
	!byte <data_eat_snake_body_1_sound_clip_extra
	!byte >data_eat_snake_body_1_sound_clip_extra
	!byte $ff

data_eat_snake_body_2_sound_clip_extra
	!byte $01, $b4, $01, $dc, $ff

data_eat_snake_body_2_sound_clip
	!byte SOUND_ALTO
	!byte <data_eat_snake_body_2_sound_clip_extra
	!byte >data_eat_snake_body_2_sound_clip_extra
	!byte $ff

;--------------------------------------------------------------------------------------------------

play_about_to_start_maze_tune

    ldx #<data_start_maze_sound_clip
    ldy #>data_start_maze_sound_clip
	jsr prepare_sound_data

	lda #117
	sta sound_loop_counter
.start_maze_sound_loop
    jsr play_sounds
	ldy #17
	jsr delay_using_Y
	dec sound_loop_counter
	bne .start_maze_sound_loop
	jmp prepare_snake_hissing_sound

;--------------------------------------------------------------------------------------------------

prepare_eat_frog_egg_snake_head_sound

    ldx #<data_eat_frog_egg_enemy_head_sound_clip
	ldy #>data_eat_frog_egg_enemy_head_sound_clip
	jmp prepare_sound_data

;--------------------------------------------------------------------------------------------------

data_snake_hissing_sound_clip_extra
	!byte $28, $fe, $28, $00, $ff

data_snake_hissing_sound_clip
	!byte SOUND_NOISE
	!byte <data_snake_hissing_sound_clip_extra
	!byte >data_snake_hissing_sound_clip_extra
	!byte $ff

;--------------------------------------------------------------------------------------------------

play_snake_hissing_sound

    dec sound_hiss_counter
	bne .skip_snake_hissing_sound
prepare_snake_hissing_sound
    lda #80
	sta sound_hiss_counter
	lda #%00101111  ;aux colour red, volume 15
	sta _VIC_VOLUME
	ldx #<data_snake_hissing_sound_clip
	ldy #>data_snake_hissing_sound_clip
	jmp prepare_sound_data

.skip_snake_hissing_sound
    rts

;--------------------------------------------------------------------------------------------------

handle_player_dies

    jsr clear_all_sound_channels
	ldx #<data_player_dies_sound_clip
	ldy #>data_player_dies_sound_clip
	jsr prepare_sound_data

	ldx #0
	stx snake_data_pointer
	lda #63
	sta sound_loop_counter
.disintegrate_player_snake_loop
    jsr play_sounds
	lda sound_loop_counter
	lsr
	lsr
	lsr
	jsr dead_snake_animation
	ldx snake_index
	lda data_enemy_snake_table_offsets,x
	tax
	lda player_and_enemy_table,x
	sta body_segments  ;points to player or enemy snake number of segments
	lda #1
	sta snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	txa
	clc
	adc #7
	jsr plot_entire_snake_on_screen
	dec sound_loop_counter
	bne .disintegrate_player_snake_loop

clear_maze_objects_and_player_loses_life
    jsr clear_maze_objects

    ;check if player laid an egg before demise
	lda player_egg_status
	cmp #3
	bne .skip_baby_snake
	jsr start_baby_snake_goes_home
.skip_baby_snake
    jsr update_player_loses_life
	bcs end_of_game

    ; life lost, play next one
	lda #3
	sta player_body_segments

	ldx #4
.delay_using_X_0
    ldy #255
	jsr delay_using_Y
	dex
	bne .delay_using_X_0

	jmp play_one_life

;--------------------------------------------------------------------------------------------------

end_of_game

    ; All lives lost, end of game, play "last post" tune
    ldx #<data_last_post_end_sound_clip
	ldy #>data_last_post_end_sound_clip
	jsr prepare_sound_data

	lda #2
	sta end_loop_counter
	lda #20
	sta sound_loop_counter
.play_end_of_game_sound
    jsr play_sounds
	ldy #17
	jsr delay_using_Y
	jsr read_joystick
	cmp #JOY_FIRE
	beq .goto_start_game_play
	dec sound_loop_counter
	bne .play_end_of_game_sound
	dec end_loop_counter
	bpl .play_end_of_game_sound

	jsr clear_all_sound_channels
	jsr clear_screen_and_add_heading_block
	jsr plot_level_and_headings_on_screen
	jsr plot_high_score_on_screen
	jsr plot_player_score_on_screen
	jsr draw_maze_and_set_enemy_snake_start_position

.wait_to_restart_game_loop
    ldx #<data_main_theme_tune_sound_clip
	ldy #>data_main_theme_tune_sound_clip
	jsr prepare_sound_data

	lda #128
	sta sound_loop_counter
.play_main_tune_and_wait_restart_loop
    jsr play_sounds
	jsr handle_enemy_snake_movement
	ldy #36
	jsr delay_using_Y
	jsr read_joystick
	cmp #JOY_FIRE
	beq .goto_start_game_play
	dec sound_loop_counter
	bne .play_main_tune_and_wait_restart_loop
	beq .wait_to_restart_game_loop

.goto_start_game_play
    jmp start_game_play

;--------------------------------------------------------------------------------------------------

data_last_post_end_sound_clip_extra
	!byte $19, $9c, $01, $00, $0f, $9c, $01, $00
	!byte $3c, $b5, $01, $00, $19, $9c, $01, $00
	!byte $0f, $b5, $01, $00, $3c, $c4, $01, $00
	!byte $19, $b5, $01, $00, $0f, $c4, $01, $00
	!byte $3c, $ce, $01, $00, $19, $c4, $01, $00
	!byte $19, $b5, $01, $00, $3c, $9c, $01, $00
	!byte $19, $9c, $01, $00, $0f, $9c, $01, $00
	!byte $3c, $b5, $01, $00, $ff

data_last_post_end_sound_clip
	!byte SOUND_SOPRANO
	!byte <data_last_post_end_sound_clip_extra
	!byte >data_last_post_end_sound_clip_extra
	!byte $ff

;--------------------------------------------------------------------------------------------------

start_baby_snake_goes_home

    jsr clear_all_sound_channels
	ldx #<data_baby_snake_sound_clip
	ldy #>data_baby_snake_sound_clip
	jsr prepare_sound_data

	jsr perform_plot_player_egg_on_screen

	ldx #4
.delay_using_X_4_1
    ldy #255
	jsr delay_using_Y
	dex
	bne .delay_using_X_4_1

	jsr play_sound

	lda #0
	sta player_egg_status  ;set to zero (no egg)

    ; set player snake (baby hatched) coordinates from the baby snake egg coordinates
	ldx #2
.apply_egg_coords_loop
    lda player_egg_location_column-1,x  ;get $2c (player_egg_location_row), $2b (player_egg_location_column), $2a (direction)
	sta player_and_enemy_table+5,x  ;update $87 (snake head screen row), $86 (snake head screen column), $85 (snake head direction)
	dex
	bpl .apply_egg_coords_loop

	lda player_body_segments
	pha
	lda #1
	sta player_body_segments
	jsr add_segment_to_player_body
	ldy #0
	jsr perform_player_or_enemy_snake_movement  ;player snake
	jsr player_or_baby_snake_goes_home_loop
	pla
	sta player_body_segments
	jmp add_one_to_player_lives

;--------------------------------------------------------------------------------------------------

player_snake_goes_home

    jsr clear_all_sound_channels
	ldx #<data_player_goes_home_sound_clip
	ldy #>data_player_goes_home_sound_clip
	jsr prepare_sound_data

player_or_baby_snake_goes_home_loop
    lda #166  ;right edge column
    cmp player_body_segments+6  ;snake head column
	beq .check_outside_home_row
	jsr .set_snake_header_screen_coords_and_check_direction
	beq .move_snake_right_and_down_check_near_home
.perform_snake_movement_in_loop
    jsr .goto_perform_player_movement
	jmp player_or_baby_snake_goes_home_loop

.move_snake_right_and_down_check_near_home
    jsr .move_snake_to_the_right
	bcc .perform_snake_movement_in_loop  ;direction change is allowed
	lda #DIRECTION_DOWN
    ldx player_body_segments+7  ;snake head row
    cpx #119  ;outside player snake home door row?
	bcc .move_snake_and_get_a_new_direction
	lda #DIRECTION_UP

.move_snake_and_get_a_new_direction
    jsr .set_snake_direction  ;up
	bcc .move_snake_and_check_direction  ;direction change is allowed
	ldy desired_snake_direction
	lda data_directions-1,y
	bne .move_snake_and_get_a_new_direction

.move_snake_and_check_direction
    jsr .goto_perform_player_movement
	jsr .set_snake_header_screen_coords_and_check_direction
	bne .move_snake_and_check_direction
	jsr .move_snake_to_the_right
	bcc .perform_snake_movement_in_loop  ;direction change is allowed
	lda player_body_segments+5 ;snake head direction
	bne .move_snake_and_get_a_new_direction

.check_outside_home_row
    lda player_body_segments+7  ;snake head row
    cmp #118  ;outside player snake home door row?
	beq .open_door_and_get_into_home
	jsr .set_snake_header_screen_coords_and_check_direction
	beq .move_snake_down_and_left_into_home

.move_snake_and_check_outside_home_row
    jsr .goto_perform_player_movement
	jmp .check_outside_home_row

.move_snake_down_and_left_into_home
    lda #DIRECTION_DOWN
	jsr .set_snake_direction  ;down
	bcc .move_snake_and_check_outside_home_row  ;direction change is allowed
	lda #DIRECTION_LEFT
	jsr .set_snake_direction  ;left

.repeat_snake_move_in_direction
    jsr .goto_perform_player_movement
	jsr .set_snake_header_screen_coords_and_check_direction
	bne .repeat_snake_move_in_direction
	lda #DIRECTION_DOWN
	jsr .set_snake_direction  ;down
	bcs .repeat_snake_move_in_direction  ;direction change is not allowed

.repeat_snake_move_in_direction_2
    jsr .goto_perform_player_movement
	jsr .set_snake_header_screen_coords_and_check_direction
	bne .repeat_snake_move_in_direction_2
	beq .move_snake_right_and_down_check_near_home  ;always branch

.open_door_and_get_into_home
    clc  ;to clear space and open door
	jsr open_or_close_snake_entrance_door   ;door open
	lda #DIRECTION_DOWN  ;move snake down into home
	sta player_snake_direction
	lda #255
	sta player_and_enemy_table+3  ;update snake in home or maze to #255 (reached home)
	jsr .goto_perform_player_movement
	lda #DIRECTION_LEFT  ;move snake left into home
	sta player_snake_direction

.move_inside_home_loop
    jsr .goto_perform_player_movement
	ldx #0
	jsr get_screen_coordinates_for_last_segment  ;player snake
	ldy screen_row
	cpy #134  ;last segment is beyond home door row?
	bne .move_inside_home_loop
	ldx screen_column
	cpx #166  ;last segment is at the right edge column?
	bne .move_inside_home_loop
	sec  ;to set the door closed
	jsr open_or_close_snake_entrance_door  ;door closed
	jmp clear_all_sound_channels

.move_snake_to_the_right
    lda #DIRECTION_RIGHT
.set_snake_direction
    sta player_snake_direction  ;right
	sta desired_snake_direction  ;right
	jsr .set_snake_header_screen_coords_and_check_direction
	jmp check_if_direction_change_is_valid

.set_snake_header_screen_coords_and_check_direction
    ldy #7  ;points to player snake head
	jsr get_screen_coordinates_for_sprite_player
	jmp check_snake_head_maze_cell_alignment  ;decide if snake head is at a position to check movement rules

.goto_perform_player_movement
    ldy #0
	jsr perform_player_or_enemy_snake_movement  ;player snake
	jsr play_sounds
	jsr handle_frog_actions

    ;player lays an egg going home
	lda player_egg_status
	cmp #3
	bne .skip_plot_player_egg_on_screen
	jsr perform_plot_player_egg_on_screen
.skip_plot_player_egg_on_screen
    ldy #10
	jmp delay_using_Y

;--------------------------------------------------------------------------------------------------

play_sound

    lda #%00101111  ;aux colour red, volume 15
	sta _VIC_VOLUME
	ldx #255
.play_sound_loop
    ldy #56
.play_sound_delay_loop
    stx _VIC_SOUND_SOPRANO
	stx _VIC_SOUND_ALTO
	dey
	bne .play_sound_delay_loop
	dex
	bne .play_sound_loop
	lda #%00101010  ;aux colour red, volume 10
	sta _VIC_VOLUME
	rts

;--------------------------------------------------------------------------------------------------

set_maze_level_to_next_one

    ldx maze_level
	cpx #99
	bcs .max_maze_number_so_end
	inx
	stx maze_level
.max_maze_number_so_end
    rts

;--------------------------------------------------------------------------------------------------

player_has_eaten_all_enemy_snakes

    lda #20  ;apart from the delay, 20 iterations appears unnecessary
	sta game_speed_counter
.eaten_all_snakes_loop
    jsr play_sounds
	jsr perform_enemy_snake_movement
	jsr update_snake_tick_counters
	lda #0
	sta snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	lda player_body_segments
	sta body_segments  ;points to player or enemy snake number of segments
	lda #7
	jsr plot_entire_snake_on_screen
	ldy #17
	jsr delay_using_Y
	dec game_speed_counter
	bne .eaten_all_snakes_loop

	jsr clear_all_sound_channels
	jsr set_maze_level_to_next_one
	jsr player_snake_goes_home

    ;check if player laid an egg
	lda player_egg_status
	cmp #3
	bne .goto_play_one_life
	jsr start_baby_snake_goes_home
.goto_play_one_life
    jmp play_one_life

;--------------------------------------------------------------------------------------------------

clear_maze_objects

    ; clear all enemy snakes from screen
    ldx #38
.clear_each_enemy_snake_on_screen_loop
    stx temp_snake_data_pointer2  ;points to player or enemy snake head
	stx snake_data_pointer

    ; use each enemy snake segment coordinates and clear each from the screen
	lda enemy_snake_table-7,x  ;number of enemy snake body segments
	sta temp3
.clear_one_enemy_snake_on_screen_loop
    jsr get_screen_coordinates_for_sprite
	jsr clear_block_at_screen_coordinates
	jsr add_3_to_point_to_next_segment
	dec temp3
	bne .clear_one_enemy_snake_on_screen_loop

	lda snake_data_pointer
	clc
	adc #30  ;offset to next snake data
	tax
	cpx #99
	bcc .clear_each_enemy_snake_on_screen_loop

    ; clear frog
	lda frog_display
	bmi .skip_clear_frog_on_screen
	jsr plot_frog_sprite_on_screen  ;will clear frog on screen
.skip_clear_frog_on_screen

    ; clear enemy snake egg
    lda enemy_egg_status
	cmp #3  ;hatchable egg
	bne .clear_maze_objects_end
	lda enemy_egg_location_column
	sta screen_column
	lda enemy_egg_location_row
	sta screen_row
	jmp clear_block_at_screen_coordinates

.clear_maze_objects_end
    rts

;--------------------------------------------------------------------------------------------------

data_player_goes_home_sound_clip_extra
	!byte $06, $cd, $06, $c3, $18, $00, $06, $c3
	!byte $06, $c8, $06, $cd, $08, $e1, $04, $00
	!byte $08, $e1, $04, $00, $18, $da, $06, $00
	!byte $06, $cd, $06, $c3, $18, $00, $06, $c3
	!byte $06, $c8, $06, $c3, $08, $cd, $04, $00
	!byte $08, $cd, $04, $00, $18, $c7, $ff

data_baby_snake_sound_clip_extra
	!byte $06, $c7, $06, $bc, $18, $00, $06, $bc
	!byte $06, $c4, $06, $c8, $06, $ce, $06, $c4
	!byte $18, $00, $06, $c4, $06, $ca, $06, $c4
	!byte $06, $bc, $06, $cd, $06, $00, $06, $c4
	!byte $06, $ca, $06, $bc, $06, $00, $06, $d2
	!byte $18, $cd, $ff

data_player_goes_home_sound_clip
	!byte SOUND_ALTO
	!byte <data_player_goes_home_sound_clip_extra
	!byte >data_player_goes_home_sound_clip_extra
	!byte SOUND_SOPRANO
	!byte <data_player_goes_home_sound_clip_extra
	!byte >data_player_goes_home_sound_clip_extra
	!byte $ff

data_baby_snake_sound_clip
	!byte SOUND_ALTO
	!byte <data_baby_snake_sound_clip_extra
	!byte >data_baby_snake_sound_clip_extra
	!byte SOUND_SOPRANO
	!byte <data_baby_snake_sound_clip_extra
	!byte >data_baby_snake_sound_clip_extra
	!byte $ff

;--------------------------------------------------------------------------------------------------
; Junk bytes needed to pad file to 8192 bytes for A000 cartridge format
; These bytes could be replaced with !fill 1309,0 but are kept to allow
; a matching binary comparison with the original program
    !source "junk2.asm"

;--------------------------------------------------------------------------------------------------
end_of_program
