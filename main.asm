; Serpentine for the Commodore Vic20

;-----------------------------------------------------------------------------------
; system addresses

_CUSTOM_CHARACTERS_ADDR = $1000  ;4096
_COLOUR_SCREEN_ADDR = $9600  ;38400
_HORIZONTAL_ALIGNMENT = $9000  ;36864 bits 0-6 horizontal centering, bit 7 sets interlace scan
_VERTICAL_ALIGNMENT = $9001  ;36865 vertical centering
_VICCR9 = $9009  ;36873
_SOUND2 = $900b  ;36875
_SOUND3 = $900c  ;36876
_VOLUME = $900e  ;36878
_IRQ_ENABLE =   $911e  ;37150
_JOYSTICK_MIRROR = $911f  ;37151
_KEYB_ROWS = $9120  ;37152
_DATADIR_B = $9122  ;37154

;-----------------------------------------------------------------------------------
; joystick constants

JOY_RIGHT = 1
JOY_UP = 2
JOY_DOWN = 4
JOY_LEFT = 8
JOY_FIRE = 16

;-----------------------------------------------------------------------------------
;Snake direction values
up = 1
down = 2
right = 3
left = 4

;-----------------------------------------------------------------------------------
; zero page addresses

body_segments = $07
snake_colour = $08
snake_direction = $09
direction_change_indicator = $0c
maze_part_to_plot = $0d
screen_coords_table = $0d  ;$0d (segment_direction), $0e (screen_column), $0f (screen_row)
screen_coords_table_word = $0d  ;as above
segment_direction = $0d
screen_column = $0e
screen_row = $0f
maze_address_low = $15
maze_address_high = $16

player_lives = $18
current_maze = $19
enemy_snake_speed_control = $1c
enemy_snake_speed_counter = $1d

enemy_egg_location_column = $23
enemy_egg_location_row = $24
enemy_egg_status = $25  ;0, 1, 2, 3  ;TODO - assumed, 0 (no egg), 3 (egg laid), 1 and 2 (incubation timers)
enemy_snake_with_egg = $26  ;0, 1, 2, 3  ;TODO - assumed pointer to snake developing or has laid an egg
dead_enemy_snake_to_replace_with_egg = $27  ;0, 1, 2, 3 pointer to dead snake which can have a replacement egg laid for it

player_egg_location_column = $2b
player_egg_location_row = $2c
player_egg_status = $2d  ;0, 1, 2, 3  ;TODO - assumed, 0 (no egg), 3 (egg laid), 1 and 2 (incubation timers)

snake_tick_table = $2e  ;game tick counter for when snakes can do things

frog_display = $40
frog_location_column = $41
frog_location_row = $42

snake_counter = $4e  ;0, 1, 2
scroll_heading_position = $46
scroll_heading_delay = $47
sound_loop_counter = $48
end_loop_counter = $49

score_for_eat_snake_head = $4a
score_for_eat_snake_body = $4b
score_for_eat_egg_low = $4c
score_for_eat_egg_high = $4d

temp1 = $50
temp2 = $51
temp3 = $52

sound_hiss_counter = $53
player_score = $54  ;3 bytes $54, $55, $56
high_score = $57  ;3 bytes $57, $58, $59
text_pointer_low = $5d
text_pointer_high = $5e

player_and_enemy_table = $80  ;table where player and enemy snake data is held
player_and_enemy_table_word = $0080  ;table where player and enemy snake data is held (alternate reference)
enemy_snake_table = $80  ;table where enemy snake data is held (used to indicate enemy snake only)
player_body_segments = $80  ;number of body segments
player_snake_direction = $82  ;direction indicator

snake_1_body_segments = $9f  ;number of body segments
snake_2_body_segments = $bd  ;number of body segments
snake_3_body_segments = $db  ;number of body segments

;-----------------------------------------------------------------------------------
; start program, game was originally a cartridge so no basic loader
* = $a000
    ; auto start the program
	!byte <start_of_program  ;cold start vector (low)
	!byte >start_of_program  ;cold start vector (high)
	!byte <start_of_program  ;warm / reset start vector (low)
	!byte >start_of_program  ;warm / reset start vector (high)
    !pet "a0CBM"  ;start of signature a0CBM

;-----------------------------------------------------------------------------------
; player snake table, data is saved in zero page $80 +
; see references to zero page data for each snake in player_and_enemy_table, player_and_enemy_table_word

data_zero_page_80_99
    !byte $03  ;player_body_segments
	!byte $00  ;snake colour number: 0 is blue, 1 is red, 2 is yellow
	!byte $00  ;snake direction
	!byte $80
	!byte $80

    ;snake head coordinates
	!byte $01  ;segment direction
	!byte $a6  ;screen column
	!byte $86  ;screen row

    ;snake body coordinates
	!byte $01  ;segment direction
	!byte $a6  ;screen column
	!byte $8e  ;screen row

	!byte $01
	!byte $a6
	!byte $96

	!byte $01
	!byte $a6
	!byte $9e

	!byte $03
	!byte $a6
	!byte $a6

	!byte $03
	!byte $9e
	!byte $a6

    !byte $aa
    !byte $aa
    !byte $aa
	!byte $aa
    !byte $aa
    !byte $aa
    !byte $aa  ;$9d

;-----------------------------------------------------------------------------------
; enemy snake table for each snake, data is saved in zero page $9e + for snake 1, $bc + for snake 2, $da + for snake 3
; see references to zero page data for each snake in player_and_enemy_table, player_and_enemy_table_word

data_zero_page_9e_f7
    !byte $3c  ;$9e
	!byte $06  ;$9f number of enemy snake body segments
	!byte $01  ;snake colour number: 0 is blue, 1 is red, 2 is yellow
	!byte $00  ;snake direction
	!byte $80
	!byte $80

    ;snake head coordinates
	!byte $01  ;segment direction
	!byte $06  ;screen column
	!byte $76  ;screen row

    ;snake body coordinates
	!byte $01  ;segment direction
	!byte $06  ;screen column
	!byte $7e  ;screen row

	!byte $01
	!byte $06
	!byte $86

	!byte $01
	!byte $06
	!byte $8e

	!byte $01
	!byte $06
	!byte $96

	!byte $01
	!byte $06
	!byte $9e

	!byte $aa
    !byte $aa
    !byte $aa
    !byte $aa
    !byte $aa
    !byte $aa  ;$bb, $d9, $f7

;-----------------------------------------------------------------------------------

start_of_program

	sei
	lda #2  ;disable restore key interrupt
	sta _IRQ_ENABLE
	jsr initialise_9000_series_and_other_data
	lda #1
	sta current_maze
	jsr clear_player_and_high_score
	jsr init_zero_page_with_timers
	jsr display_opening_title_screen

start_game_play

	jsr clear_all_sound_channels
	jsr set_screen_base_colours
	jsr initialise_0200_onwards_with_increments_of_11
	jsr check_for_new_high_score
	ldx #3
	stx player_lives
	stx player_body_segments
	dex
	stx $5a
	jsr clear_player_score
	lda #1
	sta current_maze

;-----------------------------------------------------------------------------------

play_one_life

	ldx #247
	txs
	jsr clear_all_sound_channels
	jsr clear_25_2d_2b
	jsr clear_512_custom_characters
	jsr initialise_zero_page
	jsr draw_maze
	jsr plot_level_and_headings_on_screen
	jsr plot_high_score_on_screen
	jsr plot_player_score_on_screen
	jsr plot_player_lives_on_screen
	jsr calculate_score_values_for_maze
	jsr set_frog_to_clear_on_screen
	jsr plot_player_snake_and_open_entrance_door
	jsr set_enemy_snake_start_position
	jsr play_about_to_start_maze_tune

.game_play_loop
	jsr handle_player_movement
	jsr handle_enemy_snake_movement
	jsr handle_player_and_enemy_snake_interactions
	jsr handle_player_and_enemy_snake_eggs
	jsr more_player_and_enemy_snake_interactions
	jsr handle_frog_actions
	jsr play_sounds
	jsr play_snake_hissing_sound
	jsr get_joystick_movement
	dec $1f
	bne .game_play_loop
	ldx enemy_snake_speed_control
	inx
	cpx #11
	bcs .keep_max_speed_control_at_11
	stx enemy_snake_speed_control
.keep_max_speed_control_at_11
	ldx $1a
	dex
	cpx #8
	bcc .game_play_loop
	stx $1a
	bcs .game_play_loop  ;always branch

;-----------------------------------------------------------------------------------

initialise_zero_page

	ldy #25
.init_zero_page_loop
	lda data_zero_page_80_99,y
	sta player_and_enemy_table_word,y  ;initialise all from table
	dey
	bne .init_zero_page_loop

	lda #10
	ldx current_maze
	cpx #5
	bcs .alternate_zero_page_value
	lda #15
	sec
	sbc current_maze
.alternate_zero_page_value
	sta $1b
	sta $1a

	lda #4
	sta enemy_snake_speed_counter
	sta enemy_snake_speed_control

	ldx #29
	jsr .init_zero_page_group_of_30
	ldx #59
	jsr .init_zero_page_group_of_30

	ldx #89
.init_zero_page_group_of_30
	ldy #29
.init_zero_page_30_loop
	lda data_zero_page_9e_f7,y
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
	sta $1f
	rts

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

direction_list
	!byte JOY_UP, JOY_DOWN, JOY_RIGHT, JOY_LEFT, JOY_FIRE

;-----------------------------------------------------------------------------------

get_joystick_movement

	jsr read_joystick
	bcs .no_joystick_action
	cmp #JOY_FIRE
	bne .joy_movement_in_X

    ; pause game when fire is pressed
	lda _VOLUME
	tay
	and #%11110000
	sta _VOLUME
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
	sty _VOLUME
.no_joystick_action
	rts
.joy_movement_in_X
	stx player_snake_direction  ;X is the direction: 1 up, 2 down, 3 right, 4 left
	rts

;-----------------------------------------------------------------------------------

read_joystick

	lda #127
	sta _DATADIR_B
	lda _KEYB_ROWS
	eor #255
	and #%10000000  ;isolate joystick-right direction (bit 7)
	asl  ;move bit 7 to carry
	rol  ;move carry to bit 0
	sta $12  ;put right bit in working variable
	lda _JOYSTICK_MIRROR
	eor #255
	and #%00111100  ;isolate joystick directions and fire
	lsr  ;shift right
	ora $12  ;add right direction, bits are not fire (16 if on), left (8 if on), down (4 if on), up (2 if on) and right (1 if on)
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

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

initialise_0200_onwards_with_increments_of_11

    ; set $0200 to $02f2 with 0, 11, 22, 33, 44 etc to 242
	lda #0
	tay
	sta $12
.init_0200_11_times_outer_loop
	ldx #22
.init_0200_22_times_loop
	sta $0200,y
	iny
	clc
	adc #11
	dex
	bne .init_0200_22_times_loop
	inc $12
	lda $12
	cmp #11  ;11 times
	bcc .init_0200_11_times_outer_loop
	rts

;-----------------------------------------------------------------------------------

clear_512_custom_characters

	lda #>_CUSTOM_CHARACTERS_ADDR
	ldy #<_CUSTOM_CHARACTERS_ADDR
	sta $01
	sty $00

	ldx #16  ;8 x 16 pixel character size, also see _VICCR3
	ldy #0
	tya  ;clear the entire character (blank space)
.clear_custom_char_loop
	sta ($00),y
	iny
	bne .clear_custom_char_loop
	inc $01
	dex
	bne .clear_custom_char_loop

block_22_custom_characters
	lda #>_CUSTOM_CHARACTERS_ADDR
	ldy #<_CUSTOM_CHARACTERS_ADDR
	sta $01
	sty $00

	ldx #22  ;top 2 lines of block characters
.block_custom_char_X_loop
	lda #255  ;fill the entire character line making a block space
	ldy #15  ;8 x 16 pixel character size, also see _VICCR3
.block_custom_char_Y_loop
	sta ($00),y
	dey
	bpl .block_custom_char_Y_loop

	lda $00
	clc
	adc #176  ;176 (each character is 8 bits in a row of 22 characters)
	sta $00
	bcc *+4  ;skip high byte update
	inc $01
	dex
	bne .block_custom_char_X_loop
	rts

;-----------------------------------------------------------------------------------

data_screen_bitmap_address_low
    ; increments each byte by 176 (each character is 8 bits in a row of 22 characters)
	!byte $00, $b0, $60, $10, $c0, $70, $20, $d0
	!byte $80, $30, $e0, $90, $40, $f0, $a0, $50
	!byte $00, $b0, $60, $10, $c0, $70

data_screen_bitmap_address_high
    !byte $10, $10, $11, $12, $12, $13, $14, $14
	!byte $15, $16, $16, $17, $18, $18, $19, $1a
	!byte $1b, $1b, $1c, $1d, $1d, $1e

;-----------------------------------------------------------------------------------

convert_screen_row_column_to_screen_bitmap_address

	lda screen_column
	tay
	and #7
	sta $02
	tya
	lsr
	lsr
	lsr
	tax
	lda data_screen_bitmap_address_high,x
	sta $01
	lda data_screen_bitmap_address_low,x
	clc
	adc screen_row
	sta $00
	bcc *+4  ;skip high byte update
	inc $01
	rts

;-----------------------------------------------------------------------------------

plot_something_on_screen

	jsr convert_screen_row_column_to_screen_bitmap_address
	ldy #7
@LA23F
	lda #0
	sta $03
	lda ($10),y
	ldx $02
	beq @LA24F
@LA249
	lsr
	ror $03
	dex
	bne @LA249
@LA24F
	ora ($00),y
	sta ($00),y
	tya
	tax
	ora #176
	tay
	lda $03
	beq @LA260
	ora ($00),y
	sta ($00),y
@LA260
	txa
	tay
	dey
	bpl @LA23F
	rts

;-----------------------------------------------------------------------------------

clear_something_on_screen

    ;unplot the given object on the screen, thereby clearing it
	jsr convert_screen_row_column_to_screen_bitmap_address
	ldy #7
@LA26B
	lda #255
	sta $03
	lda ($10),y
	eor #255
	ldx $02
	beq @LA27E
@LA277
	sec
	ror
	ror $03
	dex
	bne @LA277
@LA27E
	and ($00),y
	sta ($00),y
	tya
	tax
	ora #176
	tay
	lda $03
	cmp #255
	beq @LA291
	and ($00),y
	sta ($00),y
@LA291
	txa
	tay
	dey
	bpl @LA26B
	rts

;-----------------------------------------------------------------------------------

get_screen_coordinates_for_sprite

	ldy $06  ;points to player or enemy snake
get_screen_coordinates_for_sprite_player  ;Y is 7 when called
	ldx #2
.get_sprite_screen_coords_loop
	lda player_and_enemy_table_word,y  ;player_and_enemy_table with offset for sprite in Y
	sta screen_coords_table,x  ;update $0f (screen_row), $0e (screen_column), $0d (segment_direction)
	dey
	dex
	bpl .get_sprite_screen_coords_loop
	rts

;-----------------------------------------------------------------------------------

set_screen_coordinates_for_sprite

	ldy $06  ;points to player or enemy snake
	ldx #2
.set_sprite_screen_coords_loop
    lda screen_coords_table,x  ;get $0f (screen_row), $0e (screen_column), $0d (segment_direction)
	sta player_and_enemy_table_word,y  ;player_and_enemy_table with offset for sprite in Y
	dey
	dex
	bpl .set_sprite_screen_coords_loop
	rts

;-----------------------------------------------------------------------------------

data_screen_column_increments
	!byte 0, 0, 2, 254
data_screen_row_increments
	!byte 254, 2, 0, 0

;-----------------------------------------------------------------------------------

check_and_update_screen_row_column
	ldx segment_direction
	bne update_screen_row_column_and_check_within_screen_limits
	ldx screen_column
	ldy screen_row
	rts

update_screen_row_column_and_check_within_screen_limits
	lda screen_row
	clc
	adc data_screen_row_increments-1,x
	tay
	lda screen_column
	clc
	adc data_screen_column_increments-1,x
	tax

	lda #%10000000  ;128 set top bit 7
	sta $04  ;set top bit 7

    ;check incremented row (Y) and column (X) are in the bounds of the screen
	cpx #6
	bcs .column_ok_on_right_edge
	asl $04  ;clear top bit 7
	ldx screen_column
.column_ok_on_right_edge
	cpx #167
	bcc .column_ok_on_left_edge
	asl $04  ;clear top bit 7
	ldx screen_column
.column_ok_on_left_edge
	cpy #22
	bcs .row_ok_on_top_edge
	asl $04  ;clear top bit 7
	ldy screen_row
.row_ok_on_top_edge
	cpy #167
	bcc .row_ok_on_bottom_edge
	asl $04  ;clear top bit 7
	ldy screen_row
.row_ok_on_bottom_edge
	rts

;-----------------------------------------------------------------------------------

update_screen_row_column

	jsr check_and_update_screen_row_column
	stx screen_column
	sty screen_row
	rts

;-----------------------------------------------------------------------------------

LA2FF
	lda #128
	sta $13
	ldx #1
@LA305
	lda screen_coords_table+1,x  ;points to $0e (screen_column), $0f (screen_row)
	sec
	sbc #6
	and #%00001111  ;15
	bne @LA313
	dex
	bpl @LA305
	asl $13
@LA313
	rts

LA314
	ldx #2
@LA316
	lda screen_coords_table,x  ;points to $0e (screen_column), $0f (screen_row)
	sec
	sbc #6
	and #%00000111  ;7
	bne @LA322
	dex
	bne @LA316
@LA322
	rts

;-----------------------------------------------------------------------------------

data_to_add_to_hex_17
	!byte 0, 11, 1, 0

;-----------------------------------------------------------------------------------

LA327
	bit $13
	bpl .ensure_segments_are_within_screen
.LA32B_clear_carry_and_end
	clc
	rts

.ensure_segments_are_within_screen
    ldx segment_direction
ensure_snake_and_segments_are_within_screen
    stx $14
	jsr update_screen_row_column_and_check_within_screen_limits
	bit $04  ;check top bit 7
	bmi .screen_column_row_are_outside_limits  ;top bit 7 is clear so branch
.LA338_set_carry_and_end
    sec
	rts

.screen_column_row_are_outside_limits
    jsr convert_screen_row_column_to_byte_in_hex_17
	ldx $14
	clc
	adc data_to_add_to_hex_17-1,x
	sta $17
	jsr decide_which_maze_part_to_plot  ;TODO: has dual purpose but needs $15, $16 populated
	beq .LA32B_clear_carry_and_end
	cmp #3
	beq .LA338_set_carry_and_end
	cmp #1
	bne @LA35A
	lda $14
	cmp #3
	bcs .LA32B_clear_carry_and_end
	bcc .LA338_set_carry_and_end  ;always branch

@LA35A
	lda $14
	cmp #3
	bcs .LA338_set_carry_and_end
	bcc .LA32B_clear_carry_and_end  ;always branch

;-----------------------------------------------------------------------------------

LA362

    ldx snake_direction
	bit $13
	bpl ensure_snake_and_segments_are_within_screen
	jsr LA314
	bne .LA382_set_carry_and_end

	ldx snake_direction
	lda segment_direction
	cmp data_directions-1,x
	bne .LA382_set_carry_and_end
	lda screen_column
	cmp #166  ;last segment is at the right edge column?
	bne .LA32B_clear_carry_and_end
	lda screen_row
    cmp #126  ;last segment is outside front of home door row?
	bne .LA32B_clear_carry_and_end
.LA382_set_carry_and_end
    sec
	rts

;-----------------------------------------------------------------------------------

move_something_on_screen

    jsr get_screen_coordinates_for_sprite
	jsr clear_block_at_screen_coordinates
	jsr prepare_snake_body_sprite_to_use

update_row_column_and_plot_something_on_screen
    lda direction_change_indicator
	beq .skip_direction_change_indicator_update  ;direction change indicator still zero?
	ldy segment_direction
	sta segment_direction
	sty direction_change_indicator
.skip_direction_change_indicator_update
    jsr update_screen_row_column
	jsr plot_something_on_screen
	jsr set_screen_coordinates_for_sprite

add_3_to_point_to_next_segment
    lda $06
	clc
	adc #3
	sta $06
	rts

;-----------------------------------------------------------------------------------
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

;-----------------------------------------------------------------------------------

data_directions_right_up
	!byte right, right, up, up
data_directions_left_down
	!byte left, left, down, down

;-----------------------------------------------------------------------------------

prepare_snake_body_sprite_to_use

    ldx snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	lda data_body_sprite_addresses_low,x  ;body sprites are in 3 different colours
	sta $10
	lda data_body_sprite_addresses_high,x
	sta $11
	rts

;-----------------------------------------------------------------------------------

prepare_snake_head_sprite_to_use

    ;determine address for player snake or enemy snake normal, or weak, and include their direction
    lda snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	asl
	asl  ;asl x 2 = multiply by 4
	adc segment_direction
	tax

	lda data_head_sprite_addresses_low-1,x
	sta $10
	lda data_head_sprite_addresses_high-1,x
	sta $11
	rts

;-----------------------------------------------------------------------------------

handle_player_movement

    ldy #0
	dec $1b
	bne perform_player_or_enemy_snake_movement
	lda $1a
	sta $1b
	rts

perform_player_or_enemy_snake_movement
    sty $06
	sty $05
	ldx #0
	stx direction_change_indicator
.set_snake_main_variables_loop
    lda player_and_enemy_table_word,y  ;player_and_enemy_table with offset for sprite in Y
	sta body_segments,x  ;update $0b, $0a, $09 (snake_direction), $08 (snake_colour), $07 (body_segments)
	iny
	inx
	cpx #5
	bcc .set_snake_main_variables_loop

	iny
	iny
	sty $06  ;points to player or enemy snake head (Y is 7 or enemy snake pointer + 7)
	jsr get_screen_coordinates_for_sprite
	jsr LA2FF
	jsr LABBA
	jsr LA314
	bne @LA421
	lda segment_direction
	sta direction_change_indicator
@LA421
    lda snake_direction
	beq @LA42A
	jsr LA362
	bcc @LA463
@LA42A
    jsr LA327
	bcc @LA46D
	ldy $0a
	bpl @LA43F
	ldx $05
	lda #0
	sta player_and_enemy_table+3,x
	cpy #128
	beq @LA46D
	bne @LA463  ;always branch

@LA43F
    lda snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	bne .determine_enemy_snake_direction
	jmp plot_entire_snake_on_screen_with_prepared_coordinates

.determine_enemy_snake_direction
    lsr $9114  ;set carry flag from timer
	bcs .carry_is_set_from_timer
@LA44B
    ldy segment_direction
	lda data_directions_right_up-1,y
	sta snake_direction
	jsr LA362
	bcc @LA463
.carry_is_set_from_timer
    ldy segment_direction
	lda data_directions_left_down-1,y
	sta snake_direction
	jsr LA362
	bcs @LA44B
@LA463
    lda snake_direction
	sta direction_change_indicator
	ldx $05
	lda #0
	sta player_and_enemy_table+2,x
@LA46D
    jsr clear_block_at_screen_coordinates
	jsr prepare_snake_head_sprite_to_use
	jsr update_row_column_and_plot_something_on_screen
	dec $07
@LA478
    jsr move_something_on_screen
	dec $07
	bne @LA478
	ldx $05
	lda #8
	sec
	sbc player_and_enemy_table,x
	tay
	jsr delay_using_Y
	bit $0b  ;TODO: what is this?
	bpl .end_perform_movement
	lda snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	bne .close_enemy_snake_door

    ; close player snake door after leaving home
	ldy screen_row
	cpy #118  ;outside player snake home door row?
	bne .end_perform_movement
	jsr @LA4AE
	jmp open_or_close_snake_entrance_door  ;close door (player snake)

.close_enemy_snake_door
    ; close enemy snakes door after leaving home
    ldy screen_row
	cpy #102  ;outside enemy snake home door row?
	bne .end_perform_movement
	jsr @LA4AE
	ldx #6  ;left edge column
	ldy #112  ;enemy snake home door row
	jmp open_or_close_snake_entrance_door_with_X_Y_coordinates  ;close door (enemy snakes)

@LA4AE
    lda #0
	ldx $05
	sta player_and_enemy_table+4,x
	sec  ;to set the door closed
.end_perform_movement
    rts

;-----------------------------------------------------------------------------------
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

;-----------------------------------------------------------------------------------

initialise_9000_series_and_other_data

    lda #$a4
	sta $00
	lda #$c0
	sta $01
	jsr initialise_9000_series_data
	lda #2
	ldy #0
	sta ($00),y
	rts

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

draw_maze

    ldx current_maze
	cpx #21  ;beyond max number of mazes available
	bcc .set_maze_build_from_address

    ; current maze number can exceed the 20 defined maze maps,
    ; so subtract 10 from current maze number to get one of the 20 maze maps
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

    ;draw the maze (which leaves unwanted maze parts on the top row and left column of the maze)
	lda #0
	sta $17
.draw_maze_loop_1
    jsr convert_byte_in_hex_17_to_screen_row_column
	jsr decide_which_maze_part_to_plot
	tax
	cpx #3
	bcc .skip_draw_maze_part
	dex
	jsr draw_maze_parts
	jsr convert_byte_in_hex_17_to_screen_row_column
	ldx #1
.skip_draw_maze_part
    jsr draw_maze_parts
	inc $17
	lda $17
	cmp #110  ;10 rows x 11 columns of parts needed to plot maze throughout the screen
	bcc .draw_maze_loop_1

    ;tidy top line of maze (loops 2 and 3)
	lda #10
	sta $17
	lda #<data_maze_part_2
	sta $10
	lda #>data_maze_part_2
	sta $11
.draw_maze_loop_2
    jsr convert_byte_in_hex_17_to_screen_row_column
	jsr clear_something_on_screen
	dec $17
	bpl .draw_maze_loop_2

	lda #10
	sta $17
	lda #<data_maze_part_3
	sta $10
	lda #>data_maze_part_3
	sta $11
.draw_maze_loop_3
    jsr convert_byte_in_hex_17_to_screen_row_column
	jsr plot_something_on_screen
	dec $17
	bpl .draw_maze_loop_3

    ;tidy left column of maze (loops 4 and 5)
	lda #99
	sta $17
	lda #<data_maze_part_4
	sta $10
	lda #>data_maze_part_4
	sta $11
.draw_maze_loop_4
    jsr convert_byte_in_hex_17_to_screen_row_column
	jsr clear_something_on_screen
	lda $17
	sec
	sbc #11
	sta $17
	bne .draw_maze_loop_4

	lda #<data_maze_part_5
	sta $10
	lda #>data_maze_part_5
	sta $11
	lda #99
	sta $17
.draw_maze_loop_5
    jsr convert_byte_in_hex_17_to_screen_row_column
	jsr plot_something_on_screen
	lda $17
	sec
	sbc #11
	sta $17
	bne .draw_maze_loop_5
	rts

;-----------------------------------------------------------------------------------
; maze part data

data_maze_part_1
    !byte %10100000
    !byte %10100000
    !byte %10100000
    !byte %10100000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

data_maze_part_2
    !byte %10100101
    !byte %10100101
    !byte %10100101
    !byte %10100101
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

data_maze_part_3
    !byte %01010101
    !byte %01010101
    !byte %01010101
    !byte %01010101
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

data_maze_part_4
    !byte %10100000
    !byte %10100000
    !byte %10100000
    !byte %10100000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000

data_maze_part_5
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000
    !byte %01010000

;-----------------------------------------------------------------------------------
; maze part addresses

data_maze_parts_low
    !byte <data_maze_part_1
	!byte <data_maze_part_2
	!byte <data_maze_part_4

data_maze_parts_high
    !byte >data_maze_part_1
	!byte >data_maze_part_2
    !byte >data_maze_part_4

;-----------------------------------------------------------------------------------

data_draw_maze_part_horizontal_offset
	!byte $08, $00

data_draw_maze_part_vertical_offset
	!byte $00, $08

;-----------------------------------------------------------------------------------

draw_maze_parts

    stx maze_part_to_plot
	lda data_maze_parts_low,x
	sta $10
	lda data_maze_parts_high,x
	sta $11
	jsr plot_something_on_screen
	ldx maze_part_to_plot
	beq .end_draw_maze_parts
	lda screen_column
	clc
	adc data_draw_maze_part_horizontal_offset-1,x
	sta screen_column
	lda screen_row
	adc data_draw_maze_part_vertical_offset-1,x
	sta screen_row
	lda $10
	clc
	adc #8
	sta $10
    bcc *+4  ;skip high byte update
	inc $11
    jmp plot_something_on_screen

.end_draw_maze_parts
    rts

;-----------------------------------------------------------------------------------

convert_byte_in_hex_17_to_screen_row_column

    lda $17
	ldx #0
	sec
.subtract_11_loop  ;divide A by 11 getting result in X
    inx
	sbc #11
	bcs .subtract_11_loop

	adc #11
	asl
	asl
	asl
	asl  ;asl x 4 = multiply by 16
	sta screen_column

	txa
	asl
	asl
	asl
	asl  ;asl x 4 = multiply by 16
	sta screen_row
	rts

;-----------------------------------------------------------------------------------

convert_screen_row_column_to_byte_in_hex_17

    lda screen_row
	lsr
	lsr
	lsr
	lsr
	sec
	sbc #1
	sta $17
	asl $17
	adc $17
	asl $17
	asl $17
	adc $17
	sta $17
	lda screen_column
	lsr
	lsr
	lsr
	lsr
	clc
	adc $17
	sta $17
	rts

;-----------------------------------------------------------------------------------

decide_which_maze_part_to_plot

    ;convert $17 to X and Y
    lda $17
	and #%00000011  ;3
	tax  ;X is 0, 1, 2 or 3
	lda $17
	lsr
	lsr
	tay
	lda (maze_address_low),y
.decide_maze_part_loop
    cpx #3
	bcs .end_decide_maze_part
	lsr
	lsr
	inx
	bne .decide_maze_part_loop  ;always branch
.end_decide_maze_part
    and #%00000011  ;3, so A is 0, 1, 2 or 3
	rts

;-----------------------------------------------------------------------------------

data_for_snake_entrance_door
    !byte %01010101
    !byte %01010101
    !byte %01010101
    !byte %01010101
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

;-----------------------------------------------------------------------------------

plot_player_snake_and_open_entrance_door

	lda #0
	sta snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	lda player_body_segments
	sta body_segments  ;points to player snake number of segments
	lda #7
	jsr plot_entire_snake_on_screen
	clc

;-----------------------------------------------------------------------------------

open_or_close_snake_entrance_door

    ldx #166  ;right edge column
	ldy #128  ;home door row
open_or_close_snake_entrance_door_with_X_Y_coordinates
    stx screen_column
	sty screen_row
	lda #<data_for_snake_entrance_door
	sta $10
	lda #>data_for_snake_entrance_door
	sta $11
	bcs .goto_plot_something_on_screen_1
	jmp clear_something_on_screen

.goto_plot_something_on_screen_1
    jmp plot_something_on_screen

;-----------------------------------------------------------------------------------

plot_entire_snake_on_screen

    sta $06  ;points to player or enemy snake head
	jsr get_screen_coordinates_for_sprite
plot_entire_snake_on_screen_with_prepared_coordinates
    jsr prepare_snake_head_sprite_to_use
	jmp .plot_snake_part_on_screen

.plot_snake_body_loop
    jsr get_screen_coordinates_for_sprite
	jsr prepare_snake_body_sprite_to_use
.plot_snake_part_on_screen
    jsr plot_something_on_screen
	jsr add_3_to_point_to_next_segment  ;coordinates of next segment
	dec $07  ;points to player or enemy snake number of segments
	bne .plot_snake_body_loop
	rts

;-----------------------------------------------------------------------------------

update_heading

    stx screen_column
	sty screen_row
	ldy #0
	sty $5c
.update_heading_loop
    jsr plot_block_at_screen_coordinates
	lda #0
	sta $11
	ldy $5c
	lda (text_pointer_low),y
	beq .end_update_heading

    ; convert a text character into a reverse character address
	sec
	sbc #64

	ldy #3
.convert_to_address_loop
    asl
	rol $11
	dey
	bne .convert_to_address_loop

	sta $10
	lda #128
	clc
	adc $11

	jsr plot_A_on_screen_given_screen_position_low_high_bytes
	inc $5c
	bne .update_heading_loop
.end_update_heading
    rts

;-----------------------------------------------------------------------------------

plot_block_at_screen_coordinates

    ; word in $10, $11 is $8500 (34048) which is a block character (8 bytes of $ff)
    ; $8400 to $87FF (33792 to 33815) is the reversed upper case and graphics area
    lda #0
	sta $10
	lda #133  ;$85
	sta $11
	jmp plot_something_on_screen

;-----------------------------------------------------------------------------------

clear_block_at_screen_coordinates

    ; word in $10, $11 is $8500 (34048) which is a block character (8 bytes of $ff)
    ; $8400 to $87FF (33792 to 33815) is the reversed upper case and graphics area
    lda #0
	sta $10
	lda #133  ;$85
	sta $11
	jmp clear_something_on_screen

;-----------------------------------------------------------------------------------

plot_A_on_screen

    asl
	asl
	asl
	ora #128
	sta $10
	lda #129

;-----------------------------------------------------------------------------------

plot_A_on_screen_given_screen_position_low_high_bytes

    sta $11
	jsr clear_something_on_screen  ;this unplots the value in A on the screen, which displays it in reverse
	lda screen_column
	clc
	adc #8
	sta screen_column
	rts

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

plot_level_and_headings_on_screen

    lda #<data_score_heading
	sta text_pointer_low
	lda #>data_score_heading
	sta text_pointer_high
	ldx #4
	ldy #0
	jsr update_heading

	lda #<data_level_heading
	sta text_pointer_low
	lda #>data_level_heading
	sta text_pointer_high
	ldx #4
	ldy #8
	jsr update_heading

	lda #48
	sta screen_column
	lda #8
	sta screen_row
	lda current_maze
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

;-----------------------------------------------------------------------------------

clear_player_and_high_score

    ldx #5
clear_player_score
    lda #0
.clear_player_score_loop
    sta player_score,x
	dex
	bpl .clear_player_score_loop
	rts

;-----------------------------------------------------------------------------------

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
	cmp #5
	bcc @LAA20
	ldx #5
@LAA20
    stx $5a
	jsr add_one_to_player_lives
.clear_decimal_and_end
    cld  ;clear decimal
	rts

;-----------------------------------------------------------------------------------

plot_player_score_on_screen

    ldx #0
	lda #0
	ldy #48
plot_score_on_screen
    sty screen_column
	sta screen_row
	lda #3
	sta $61
	lda #128
	sta $62
.check_score_bytes_loop
    lda player_score,x
	bne .score_byte_is_not_zero
	inx
	dec $61
	bne .check_score_bytes_loop
	rts

.score_byte_is_not_zero
    stx $5c
@LAA45
    ldx $5c
	lda player_score,x
	pha
	and #240
	bne @LAA56
	bit $62
	bpl @LAA56
	asl $62
	beq @LAA64
@LAA56
    asl $62
	lsr
	lsr
	lsr
	lsr
	pha
	jsr plot_block_at_screen_coordinates
	pla
	jsr plot_A_on_screen
@LAA64
    jsr plot_block_at_screen_coordinates
	pla
	and #15
	jsr plot_A_on_screen
	inc $5c
	dec $61
	bne @LAA45
	rts

;-----------------------------------------------------------------------------------

plot_high_score_on_screen

	ldx #3
	lda #0
	ldy #128
	jmp plot_score_on_screen

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

play_sounds

    ldx #4
.play_sounds_loop
    lda $6c,x
	sta $5f
	lda $71,x
	sta $60
	ldy $62,x
	lda $67,x
	beq @LAADA
	cmp #255  ;end of sound
	bne @LAAEF
.clear_sound_channel
    lda #0
	sta _VICCR9,x
	beq .next_sound_channel

@LAADA
    iny
	iny
	lda ($5f),y
	beq @LAADA
	sta $67,x
	cmp #255  ;end of sound
	beq .clear_sound_channel
	tya
	sta $62,x
	iny
	lda ($5f),y
	sta _VICCR9,x
@LAAEF
    dec $67,x
.next_sound_channel
    dex
	bne .play_sounds_loop
	rts

;-----------------------------------------------------------------------------------

prepare_sound_data
    stx $5f
	sty $60
	ldy #0
.init_sound_data_loop
    lda ($5f),y
	cmp #255  ;end of sound
	beq .end_data_byte_reached
	tax
	iny
	lda ($5f),y
	sta $6c,x
	iny
	lda ($5f),y
	sta $71,x
	lda #0
	sta $67,x
	lda #254
	sta $62,x
	iny
	bne .init_sound_data_loop
.end_data_byte_reached
    rts

;-----------------------------------------------------------------------------------

data_clear_all_sound_channels
	!byte $01, <data_sound_end, >data_sound_end
    !byte $02, <data_sound_end, >data_sound_end
    !byte $03, <data_sound_end, >data_sound_end
    !byte $04, <data_sound_end, >data_sound_end
data_sound_end
    !byte $ff

;-----------------------------------------------------------------------------------

clear_all_sound_channels

    ; clear sounds on each channel
    lda #%00101010  ;aux colour red, volume 10
	sta _VOLUME
	ldx #<data_clear_all_sound_channels
	ldy #>data_clear_all_sound_channels
	jsr prepare_sound_data
	jmp play_sounds

;-----------------------------------------------------------------------------------

set_enemy_snake_start_position

    lda current_maze
	cmp #1  ;first maze
	bne .not_maze_number_one
	lda #5  ;head plus 4 body parts, easier for the first maze, changes to 6 for the others
	sta snake_1_body_segments
	sta snake_2_body_segments
	sta snake_3_body_segments
.not_maze_number_one
    lda #0
	sta enemy_snake_table+30  ;TODO: what does this do?
	lda #120
	sta enemy_snake_table+90  ;TODO: what does this do?

	ldx #31  ;with below, points to enemy snake 1 body segments
perform_snake_entrance
    lda enemy_snake_table,x  ;enemy snake number of segments
	sta $07  ;points to player or enemy snake number of segments
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

;-----------------------------------------------------------------------------------

data_directions
	!byte down, up, left, right
data_to_compare_to_hex_77
	!byte 50, 80, 110, 140, 170, 190, 210, 225, 240, 250

;-----------------------------------------------------------------------------------

handle_enemy_snake_movement

    dec enemy_snake_speed_counter
	bne perform_enemy_snake_movement

    ; only skip enemy snake movement on speed counter of zero
    ; so a higher enemy_snake_speed_counter means more / quicker enemy snake movement
	lda enemy_snake_speed_control
	sta enemy_snake_speed_counter  ;reset back to the control value
	rts

;-----------------------------------------------------------------------------------

perform_enemy_snake_movement

    lda #0
	sta temp2
	ldx #31  ;with below, points to enemy snake 1
.each_snake_loop
    stx $1e
	ldy temp2
	lda $002e,y
	bpl .check_if_snake_should_enter_maze
	cmp #128
	beq .goto_delay_and_onto_next_snake
	jsr dead_snake_animation
	jmp .goto_next_snake

.check_if_snake_should_enter_maze
    ldy enemy_snake_table-1,x  ;TODO: what does this do?
	beq @LABA8
	dey
	tya
	sta enemy_snake_table-1,x  ;TODO: what does this do?
	beq .goto_perform_snake_entrance
.goto_delay_and_onto_next_snake
    ldy #7
	jsr delay_using_Y
	jmp .goto_next_snake

.goto_perform_snake_entrance
    jsr perform_snake_entrance
@LABA8
    ldy $1e
	jsr perform_player_or_enemy_snake_movement
.goto_next_snake
    inc temp2
	lda $1e
	clc
	adc #30  ;offset to next snake data
	tax
	cpx #92  ;last enemy snake offset
	bcc .each_snake_loop
	rts

;-----------------------------------------------------------------------------------

LABBA
    ldx snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	bne .enemy_snake_LABBF
.enemy_snake_end_LABBE
    rts

.enemy_snake_LABBF
    bit $13
	bmi .enemy_snake_end_LABBE
	jsr shift_77_series_bytes
	cmp #128
	bcc .enemy_snake_end_LABBE
	jsr shift_77_series_bytes

	ldy current_maze
	cpy #11
	bcc .use_current_maze_for_Y
	ldy #10  ;limit Y if maze number is too big
.use_current_maze_for_Y
    cmp data_to_compare_to_hex_77-1,y
	bcc @LABED
@LABDA
    jsr shift_77_series_bytes
	and #%00000011  ;3
	clc
	adc #1
	ldy segment_direction
	cmp data_directions-1,y
	bne @LABEA
	tya
@LABEA
    sta snake_direction
	rts

@LABED
    lda segment_direction
	cpx #2
	beq @LAC20
	bit $77
	bpl @LAC0B
@LABF7
    ldx #1
	ldy screen_row
    cpy player_body_segments+7  ;snake head row
	beq @LAC0B
	bcs @LAC03
	ldx #2
@LAC03
    cmp data_directions-1,x
	beq @LAC0A
	stx snake_direction
@LAC0A
    rts

@LAC0B
    ldx #4
	ldy screen_column
	cpy player_body_segments+6  ;snake head column
	beq @LAC19
	bcs @LAC03
	ldx #3
	bne @LAC03

@LAC19
    ldy screen_row
	cpy player_body_segments+7  ;snake head row
	bne @LABF7
@LAC1F
    rts

@LAC20
    ldx #3
	ldy player_egg_location_column
	beq @LABDA
	cpy screen_column
	beq @LAC30
	bcs @LAC03
	ldx #4
	bne @LAC03

@LAC30
    ldx #2
	ldy player_egg_location_row
	cpy screen_row
	beq @LAC1F
	bcs @LAC03
	ldx #1
	bne @LAC03

shift_77_series_bytes
    stx $7c
	lda $77
	sec
	adc $7a
	adc $7b
	sta $77

	ldx #3
.shift_77_series_bytes_4_times_loop
    lda $77,x  ;$7a, $79, $78, $77
	sta $78,x  ;$7b, $7a, $79, $78
	dex
	bpl .shift_77_series_bytes_4_times_loop
	ldx $7c
	rts

;-----------------------------------------------------------------------------------

init_zero_page_with_timers

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

;-----------------------------------------------------------------------------------

more_player_and_enemy_snake_interactions

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

;-----------------------------------------------------------------------------------
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

;-----------------------------------------------------------------------------------
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

;-----------------------------------------------------------------------------------

dead_snake_animation

    ldx $1e
	sta temp3
	lda player_and_enemy_table,x
	sta body_segments
	txa
	clc
	adc #7
	sta $06  ;points to player or enemy snake head
.dead_snake_animate_loop
    jsr get_screen_coordinates_for_sprite
	jsr clear_block_at_screen_coordinates
	lda temp3
	and #7
	lsr
	cmp #2
	bcc @LACE2
	tax
	lda dead_snake_part_address_low-2,x
	sta $10
	lda dead_snake_part_address_high-2,x
	sta $11
	jsr plot_something_on_screen
@LACE2
    jsr add_3_to_point_to_next_segment
	dec body_segments
	bne .dead_snake_animate_loop
	rts

;-----------------------------------------------------------------------------------

calculate_score_values_for_maze

    lda current_maze
	cmp #21  ;beyond max number of mazes available
	bcc .maze_less_than_21
	lda #20  ; cap maze to 20 for calculating score values
.maze_less_than_21
    pha
	lsr  ;divide maze number (level) by two
	tax  ;becomes X
	tay  ;and Y

    ; calculate score for eating snake head
	lda #0
	sed  ;set to decimal
	clc
.increase_eat_snake_head_score_loop
    adc #2  ;represents increment of 200 points varied by maze number divided by two
	dex
	bpl .increase_eat_snake_head_score_loop
	sta score_for_eat_snake_head

    ; calculate score for eating snake body segment
	clc
	lda #0
.increase_eat_snake_body_score_loop
    adc #1  ;represents increment of 100 points varied by maze number divided by two
	dey
	bpl .increase_eat_snake_body_score_loop
	sta score_for_eat_snake_body

	pla  ;get maze number (level) again
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

;-----------------------------------------------------------------------------------

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
	stx temp1
	adc temp1
	sta temp1
	tax

    ; get the coordinates from the last segment
	lda #0
	sta player_and_enemy_table,x  ;player or enemy snake last segment direction
	lda player_and_enemy_table-2,x  ;player or enemy snake last segment column
	sta screen_column
	lda player_and_enemy_table-1,x  ;player or enemy snake last segment row
	sta screen_row

	jsr LA314
	bne @LAD59

    ; update the new segment with the last segment coordinates
	ldx temp1
	lda #0
	sta player_and_enemy_table-3,x  ;player or enemy snake new segment direction
	lda screen_row
	sta player_and_enemy_table+2,x  ;player or enemy snake new segment row
	lda screen_column
	sta player_and_enemy_table+1,x  ;player or enemy snake new segment column

.end_add_segment_to_body
    rts

@LAD59
    ldx temp1
	ldy player_and_enemy_table-3,x  ;player or enemy snake new segment direction
	jsr @LAD73
	cpy #4
	jsr @LAD6B
	inx
	jsr @LAD73
	cpy #1

@LAD6B
    bne .update_new_segment_column
	clc
	adc #8
.update_new_segment_column
    sta player_and_enemy_table+1,x  ;player or enemy snake new segment column
	rts

@LAD73
    lda player_and_enemy_table-2,x  ;player or enemy snake last segment column
	sec
	sbc #6
	and #248
	clc
	adc #6
	rts

;-----------------------------------------------------------------------------------

handle_eat_snake_body_update

    ldx $1e
perform_eat_snake_body_update
    jsr get_screen_coordinates_for_last_segment  ;enemy snake
	jsr clear_block_at_screen_coordinates
	ldx temp1  ;points to player or enemy snake
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

;-----------------------------------------------------------------------------------

LAD9D
    ldy #2
	ldx $1e
@LADA1
    lda player_and_enemy_table_word+5,y
	sec
	sbc player_and_enemy_table+7,x
	bcs @LADAD
	eor #255
	adc #1
@LADAD
    cmp #5
	bcs @LADB6
	dex
	dey
	bne @LADA1
	clc
@LADB6
    rts

;-----------------------------------------------------------------------------------

handle_player_and_enemy_snake_interactions

    ldx #11
	lda #0
.zero_hex_34_to_3f_loop
    sta $34,x  ;$34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f
	dex
	bpl .zero_hex_34_to_3f_loop
	sta $7c

	ldx #31  ;with below, points to enemy snake 1 body segments
	txa
.check_next_snake_loop_3
    sta $05
	stx $1e
	lda enemy_snake_table-1,x  ;TODO: what does this do?
	bne @LAE26
	lda enemy_snake_table,x  ;enemy snake number of segments
	sta body_segments
	ldx $1e
	ldy #2
@LADD5
    lda player_and_enemy_table_word+5,y
	sec
	sbc enemy_snake_table+7,x  ;enemy snake head row
	bcs @LADE1
	eor #255
	adc #1
@LADE1
    cmp #48
	bcc @LADED
	ldx $7c
	lda #128
	sta $3d,x
	bne @LAE1A

@LADED
    dex
	dey
	bne @LADD5
	ldx $7c
	lda snake_tick_table,x
	bne @LAE1A
	jsr LAD9D
	bcs @LAE04
	ldx $7c
	lda #128
	sta $34,x
	bne @LAE1A

@LAE04
    lda $1e
	clc
	adc #3
	sta $1e
	dec $07
	beq @LAE1A
	jsr LAD9D
	bcs @LAE04
	ldx $7c
	lda #128
	sta $37,x
@LAE1A
    inc $7c
	lda $05
	clc
	adc #30  ;offset to next snake data
	tax
	cmp #92  ;last enemy snake offset
	bcc .check_next_snake_loop_3

@LAE26
    lda #0
	sta $7c

	ldx #31  ;with below, points to enemy snake 1
.check_next_snake_loop
    stx $1e
	lda enemy_snake_table-1,x  ;TODO: what does this do?
	bne .check_and_handle_snake_body_or_head_being_eaten
	ldx $7c
	lda $3d,x
	bne @LAE73
	lda $31,x
	bne @LAE73
	ldx player_body_segments
	dex
	stx $07
	ldx #9
@LAE43
    stx $06
	ldy $1e
	lda #2
	sta temp2
@LAE4B
    lda player_and_enemy_table_word+6,y
	sec
	sbc enemy_snake_table,x
	bcs @LAE57
	eor #255
	adc #1
@LAE57
    cmp #5
	bcs @LAE69
	inx
	iny
	dec temp2
	bne @LAE4B
	ldx $7c
	lda #128
	sta $3a,x
	bne @LAE73

@LAE69
    lda $06
	clc
	adc #3
	tax
	dec $07
	bne @LAE43
@LAE73
    inc $7c
	lda $1e
	clc
	adc #30  ;offset to next snake data
	tax
	cmp #92  ;last enemy snake offset
	bcc .check_next_snake_loop

.check_and_handle_snake_body_or_head_being_eaten
    lda #0
	sta snake_counter  ;0, 1, 2
	ldy #31  ;with below, points to enemy snake 1 body segments
.check_next_snake_loop_2
    sty $1e
	ldx snake_counter
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
    inc snake_counter
	lda $1e
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
	ldx snake_counter
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
	cmp #2
	bne .remove_segment
	stx player_egg_status
	stx player_egg_location_column
.remove_segment
    jsr perform_eat_snake_body_update
	bcs .continue_onto_next_snake
	jmp handle_player_dies

.check_for_weak_enemy_snake
    ldx #31  ;with below, points to enemy snake 1 body segments
.check_for_weak_next_snake_loop
    lda enemy_snake_table,x  ;enemy snake number of segments
	cmp player_body_segments
	bcc .enemy_snake_is_smaller_than_player
	lda #1  ;red colour snake
	!byte $2c  ; odd - an error? $2c is the bit (absolute) instruction
               ; so this part could read lda #1  bit $02a9  sta enemy_snake_table+1,x
               ; the bit instruction is spurious and has no effect

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

;-----------------------------------------------------------------------------------
; Junk bytes not used, they could be replaced with !fill 200,0 but are kept to allow
; a matching binary comparison with the original program
data_junk_bytes
    !byte $1a, $af, $20, $62, $b3, $20, $e4, $b3, $e8, $e0, $07, $d0, $f2, $a9, $40, $85
    !byte $1e, $a9, $50, $85, $1f, $a5, $10, $38, $e9, $01, $0a, $aa, $bd, $02, $af, $85
    !byte $c2, $bd, $03, $af, $85, $c3, $a0, $00, $98, $48, $b1, $c2, $20, $62, $b3, $68
    !byte $a8, $a5, $1e, $18, $69, $08, $85, $1e, $c8, $c0, $06, $d0, $eb, $20, $29, $b3
    !byte $09, $20, $85, $35, $e6, $28, $a5, $28, $f0, $07, $c9, $7f, $f0, $03, $4c, $8c
    !byte $af, $20, $3d, $b0, $20, $29, $b3, $09, $20, $c5, $35, $f0, $e7, $4c, $73, $b2
    !byte $a9, $3c, $85, $1e, $a2, $07, $a0, $00, $a9, $4e, $85, $1f, $8a, $48, $20, $7e
    !byte $b3, $68, $aa, $a9, $00, $91, $00, $a0, $14, $91, $00, $20, $e4, $b3, $ca, $10
    !byte $e5, $60, $54, $5c, $b4, $bc, $be, $be, $be, $be, $47, $01, $0d, $05, $20, $4f
    !byte $16, $05, $12, $20, $3e, $ad, $20, $73, $b2, $20, $ee, $ab, $20, $c1, $b1, $a9
    !byte $38, $85, $1e, $a9, $58, $85, $1f, $a2, $00, $bd, $c2, $af, $20, $62, $b3, $20
    !byte $e4, $b3, $e8, $e0, $09, $d0, $f2, $20, $2a, $a7, $20, $2a, $a7, $20, $67, $a1
    !byte $20, $2a, $a7, $4c, $2a, $a7, $05, $ff

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

clear_25_2d_2b
    lda #0
	sta enemy_egg_status  ;set to zero
	sta player_egg_status  ;set to zero
	sta player_egg_location_column  ;set to zero
	rts

;-----------------------------------------------------------------------------------

update_hex_20_21_using_timer

    lda #1
	lsr $9124  ;timer least significant byte (LSB) of count move to carry
	bcc .timer_carry_is_clear
	lda #0
.timer_carry_is_clear
    sta $21
	jsr shift_77_series_bytes
	and #%00111111  ;63
	ora #%00001111  ;15
	sta $20
	rts

;-----------------------------------------------------------------------------------

clear_developing_egg_sprite

    lda #<developing_egg_sprite
	sta $10
	lda #>developing_egg_sprite
	sta $11
	jmp clear_something_on_screen

;-----------------------------------------------------------------------------------

LB044
    jsr shift_77_series_bytes
	pha
	ora #63
	sta $28
	pla
	and #3
	ora #1
	sta $29
	lda player_egg_status
	cmp #2
	bne @LB05D
	lda #1
	sta $29
@LB05D
    rts

;-----------------------------------------------------------------------------------

reset_developing_egg_status_for_enemy_snake

    lda snake_counter
	cmp enemy_snake_with_egg
	bne .end_reset_developing_egg_status
	lda enemy_egg_status
	cmp #3
	beq .end_reset_developing_egg_status
	lda #0
	sta enemy_egg_status  ;set to zero
.end_reset_developing_egg_status
    rts

;-----------------------------------------------------------------------------------

handle_player_and_enemy_snake_eggs

    ldy enemy_egg_status
	bne perform_enemy_snake_egg_actions

	ldx #2
.check_for_dead_snake_loop

    ; a snake must be dead for the other snakes to be able to lay a new egg replacement
    lda snake_tick_table,x  ;0, 1, 2
	cmp #128  ;is snake dead?
	bne .skip_to_another_snake

    ;dead snake candidate is available to replace with a laid egg
	stx dead_enemy_snake_to_replace_with_egg  ;0, 1, 2

	ldx #2
.check_candidate_snake_to_lay_egg_loop

    lda snake_tick_table,x  ;0, 1, 2
	bmi .skip_to_next_candidate_snake  ;can't lay a replacement egg immediately after snake has died

	ldy data_enemy_snake_table_offsets,x
	lda player_and_enemy_table_word,y  ;player or enemy snake number of segments
	cmp #3
	bcc .skip_to_next_candidate_snake  ;not enough segments to allow an egg to be laid

	lda player_and_enemy_table_word+4,y  ;TODO: what is this for?
	bmi .skip_to_next_candidate_snake

	stx enemy_snake_with_egg  ;0, 1, 2
	inc enemy_egg_status
	jsr update_hex_20_21_using_timer

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

;-----------------------------------------------------------------------------------

perform_enemy_snake_egg_actions

    dec $20
	bne @LB117
	dec $21
	bpl @LB117
	cpy #3
	bne @LB0E3
	ldy dead_enemy_snake_to_replace_with_egg  ;0, 1, 2
	lda #0
	sta $002e,y
	sta enemy_egg_status  ;set to zero
	ldx data_enemy_snake_table_offsets,y
	lda #1
	tay
	sta enemy_snake_table,x  ;enemy snake number of segments
	lda #2
	cmp player_body_segments
	bcs *+3  ;skip next instruction
	iny  ;change to weak green colour snake
    tya  ;keep with normal red colour snake
	sta enemy_snake_table+1,x  ;enemy snake colour number

	ldy #2
@LB0CF
    lda $0022,y
	sta enemy_snake_table+7,x  ;enemy snake head row
	dex
	dey
	bpl @LB0CF

	txa
	clc
	adc #8
	tax
	jsr add_segment_to_player_or_enemy_snake_body  ;has the last segment coordinates at this point
	jmp .lay_an_enemy_snake_egg_at_given_location

@LB0E3
    cpy #1
	bne @LB0EE
	jsr update_hex_20_21_using_timer
	inc enemy_egg_status
	bne .lay_an_enemy_snake_egg
@LB0EE
    ldy enemy_snake_with_egg
	ldx data_enemy_snake_table_offsets,y
	jsr get_screen_coordinates_for_last_segment  ;enemy snake
	jsr LA314
	bne @LB101
	inc $21
	inc $20
	bne @LB117
@LB101
    jsr update_hex_20_21_using_timer
	inc enemy_egg_status
	ldy enemy_snake_with_egg
	ldx data_enemy_snake_table_offsets,y
	jsr perform_eat_snake_body_update

	ldx #2
.update_enemy_egg_location_row_col_loop
    lda screen_coords_table,x  ;get $0f (screen_row), $0e (screen_column), $0d (segment_direction)
	sta $22,x  ;update $24 (enemy_egg_location_row), $23 (enemy_egg_location_column), $22 (segment_direction)
	dex
	bpl .update_enemy_egg_location_row_col_loop

@LB117
    ldy enemy_egg_status
	cpy #1
	beq perform_player_egg_actions
	cpy #3
	bne .lay_an_enemy_snake_egg

	ldx #2
@LB123
    lda enemy_snake_table+5,x  ;enemy snake head direction
	sec
    sbc $22,x  ;subtract $24 (enemy_egg_location_row), $23 (enemy_egg_location_column), $22 (segment_direction)
	bcs @LB12E
	eor #255
	adc #1
@LB12E
    cmp #5
	bcs .lay_an_enemy_snake_egg_at_given_location  ;has the last segment coordinates at this point
	dex
	bne @LB123

    ; egg has been eaten, clear egg from screen and add it to player score
	stx enemy_egg_status  ;X is zero at this point
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

.lay_an_enemy_snake_egg_at_given_location
    lda enemy_egg_location_column
	sta screen_column
	lda enemy_egg_location_row
	sta screen_row
	bne .plot_enemy_egg_on_screen  ;always branch

.lay_an_enemy_snake_egg
    ; point to the last segment for the snake with a developing egg
    ldy enemy_snake_with_egg
	ldx data_enemy_snake_table_offsets,y
	stx $06
	lda enemy_snake_table,x  ;enemy snake number of segments
	asl
	adc enemy_snake_table,x  ;enemy snake number of segments
	adc $06
	adc #4
	sta $06
	jsr get_screen_coordinates_for_sprite

.plot_enemy_egg_on_screen
    ; clear the developing egg and plot a laid egg
    jsr clear_developing_egg_sprite
	lda #<enemy_snake_egg_sprite
	sta $10
	lda #>enemy_snake_egg_sprite
	sta $11
	jsr plot_something_on_screen

;-----------------------------------------------------------------------------------

perform_player_egg_actions

    lda player_egg_status
	bne @LB195
	lda player_lives
	cmp #9  ;player lives
	bcs @LB194
@LB18F
    inc player_egg_status
	jmp LB044
@LB194
    rts

@LB195
    cmp #3
	bne @LB1DC

	ldx #31  ;with below, points to enemy snake 1
@LB19B
    ldy #2
	stx $1e
@LB19F
    lda enemy_snake_table+7,x  ;enemy snake head row
	sec
	sbc $002a,y
	bcs @LB1AB
	eor #255
	adc #1
@LB1AB
    cmp #5
	bcs .move_to_next_snake
	dex
	dey
	bne @LB19F
	lda player_egg_location_column
	sta screen_column
	lda player_egg_location_row
	sta screen_row
	lda #0
	sta player_egg_location_column
	sta player_egg_status  ;set to zero
	jsr clear_block_at_screen_coordinates
	jsr prepare_eat_frog_egg_snake_head_sound
	lda $1e
	clc
	adc #5
	tax
	jmp add_segment_to_player_or_enemy_snake_body

.move_to_next_snake
    lda $1e
	clc
	adc #30  ;offset to next snake data
	tax
	cmp #92  ;last enemy snake offset
	bcc @LB19B
	bcs perform_plot_player_egg_on_screen  ;always branch

@LB1DC
    dec $28
	bne .check_for_laying_player_egg
	dec $29
	bpl .check_for_laying_player_egg
	ldx #0
	jsr get_screen_coordinates_for_last_segment  ;player snake
	jsr LA314
	bne @LB1F4
	inc $29
	inc $28
	bne .check_for_laying_player_egg
@LB1F4
    jsr @LB18F
	lda player_egg_status
	cmp #2
	beq .check_for_laying_player_egg
	ldx #0
	jsr perform_eat_snake_body_update
	bcs @LB20F
	ldx #0
	jsr get_screen_coordinates_for_last_segment  ;player snake
	jsr set_egg_screen_column_row
	jmp clear_maze_objects_and_player_loses_life

@LB20F
    jsr set_egg_screen_column_row
	bne perform_plot_player_egg_on_screen

.check_for_laying_player_egg
    lda player_egg_status
	cmp #3
	beq perform_plot_player_egg_on_screen
	cmp #1
	beq .end_screen_coordinates_for_last_segment

    ; lay the developing egg for the player
	lda player_body_segments
	asl
	adc player_body_segments
	adc #4
	sta $06  ;points to the segment holding the egg to be laid
	jsr get_screen_coordinates_for_sprite  ;get this screen coordinate for plotting on screen
	jmp .plot_player_egg_on_screen

;-----------------------------------------------------------------------------------

perform_plot_player_egg_on_screen

    lda player_egg_location_column
	sta screen_column
	lda player_egg_location_row
	sta screen_row
.plot_player_egg_on_screen
    jsr clear_developing_egg_sprite
	lda #<player_snake_egg_sprite
	sta $10
	lda #>player_snake_egg_sprite
	sta $11
	jmp plot_something_on_screen

;-----------------------------------------------------------------------------------

get_screen_coordinates_for_last_segment

    lda player_and_enemy_table,x  ;player or enemy snake number of segments
	stx temp1
	asl
	adc player_and_enemy_table,x  ;player or enemy snake number of segments
	adc temp1
	tax
	ldy #2
.get_last_segment_screen_coords_loop
    lda player_and_enemy_table+4,x
	sta screen_coords_table_word,y
	dex
	dey
	bpl .get_last_segment_screen_coords_loop
.end_screen_coordinates_for_last_segment
    rts

;-----------------------------------------------------------------------------------

set_egg_screen_column_row

    lda screen_column
	sta player_egg_location_column
	lda screen_row
	sta player_egg_location_row
	lda segment_direction
	sta $2a
	rts

;-----------------------------------------------------------------------------------
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

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

set_frog_to_clear_on_screen

    lda #%10000000  ;128
	sta frog_display
goto_shift_77_series_bytes
    jsr shift_77_series_bytes
	and #%01111111  ;127
	ora #%00011111  ;31
	sta $43
	rts

;-----------------------------------------------------------------------------------

LB2B5_returns_A_0_or_3
    stx screen_column
	sty screen_row

	ldx #1
.loop_twice_LB2BB
    lda screen_column,x
	sec
	sbc frog_location_column,x  ;subtracts $41 (frog_location_column), $42 (frog_location_row)
	bcs @LB2C6
	eor #255
	adc #1
@LB2C6
    cmp #9
	bcs .set_A_to_3
	dex
	bpl .loop_twice_LB2BB

	jsr clear_block_at_screen_coordinates
	lda #0
	rts

.set_A_to_3
    lda #3
	rts

;-----------------------------------------------------------------------------------

handle_frog_actions

    bit frog_display
	bpl .frog_is_on_screen
	jmp @LB358

.frog_is_on_screen
    ldx #6
	stx $1e
	dex
	bne @LB2E6
@LB2E4
    stx $1e
@LB2E6
    ldy #1
@LB2E8
    lda player_and_enemy_table+2,x
	sec
	sbc $0041,y
	bcs @LB2F4
	eor #255
	adc #1
@LB2F4
    cmp #7
	bcs @LB32C
	dex
	dey
	bpl @LB2E8

	ldx $1e
	cpx #6
	bne @LB30F
	lda #5  ;represents 500 points for eating a frog
	clc
	jsr update_player_score
	jsr plot_player_score_on_screen
	ldx #5
	bne .add_segment_to_player_body  ;always branch

@LB30F
    ldy #0
	cpx #36
	beq @LB31B
	iny
	cpx #66
	beq @LB31B
	iny
@LB31B
    lda $002e,y
	bmi @LB32C
.add_segment_to_player_body
    jsr add_segment_to_player_or_enemy_snake_body  ;is player body in this case
	jsr plot_frog_sprite_on_screen
	jsr prepare_eat_frog_egg_snake_head_sound
	jmp set_frog_to_clear_on_screen

@LB32C
    lda $1e
	clc
	adc #30  ;offset to next snake data
	tax
	cpx #97
	bcc @LB2E4
	lda player_egg_status
	cmp #3
	bne @LB349
	ldx player_egg_location_column
	ldy player_egg_location_row
	jsr LB2B5_returns_A_0_or_3
	bne @LB349
	sta player_egg_status  ;set to zero
	sta player_egg_location_column
@LB349
    lda enemy_egg_status
	cmp #3
	bne @LB358
	ldx enemy_egg_location_column
	ldy enemy_egg_location_row
	jsr LB2B5_returns_A_0_or_3
	sta enemy_egg_status  ;is zero or 3
@LB358
    dec $43
	beq @LB361
	bit frog_display
	bpl .goto_plot_frog_on_screen
	rts

@LB361
    ldx #<data_frog_ribbit_sound_clip
	ldy #>data_frog_ribbit_sound_clip
	jsr prepare_sound_data

	jsr goto_shift_77_series_bytes
	bit frog_display
	bpl @LB3B1
	asl frog_display
	jsr shift_77_series_bytes
	ldy #20
	ldx #4
	and #3
	beq @LB384
	cmp #2
	bcs @LB395
	ldy #164
	ldx #0
@LB384
    sty frog_location_row
	stx $44
	jsr shift_77_series_bytes
	and #112
	clc
	adc #20
	sta frog_location_column
.goto_plot_frog_on_screen
    jmp .goto_start_plot_frog

@LB395
    ldx #4
	ldy #6
	cmp #2
	beq @LB3A1
	ldx #164
	ldy #2
@LB3A1
    stx frog_location_column
	sty $44
	jsr shift_77_series_bytes
	and #48
	clc
	adc #20
	sta frog_location_row
	bne .goto_plot_frog_on_screen
@LB3B1
    jsr plot_frog_sprite_on_screen
	ldx player_egg_location_column
	ldy player_egg_location_row
	lda player_egg_status
	cmp #3
	beq @LB3C8
	ldx enemy_egg_location_column
	ldy enemy_egg_location_row
	lda enemy_egg_status
	cmp #3
	bne @LB3F1
@LB3C8
    stx screen_column
	sty screen_row

	ldx #1
@LB3CE
    ldy data_to_switch_frog_increments,x  ;Y is 0 or 2
	lda frog_location_column,x
	sec
	sbc screen_column,x
	bcs @LB3E0
	eor #255
	adc #1
	iny
	iny
	iny
	iny  ;Y is 4 or 6 at this point
@LB3E0
    cmp #25
	bcs @LB409
	pha
	lda data_to_get_frog_column_increments,y  ;Y could be 0, 2, 4, 6
	tay  ;new Y from data
	pla
	cmp #9
	bcs @LB409
	dex
	bpl @LB3CE

@LB3F1
    ldy #255
	jsr shift_77_series_bytes
	cmp #85
	bcc @LB400
	iny
	cmp #170
	bcc @LB400
	iny
@LB400
    tya
	clc
	adc $44
	and #7
	sta $44
	tay
@LB409
    lda frog_location_column
	clc
	adc data_frog_column_increments,y
	cmp #165
	bcc @LB416
.goto_set_frog_to_clear_on_screen
    jmp set_frog_to_clear_on_screen

@LB416
    sta frog_location_column
	lda frog_location_row
	clc
	adc data_frog_row_increments,y
	cmp #165
	bcs .goto_set_frog_to_clear_on_screen
	cmp #20
	bcc .goto_set_frog_to_clear_on_screen
	sta frog_location_row
.goto_start_plot_frog
    lda #0
	!byte $2c  ; odd - an error? $2c is the bit (absolute) instruction
               ; so this part could read lda #0  bit $80a9  sta $45
               ; the bit instruction is spurious and has no effect

plot_frog_sprite_on_screen
    lda #128
	sta $45
	lda frog_location_column
	sta screen_column
	lda frog_location_row
	sta screen_row
	lda #<data_frog_top_left
	ldx #>data_frog_top_left
	jsr .goto_prepare_and_plot_something_on_screen
	lda screen_column
	clc
	adc #8
	sta screen_column
	lda #<data_frog_top_right
	ldx #>data_frog_top_right
	jsr .goto_prepare_and_plot_something_on_screen
	lda screen_row
	clc
	adc #8
	sta screen_row
	lda #<data_frog_bottom_right
	ldx #>data_frog_bottom_right
	jsr .goto_prepare_and_plot_something_on_screen
	lda screen_column
	sec
	sbc #8
	sta screen_column
	lda #<data_frog_bottom_left
	ldx #>data_frog_bottom_left
.goto_prepare_and_plot_something_on_screen
    sta $10
	stx $11
	bit $45
	bpl .goto_plot_something_on_screen_2
	jmp clear_something_on_screen

.goto_plot_something_on_screen_2
    jmp plot_something_on_screen

;-----------------------------------------------------------------------------------

data_9000_to_900f_values
    !byte %00001100  ;_HORIZONTAL_ALIGNMENT = $9000  ;36864 bits 0-6 horizontal centering, bit 7 sets interlace scan
	!byte %00100110  ;_VERTICAL_ALIGNMENT = $9001  ;36865 vertical centering
	!byte %10010110  ;_VICCR2 = $9002  ;36866, used for setting number of columns displayed
                     ;  bit 7: see _VICCR5 below
                     ;  bit 6-0: 22 means 22 characters per column
	!byte %00010111  ;_VICCR3 = $9003  ;36867, used for setting number of rows displayed
                     ;  bit 7: raster beam location bit 0 (n/a here)
                     ;  bit 6-1: 22 means 11 character lines
                     ;  bit 0: 1 for 8 x 16 pixel character size
	!byte 0  ;_VICCR4 = $9004  ;36868, raster beam location bits (n/a here)
	!byte %10001100  ;_VICCR5 = $9005  ;36869, used for setting custom characters location
                     ;  bit 7-4: 1000 + _VICCR2 bit 7 (is 1) means screen is located at $somewhere (decimal), and colour map at $9600 (38400)
                     ;  bit 3-0: 1100 means character map is located at $1000 (4096)
	!byte 0  ;_VICCR6 = $9006  ;36870  light pen horizontal screen location (n/a here)
	!byte 0  ;_VICCR7 = $9007  ;36871  light pen vertical screen location (n/a here)
	!byte 255  ;_VICCR8 = $9008  ;36872  paddle X location (n/a here)
	!byte 255  ;_VICCR9 = $9009  ;36873  paddle Y location (n/a here)
	!byte 0  ;_SOUND1 = $900a  ;36874
	!byte 0  ;_SOUND2 = $900b  ;36875
	!byte 0  ;_SOUND3 = $900c  ;36876
	!byte 0  ;_NOISE = $900d  ;36877
	!byte %00100000  ;_AUXILIARY_COLOUR = $900e  ;36878 bit 7-4 aux colour is 2 for red
                     ;_VOLUME = $900e  ;36878 bit 3-0 is 0 for no volume
	!byte %00001110  ;_BACKGROUND_BORDER_COLOUR = $900f  ;36879
                     ;  bit 7-4 is 0 for black background
                     ;  bit 3-0 is 14 for blue border

;-----------------------------------------------------------------------------------

initialise_9000_series_data
    ldy #15
.init_data_loop
    lda data_9000_to_900f_values,y
	sta $9000,y
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

;-----------------------------------------------------------------------------------

draw_maze_and_set_enemy_snake_start_position

    jsr initialise_zero_page
	jsr draw_maze
	jmp set_enemy_snake_start_position

;-----------------------------------------------------------------------------------

read_joystick_to_start_game

    jsr read_joystick
	bcc .valid_joystick_action
	rts

.valid_joystick_action
    cmp #JOY_FIRE
	bne .valid_joystick_move_direction
	jsr clear_all_sound_channels
	jmp start_game_play

.valid_joystick_move_direction
    ldx _HORIZONTAL_ALIGNMENT
	ldy _VERTICAL_ALIGNMENT
	cmp #JOY_UP
	bne .check_screen_align_down
	dey
.save_screen_alignment
    stx _HORIZONTAL_ALIGNMENT
	sty _VERTICAL_ALIGNMENT
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

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

draw_scroll_heading_line

    lda #0
	sta text_pointer_low
	lda #1
	sta text_pointer_high
	lda #255
	sta scroll_heading_position
	bne scroll_data_line  ;always branch

scroll_heading_data_lines

    ldx scroll_heading_delay
	ldy #8
	jsr update_heading
	ldx #168
	stx screen_column
	jsr plot_block_at_screen_coordinates
	ldx scroll_heading_delay
	dex
	dex
	beq .reset_scroll_delay
	stx scroll_heading_delay
	rts

.reset_scroll_delay
    ldx #0
	stx screen_column
	jsr plot_block_at_screen_coordinates

;-----------------------------------------------------------------------------------

scroll_data_line

    ldx #8
	stx scroll_heading_delay
	ldy #0
	ldx scroll_heading_position
	inx
	cpx #73  ;length of scroll message
	bcc .scroll_message_not_ended
	ldx #0
.scroll_message_not_ended
    stx scroll_heading_position
.plot_scroll_row_loop
    lda data_scrolling_heading_message,x
	bne .continue_scroll_message
	ldx #0
	lda data_scrolling_heading_message,x
.continue_scroll_message
    sta $0100,y
	inx
	iny
	cpy #20
	bcc .plot_scroll_row_loop
	lda #0
	sta $0100,y
	rts

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

display_opening_title_screen

    jsr set_screen_base_colours
	jsr initialise_0200_onwards_with_increments_of_11
	jsr clear_512_custom_characters
	jsr clear_all_sound_channels
	lda #%00101010  ;aux colour red, volume 10
	sta _VOLUME
	ldx #<data_starting_game_on_sound_clip
	ldy #>data_starting_game_on_sound_clip
	jsr prepare_sound_data

    ; display "creative software" in heading
	lda #<data_heading_publisher
	sta text_pointer_low
	lda #>data_heading_publisher
	sta text_pointer_high
	ldx #12
	ldy #0
	jsr update_heading

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
	sta text_pointer_low
	lda #>data_heading_presents_title
	sta text_pointer_high
	ldx #56
	ldy #8
	jsr update_heading

    ; continue opening short tune on game start
	lda #39
	sta sound_loop_counter
.play_short_tune_loop
    jsr play_sounds
	ldy #25
	jsr delay_using_Y
	dec sound_loop_counter
	bne .play_short_tune_loop

	ldx #4
.delay_using_X_4_2
    ldy #255
	jsr delay_using_Y
	dex
	bne .delay_using_X_4_2

	jsr block_22_custom_characters

    ; display "serpentine" in heading
	lda #<data_heading_game_title
	sta text_pointer_low
	lda #>data_heading_game_title
	sta text_pointer_high
	ldx #48
	ldy #0
	jsr update_heading

	jsr draw_maze_and_set_enemy_snake_start_position
	jsr draw_scroll_heading_line
.play_main_theme_tune
    ldx #<data_main_theme_tune_sound_clip
	ldy #>data_main_theme_tune_sound_clip
	jsr prepare_sound_data

	lda #128
	sta sound_loop_counter
.scroll_and_play_main_theme_loop
    jsr scroll_heading_data_lines
	jsr handle_enemy_snake_movement
	jsr read_joystick_to_start_game
	jsr play_sounds
	dec sound_loop_counter
	bne .scroll_and_play_main_theme_loop
	beq .play_main_theme_tune

;-----------------------------------------------------------------------------------

data_eat_frog_egg_enemy_head_sound_clip_extra
    !byte $01, $ca, $01, $cc, $01, $ce, $01, $d0
    !byte $01, $d2, $01, $d4, $01, $d6, $01, $d8
    !byte $01, $da, $01, $de, $01, $e2, $01, $e6
    !byte $01, $eb, $01, $f0, $01, $f5, $01, $fa
    !byte $01, $fc, $01, $fd, $ff

data_eat_frog_egg_enemy_head_sound_clip
	!byte $04
	!byte <data_eat_frog_egg_enemy_head_sound_clip_extra
	!byte >data_eat_frog_egg_enemy_head_sound_clip_extra
	!byte $ff

data_frog_ribbit_sound_clip_extra
	!byte $03, $8c, $01, $8d, $01, $00, $01, $8c
	!byte $01, $8d, $ff

data_frog_ribbit_sound_clip
	!byte $01
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
	!byte $02
	!byte <data_player_dies_sound_clip_extra
	!byte >data_player_dies_sound_clip_extra
	!byte $ff

data_starting_game_on_sound_clip_extra
	!byte $06, $e1, $01, $00, $06, $e8, $01, $00
	!byte $06, $ed, $01, $00, screen_row, $f0, $03, $00
	!byte $06, $ed, $01, $00, $1e, $f0, $ff

data_starting_game_on_sound_clip
	!byte $01
	!byte <data_starting_game_on_sound_clip_extra
	!byte >data_starting_game_on_sound_clip_extra
	!byte $02
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
	!byte $01
	!byte <data_main_theme_tune_sound_clip_extra
	!byte >data_main_theme_tune_sound_clip_extra
	!byte $03
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
	!byte $01
	!byte <data_start_maze_sound_clip_extra
	!byte >data_start_maze_sound_clip_extra
	!byte $02
	!byte <data_start_maze_sound_clip_extra
	!byte >data_start_maze_sound_clip_extra
	!byte $03
	!byte <data_start_maze_sound_clip_extra
	!byte >data_start_maze_sound_clip_extra
	!byte $ff

data_eat_snake_body_1_sound_clip_extra
	!byte $01, $dc, $01, $00, $01, $b4, $ff

data_eat_snake_body_1_sound_clip
	!byte $02
	!byte <data_eat_snake_body_1_sound_clip_extra
	!byte >data_eat_snake_body_1_sound_clip_extra
	!byte $ff

data_eat_snake_body_2_sound_clip_extra
	!byte $01, $b4, $01, $dc, $ff

data_eat_snake_body_2_sound_clip
	!byte $02
	!byte <data_eat_snake_body_2_sound_clip_extra
	!byte >data_eat_snake_body_2_sound_clip_extra
	!byte $ff

;-----------------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------------

prepare_eat_frog_egg_snake_head_sound

    ldx #<data_eat_frog_egg_enemy_head_sound_clip
	ldy #>data_eat_frog_egg_enemy_head_sound_clip
	jmp prepare_sound_data

;-----------------------------------------------------------------------------------

data_snake_hissing_sound_clip_extra
	!byte $28, $fe, $28, $00, $ff

data_snake_hissing_sound_clip
	!byte $04
	!byte <data_snake_hissing_sound_clip_extra
	!byte >data_snake_hissing_sound_clip_extra
	!byte $ff

;-----------------------------------------------------------------------------------

play_snake_hissing_sound

    dec sound_hiss_counter
	bne .skip_snake_hissing_sound
prepare_snake_hissing_sound
    lda #80
	sta sound_hiss_counter
	lda #%00101111  ;aux colour red, volume 15
	sta _VOLUME
	ldx #<data_snake_hissing_sound_clip
	ldy #>data_snake_hissing_sound_clip
	jmp prepare_sound_data

.skip_snake_hissing_sound
    rts

;-----------------------------------------------------------------------------------

handle_player_dies

    jsr clear_all_sound_channels
	ldx #<data_player_dies_sound_clip
	ldy #>data_player_dies_sound_clip
	jsr prepare_sound_data

	ldx #0
	stx $1e
	lda #63
	sta sound_loop_counter
.disintegrate_player_snake_loop
    jsr play_sounds
	lda sound_loop_counter
	lsr
	lsr
	lsr
	jsr dead_snake_animation
	ldx snake_counter
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

;-----------------------------------------------------------------------------------

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
	jsr clear_512_custom_characters
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

;-----------------------------------------------------------------------------------

data_last_post_end_sound_clip_extra
	!byte $19, $9c, $01, $00, screen_row, $9c, $01, $00
	!byte $3c, $b5, $01, $00, $19, $9c, $01, $00
	!byte screen_row, $b5, $01, $00, $3c, $c4, $01, $00
	!byte $19, $b5, $01, $00, screen_row, $c4, $01, $00
	!byte $3c, $ce, $01, $00, $19, $c4, $01, $00
	!byte $19, $b5, $01, $00, $3c, $9c, $01, $00
	!byte $19, $9c, $01, $00, screen_row, $9c, $01, $00
	!byte $3c, $b5, $01, $00, $ff

data_last_post_end_sound_clip
	!byte $03
	!byte <data_last_post_end_sound_clip_extra
	!byte >data_last_post_end_sound_clip_extra
	!byte $ff

;-----------------------------------------------------------------------------------

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
	sta player_egg_status  ;set to zero

    ; set player snake (baby hatched) coordinates from the baby snake egg coordinates
	ldx #2
.apply_egg_coords_loop
    lda $2a,x  ;get $2c (player_egg_location_row), $2b (player_egg_location_column), $2a (direction)
	sta player_and_enemy_table+5,x  ;update $87 (snake head screen row), $86 (snake head screen column), $85 (snake head direction)
	dex
	bpl .apply_egg_coords_loop

	lda player_body_segments
	pha
	lda #1
	sta player_body_segments
	jsr add_segment_to_player_body
	ldy #0
	jsr perform_player_or_enemy_snake_movement
	jsr player_or_baby_snake_goes_home_loop
	pla
	sta player_body_segments
	jmp add_one_to_player_lives

;-----------------------------------------------------------------------------------

player_snake_goes_home

    jsr clear_all_sound_channels
	ldx #<data_player_goes_home_sound_clip
	ldy #>data_player_goes_home_sound_clip
	jsr prepare_sound_data

player_or_baby_snake_goes_home_loop
    lda #166  ;right edge column
    cmp player_body_segments+6  ;snake head column
	beq @LB953
	jsr @LB9C3
	beq @LB927
@LB921
    jsr .goto_perform_player_movement
	jmp player_or_baby_snake_goes_home_loop

@LB927
    jsr @LB9B7
	bcc @LB921
	lda #down
    ldx player_body_segments+7  ;snake head row
    cpx #119  ;outside player snake home door row?
	bcc @LB936
	lda #up
@LB936
    jsr .set_snake_direction
	bcc @LB942
	ldy snake_direction
	lda data_directions-1,y
	bne @LB936
@LB942
    jsr .goto_perform_player_movement
	jsr @LB9C3
	bne @LB942
	jsr @LB9B7
	bcc @LB921
	lda player_body_segments+5 ;snake head direction
	bne @LB936

@LB953
    lda player_body_segments+7  ;snake head row
    cmp #118  ;outside player snake home door row?
	beq .open_door_and_get_into_home
	jsr @LB9C3
	beq @LB964
@LB95E
    jsr .goto_perform_player_movement
	jmp @LB953

@LB964
    lda #down
	jsr .set_snake_direction
	bcc @LB95E
	lda #left
	jsr .set_snake_direction

@LB970
    jsr .goto_perform_player_movement
	jsr @LB9C3
	bne @LB970
	lda #down
	jsr .set_snake_direction
	bcs @LB970

@LB97F
    jsr .goto_perform_player_movement
	jsr @LB9C3
	bne @LB97F

	beq @LB927  ;always branch

.open_door_and_get_into_home
    clc  ;to clear space and open door
	jsr open_or_close_snake_entrance_door   ;door open
	lda #down  ;move snake down into home
	sta player_snake_direction
	lda #255
	sta $83
	jsr .goto_perform_player_movement
	lda #left  ;move snake left into home
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

@LB9B7
    lda #right
.set_snake_direction
    sta player_snake_direction
	sta snake_direction
	jsr @LB9C3
	jmp LA362

@LB9C3
    ldy #7  ;points to player snake head
	jsr get_screen_coordinates_for_sprite_player
	jmp LA2FF

.goto_perform_player_movement
    ldy #0
	jsr perform_player_or_enemy_snake_movement
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

;-----------------------------------------------------------------------------------

play_sound

    lda #%00101111  ;aux colour red, volume 15
	sta _VOLUME
	ldx #255
.play_sound_loop
    ldy #56
.play_sound_delay_loop
    stx _SOUND3
	stx _SOUND2
	dey
	bne .play_sound_delay_loop
	dex
	bne .play_sound_loop
	lda #%00101010  ;aux colour red, volume 10
	sta _VOLUME
	rts

;-----------------------------------------------------------------------------------

set_current_maze_to_next_one

    ldx current_maze
	cpx #99
	bcs .max_maze_number_so_end
	inx
	stx current_maze
.max_maze_number_so_end
    rts

;-----------------------------------------------------------------------------------

player_has_eaten_all_enemy_snakes

    lda #20  ;apart from the delay, 20 iterations appears unnecessary
	sta $1f
.eaten_all_snakes_loop
    jsr play_sounds
	jsr perform_enemy_snake_movement
	jsr more_player_and_enemy_snake_interactions
	lda #0
	sta snake_colour  ;is 0 for player snake, 1 or 2 for enemy
	lda player_body_segments
	sta body_segments  ;points to player or enemy snake number of segments
	lda #7
	jsr plot_entire_snake_on_screen
	ldy #17
	jsr delay_using_Y
	dec $1f
	bne .eaten_all_snakes_loop

	jsr clear_all_sound_channels
	jsr set_current_maze_to_next_one
	jsr player_snake_goes_home

    ;check if player laid an egg
	lda player_egg_status
	cmp #3
	bne .goto_play_one_life
	jsr start_baby_snake_goes_home
.goto_play_one_life
    jmp play_one_life

;-----------------------------------------------------------------------------------

clear_maze_objects

    ; clear all enemy snakes from screen
    ldx #38
.clear_each_enemy_snake_on_screen_loop
    stx $06  ;points to player or enemy snake head
	stx $1e

    ; use each enemy snake segment coordinates and clear each from the screen
	lda enemy_snake_table-7,x  ;number of enemy snake body segments
	sta temp2
.clear_one_enemy_snake_on_screen_loop
    jsr get_screen_coordinates_for_sprite
	jsr clear_block_at_screen_coordinates
	jsr add_3_to_point_to_next_segment
	dec temp2
	bne .clear_one_enemy_snake_on_screen_loop

	lda $1e
	clc
	adc #30  ;offset to next snake data
	tax
	cpx #99
	bcc .clear_each_enemy_snake_on_screen_loop

    ; clear frog
	lda frog_display
	bmi .skip_set_frog_to_clear_on_screen
	jsr plot_frog_sprite_on_screen  ;will clear frog on screen
.skip_set_frog_to_clear_on_screen

    ; clear enemy snake egg
    lda enemy_egg_status
	cmp #3
	bne .clear_maze_objects_end
	lda enemy_egg_location_column
	sta screen_column
	lda enemy_egg_location_row
	sta screen_row
	jmp clear_block_at_screen_coordinates

.clear_maze_objects_end
    rts

;-----------------------------------------------------------------------------------

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
	!byte $02
	!byte <data_player_goes_home_sound_clip_extra
	!byte >data_player_goes_home_sound_clip_extra
	!byte $03
	!byte <data_player_goes_home_sound_clip_extra
	!byte >data_player_goes_home_sound_clip_extra
	!byte $ff

data_baby_snake_sound_clip
	!byte $02
	!byte <data_baby_snake_sound_clip_extra
	!byte >data_baby_snake_sound_clip_extra
	!byte $03
	!byte <data_baby_snake_sound_clip_extra
	!byte >data_baby_snake_sound_clip_extra
	!byte $ff

;-----------------------------------------------------------------------------------
; Junk bytes needed to pad file to 8192 bytes for A000 cartridge format
; These bytes could be replaced with !fill 1309,0 but are kept to allow
; a matching binary comparison with the original program

data_junk_padding_bytes
    !byte $10, $01, $15, $0c, $20, $1a, $15, $1a, $05, $0c, $0f, $c0, $78, $a9, $02, $8d
    !byte $1e, $91, $20, $83, $b4, $20, $9d, $a1, $a9, $00, $85, $00, $a9, $10, $85, $01
    !byte $a2, $10, $a0, $00, $a9, $ff, $91, $00, $c8, $d0, $fb, $e6, $01, $ca, $d0, $f6
    !byte $a0, $f2, $a9, $05, $99, $ff, $95, $88, $d0, $fa, $a2, $00, $bd, $e3, $ba, $18
    !byte $69, $40, $9d, $00, $01, $e8, $e0, $0c, $90, $f2, $a9, $01, $85, $5e, $a9, $00
    !byte $85, $5d, $85, $1f, $aa, $0a, $a8, $20, $38, $a9, $a5, $1f, $18, $69, $04, $85
    !byte $1f, $c9, $55, $90, $ef, $02, $30, $00, $00, $81, $c3, $3c, $24, $24, $3c, $24
    !byte $24, $18, $02, $7c, $58, $1c, $74, $44, $06, $18, $01, $7e, $d8, $18, $38, $28
    !byte $0c, $18, $40, $3e, $1a, $38, $2e, $22, $60, $18, $80, $7e, $1b, $18, $1c, $14
    !byte $30, $98, $40, $7c, $1c, $1c, $18, $18, $3c, $18, $00, $7c, $9c, $1c, $18, $18
    !byte $3c, $00, $07, $0f, $0f, $07, $00, $3f, $7f, $80, $3f, $75, $c9, $ca, $72, $2b
    !byte $1f, $e0, $fe, $ff, $ff, $fe, $fc, $ff, $ff, $00, $ff, $5d, $92, $52, $4c, $aa
    !byte $ff, $00, $0e, $fb, $fb, $0e, $00, $fc, $fe, $01, $fc, $77, $4b, $4a, $34, $a8
    !byte $f0, $00, $00, $01, $01, $00, $00, $3f, $7f, $80, $3f, $75, $c9, $ca, $72, $2b
    !byte $1f, $3c, $ff, $ff, $ff, $ff, $7e, $ff, $ff, $00, $ff, $5d, $92, $52, $4c, $aa
    !byte $ff, $00, $00, $80, $80, $00, $00, $fc, $fe, $01, $fc, $77, $4b, $4a, $34, $a8
    !byte $f0, $00, $70, $df, $df, $70, $00, $3f, $7f, $80, $3f, $75, $c9, $ca, $72, $2b
    !byte $1f, $07, $7f, $ff, $ff, $7f, $3f, $ff, $ff, $00, $ff, $5d, $92, $52, $4c, $aa
    !byte $ff, $00, $e0, $f0, $f0, $e0, $00, $fc, $fe, $01, $fc, $77, $4b, $4a, $34, $a8
    !byte $f0, $07, $1f, $7f, $78, $f0, $e0, $e0, $e0, $f0, $78, $7f, $1f, $07, $00, $00
    !byte $00, $00, $e0, $f0, $78, $00, $00, $00, $00, $00, $78, $f0, $e0, $00, $00, $00
    !byte $00, $00, $00, $00, $c0, $c0, $c0, $c0, $f8, $fc, $cc, $cc, $cc, $cc, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $3c, $7e, $e7, $c3, $e7, $7e, $3c, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $37, $3f, $39, $30, $39, $3f, $3f, $30, $30
    !byte $30, $00, $00, $00, $0e, $06, $06, $06, $86, $c6, $c6, $c6, $86, $0f, $00, $00
    !byte $00, $00, $00, $00, $00, $18, $00, $38, $18, $18, $18, $18, $18, $3c, $00, $00
    !byte $00, $00, $00, $00, $1c, $36, $30, $30, $fc, $30, $30, $30, $30, $30, $00, $00
    !byte $00, $00, $00, $00, $00, $30, $30, $30, $fc, $30, $30, $30, $36, $1c, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $3c, $7e, $e7, $ff, $e0, $7e, $3c, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $37, $3d, $38, $30, $30, $30, $30, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $00, $80, $00, $00, $00, $00, $00, $00, $00
    !byte $00, $07, $18, $20, $47, $4e, $8c, $98, $90, $80, $80, $80, $40, $40, $20, $18
    !byte $07, $e0, $18, $04, $02, $02, $01, $01, $01, $01, $01, $01, $02, $02, $04, $18
    !byte $e0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $7f, $5f, $6f, $77, $58, $4b, $6b, $3b, $1b, $0b
    !byte $07, $1c, $1f, $10, $18, $17, $ef, $ef, $ff, $ff, $00, $ff, $c1, $d5, $d5, $c1
    !byte $ff, $00, $00, $c0, $40, $40, $f0, $f8, $fc, $fe, $01, $ff, $c7, $c7, $ff, $ff
    !byte $ff, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $01, $42, $3c, $3e, $7e, $3e, $1c, $24, $04, $00, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $81, $42, $3c, $3e, $ff, $7f, $3e, $24, $44, $04, $00, $00
    !byte $00, $00, $00, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    !byte $00, $00, $02, $01, $00, $00, $00, $00, $07, $00, $00, $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $81, $42, $3c, $3e, $ff, $7f, $3f, $18, $44, $84, $06, $00
    !byte $00, $00, $40, $80, $00, $00, $00, $80, $e0, $00, $00, $00, $00, $00, $00, $00
    !byte $00, $08, $06, $01, $00, $00, $00, $00, $07, $18, $01, $00, $00, $00, $01, $00
    !byte $00, $00, $00, $00, $89, $48, $3c, $32, $eb, $6f, $7f, $1c, $00, $84, $04, $02
    !byte $00, $00, $20, $40, $00, $00, $40, $00, $f0, $00, $00, $80, $00, $00, $00, $00
    !byte $00, $10, $0c, $02, $00, $00, $00, $00, $0e, $30, $40, $06, $00, $00, $03, $00
    !byte $00, $00, $00, $08, $88, $00, $3c, $32, $e1, $6d, $6f, $3e, $1c, $80, $02, $01
    !byte $00, $18, $20, $00, $00, $20, $40, $00, $f8, $04, $00, $10, $40, $00, $00, $00
    !byte $00, $10, $08, $00, $00, $00, $00, $00, $18, $40, $80, $04, $08, $00, $06, $00
    !byte $00, $00, $08, $00, $00, $00, $14, $32, $e1, $0d, $2b, $2c, $1c, $00, $00, $00
    !byte $01, $08, $00, $00, $10, $20, $00, $00, $3c, $00, $00, $08, $00, $20, $00, $00
    !byte $00, $30, $18, $04, $03, $06, $00, $00, $00, $00, $00, $00, $04, $fe, $38, $00
    !byte $00, $00, $00, $20, $30, $fe, $18, $06, $00, $00, $44, $38, $08, $04, $0c, $00
    !byte $00, $1f, $1f, $3f, $3f, $7f, $7f, $ff, $ff, $f8, $f8, $fc, $fc, $fe, $fe, $ff
    !byte $ff, $a9, $00, $85, $06, $20, $ee, $ab, $20, $21, $af, $a9, $00, $85, $09, $85
    !byte $14, $85, $0d, $85, $0f, $a9, $50, $85, $2a, $a9, $75, $85, $2b, $20, $68, $bf
    !byte $a9, $04, $85, $29, $a9, $80, $85, $68, $a9, $7d, $85, $5b, $a9, $be, $85, $67
    !byte $85, $5a, $a9, $7c, $85, $11, $85, $12, $85, $13, $a9, $80, $85, $15, $a9, $ff
    !byte $85, $16, $a9, $7e, $85, $0c, $a2, $03, $a9, $7e, $95, $63, $bd, $05, $b5, $95
    !byte $5f, $ca, $10, $f4, $a9, $7f, $85, $63, $a9, $00, $85, $34, $85, $69, $85, $31
    !byte $a2, $09, $95, $b8, $ca, $10, $fb, $a2, $0f, $a9, $7e, $95, $7a, $ca, $10, $f9
    !byte $a9, $00, $a2, $06, $95, $17, $ca, $10, $fb, $a2, $09, $95, $c2, $ca, $10, $fb
    !byte $a2, $0f, $20, $56, $b3, $c9, $7d, $b0, $f9, $c9, $10, $90, $f5, $95, $4a, $20
    !byte $56, $b3, $95, $3a, $ca, $10, $eb, $a9, $01, $85, $06, $20, $ee, $ab, $20, $28
    !byte $a5, $20, $b0, $a6, $20, $93, $a2, $20, $e6, $a1, $20, $47, $aa, $20, $94, $a7
    !byte $20, $3e, $a8, $20, $99, $ab, $20, $a4, $ac, $20, $a7, $ad, $20, $19, $ae, $20
    !byte $cb, $a3, $20, $d7, $a2, $20, $a4, $aa, $20, $29, $ac, $20, $e2, $a8, $20, $80
    !byte $a8, $20, $82, $a3, $20, $d5, $a4, $20, $5c, $b0, $20, $3d, $b0, $20, $72, $bf
    !byte $e6, $28, $4c, $21, $bf, $a9, $00, $85, $37, $85, $33, $85, $5c, $60, $02, $ad
    !byte $71, $6f, $a0, $00, $99, $21, $6f, $60, $4f, $50, $50, $45, $61, $c1, $53, $30
    !byte $31, $2c, $20, $46, $49, $4c, $45, $53, $20, $53, $43, $52, $41, $54, $43, $48
    !byte $45, $44, $2c, $30, $31, $2c, $30, $30, $00, $43, $53, $45, $52, $50, $45, $4e
    !byte $54, $49, $4e, $45, $20, $24, $36, $0d, $00, $43, $33, $50, $62, $6d, $43, $4c
    !byte $45, $41, $52, $20, $62, $73, $57, $48, $41, $20, $20, $20, $62, $7b, $43, $4c
    !byte $45, $41, $50, $20, $62, $7f, $50, $4c, $4f, $54, $43, $48, $62, $8e, $50, $42
    !byte $50, $20, $20, $20, $62, $99, $53, $48, $49, $46, $50, $20, $62, $a3, $44, $53
    !byte $48, $49, $46, $54, $62, $a9, $4c, $45, $53, $48, $49, $46, $62, $c8, $50, $42
    !byte $50, $4c, $20, $20, $62, $ca, $53, $48, $49, $46, $20, $20, $00

;-----------------------------------------------------------------------------------
end_of_program
