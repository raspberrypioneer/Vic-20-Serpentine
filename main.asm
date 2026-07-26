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
; zero page addresses

maze_address_low = $15
maze_address_high = $16
player_lives = $18
current_maze = $19
frog_display = $40
scroll_heading_position = $46
scroll_heading_delay = $47
sound_loop_counter = $48
end_loop_counter = $49
sound_hiss_counter = $53
player_score = $54  ;3 bytes $54, $55, $56
high_score = $57  ;3 bytes $57, $58, $59
text_pointer_low = $5d
text_pointer_high = $5e

;-----------------------------------------------------------------------------------
; start program, game was originally a cartridge so no basic loader
* = $a000
    ;auto start the program
	!byte <start_of_program  ;Cold start vector (low)
	!byte >start_of_program  ;Cold start vector (high)
	!byte <start_of_program  ;Warm / reset start vector (low)
	!byte >start_of_program  ;Warm / reset start vector (high)
    !pet "a0CBM"  ;start of signature a0CBM

data_zero_page_80_99
    !byte $03  ;$80
	!byte $00
	!byte $00
	!byte $80
	!byte $80
	!byte $01
	!byte $a6
	!byte $86
	!byte $01
	!byte $a6
	!byte $8e
	!byte $01
	!byte $a6
	!byte $96
	!byte $01
	!byte $a6  ;$8f
	!byte $9e  ;$90
	!byte $03
	!byte $a6
	!byte $a6
	!byte $03
	!byte $9e
	!byte $a6
    !byte $aa
    !byte $aa
    !byte $aa  ;$99
	!fill 4,$aa
data_zero_page_9e_f7
    !byte $3c  ;$9e, $bc, $da
	!byte $06
	!byte $01
	!byte $00
	!byte $80
	!byte $80
	!byte $01
	!byte $06
	!byte $76
	!byte $01
	!byte $06
	!byte $7e
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
	lda #2  ;Disable restore key interrupt
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
	stx $80
	dex
	stx $5a
	jsr clear_player_score
	lda #1
	sta current_maze

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
	jsr LACEA  ;TODO: update score
	jsr clear_frog_on_screen
	jsr LA8F6  ;TODO: unknown effect
	jsr set_enemy_snake_start_position
	jsr play_about_to_start_maze_tune
.game_play_loop
	jsr handle_player_movement
	jsr handle_enemy_snake_movement
	jsr handle_player_and_enemy_snake_interactions
	jsr LB06F  ;TODO: unknown effect
	jsr more_player_and_enemy_snake_interactions
	jsr plot_frog_on_screen
	jsr play_sounds
	jsr play_snake_hissing_sound
	jsr get_joystick_movement
	dec $1f
	bne .game_play_loop
	ldx $1c
	inx
	cpx #11
	bcs @LA0CC
	stx $1c
@LA0CC
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
	sta $0080,y
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
	sta $1d
	sta $1c

	ldx #29
	jsr .init_zero_page_group_of_30
	ldx #59
	jsr .init_zero_page_group_of_30

	ldx #89
.init_zero_page_group_of_30
	ldy #29
.init_zero_page_30_loop
	lda data_zero_page_9e_f7,y
	sta $9e,x
	dex
	dey
	bpl .init_zero_page_30_loop

	ldx #5
	lda #0
.clear_zero_page_2e_33
	sta $2e,x
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

get_joystick_movement
	jsr read_joystick
	bcs .no_joystick_action
	cmp #JOY_FIRE
	bne .joy_movement_in_X

    ;pause game when fire is pressed
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
	stx $82  ;X is the direction: 1 up, 2 down, 3 right, 4 left
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

    ;get a single joystick direction / fire from priority table (in case more than one at the same time e.g. up-left)
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

    ;set main game screen colour
	lda #13  ;colour green
.set_screen_base_colour_loop
	sta _COLOUR_SCREEN_ADDR-1,y
	dey
	cpy #22
	bne .set_screen_base_colour_loop

    ;set top 2 title line colour
	lda #6  ;colour blue
.set_top_base_colour_loop
	sta _COLOUR_SCREEN_ADDR-1,y
	dey
	bne .set_top_base_colour_loop
	rts

;-----------------------------------------------------------------------------------

initialise_0200_onwards_with_increments_of_11

    ;set $0200 to $02f2 with 0, 11, 22, 33, 44 etc to 242
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
	cmp #11
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
    ;increments each byte by 176 (each character is 8 bits in a row of 22 characters)
	!byte $00, $b0, $60, $10, $c0, $70, $20, $d0
	!byte $80, $30, $e0, $90, $40, $f0, $a0, $50
	!byte $00, $b0, $60, $10, $c0, $70
data_screen_bitmap_address_high
    !byte $10, $10, $11, $12, $12, $13, $14, $14
	!byte $15, $16, $16, $17, $18, $18, $19, $1a
	!byte $1b, $1b, $1c, $1d, $1d, $1e

LA21C
	lda $0e
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
	adc $0f
	sta $00
	bcc @LA239
	inc $01
@LA239
	rts

;-----------------------------------------------------------------------------------

LA23A
	jsr LA21C
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

LA266
	jsr LA21C
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

LA297
	ldy $06
LA299
	ldx #2
@LA29B
	lda $0080,y
	sta $0d,x
	dey
	dex
	bpl @LA29B
	rts

LA2A5
	ldy $06
	ldx #2
@LA2A9
	lda $0d,x
	sta $0080,y
	dey
	dex
	bpl @LA2A9
	rts

DATA_LA2B2
	!byte $00, $00, $02, $fe
DATA_LA2B6
	!byte $fe, $02, $00, $00

LA2BB
	ldx $0d
	bne LA2C4
	ldx $0e
	ldy $0f
	rts

LA2C4
	lda $0f
	clc
	adc DATA_LA2B6-1,x
	tay
	lda $0e
	clc
	adc DATA_LA2B2-1,x
	tax
	lda #128
	sta $04
	cpx #6
	bcs @LA2DE
	asl $04
	ldx $0e
@LA2DE
	cpx #167
	bcc @LA2E6
	asl $04
	ldx $0e
@LA2E6
	cpy #22
	bcs @LA2EE
	asl $04
	ldy $0f
@LA2EE
	cpy #167
	bcc @LA2F6
	asl $04
	ldy $0f
@LA2F6
	rts

LA2F7
	jsr LA2BB
	stx $0e
	sty $0f
	rts

LA2FF
	lda #128
	sta $13
	ldx #1
@LA305
	lda $0e,x
	sec
	sbc #6
	and #15
	bne @LA313
	dex
	bpl @LA305
	asl $13
@LA313
	rts

LA314
	ldx #2
@LA316
	lda $0d,x
	sec
	sbc #6
	and #7
	bne LA322
	dex
	bne @LA316
LA322
	rts

DATA_LA322
	!byte 0, 11, 1, 0

LA327
	bit $13
	bpl LA32D
LA32B
	clc
	rts

LA32D
    ldx $0d
LA32F
    stx $14
	jsr LA2C4
	bit $04
	bmi @LA33A
@LA338
    sec
	rts

@LA33A
    jsr LA8B3
	ldx $14
	clc
	adc DATA_LA322-1,x
	sta $17
	jsr LA8D6
	beq LA32B
	cmp #3
	beq @LA338
	cmp #1
	bne @LA35A
	lda $14
	cmp #3
	bcs LA32B
	bcc @LA338

@LA35A
	lda $14
	cmp #3
	bcs @LA338
	bcc LA32B

LA362
    ldx $09
	bit $13
	bpl LA32F
	jsr LA314
	bne @LA382
	ldx $09
	lda $0d
	cmp DATA_UNKNOWN_7-1,x
	bne @LA382
	lda $0e
	cmp #166
	bne LA32B
	lda $0f
	cmp #126
	bne LA32B
@LA382
    sec
	rts

LA384
    jsr LA297
	jsr LA972
	jsr LA3CE
LA38D
    lda $0c
	beq @LA397
	ldy $0d
	sta $0d
	sty $0c
@LA397
    jsr LA2F7
	jsr LA23A
	jsr LA2A5
LA3A0
    lda $06
	clc
	adc #3
	sta $06
	rts

DATA_LA3A8
    !byte <DATA_UNKNOWN_G
	!byte <DATA_UNKNOWN_G1
	!byte <DATA_UNKNOWN_G2
DATA_LA3AB
    !byte >DATA_UNKNOWN_G
	!byte >DATA_UNKNOWN_G1
    !byte >DATA_UNKNOWN_G2

DATA_LA3AD
	!byte <DATA_UNKNOWN_G3
	!byte <DATA_UNKNOWN_G4
	!byte <DATA_UNKNOWN_G5
	!byte <DATA_UNKNOWN_G6
	!byte <DATA_UNKNOWN_G7
	!byte <DATA_UNKNOWN_G8
	!byte <DATA_UNKNOWN_G9
	!byte <DATA_UNKNOWN_G10
	!byte <DATA_UNKNOWN_G11
	!byte <DATA_UNKNOWN_G12
	!byte <DATA_UNKNOWN_G13
    !byte <DATA_UNKNOWN_G14

DATA_LA3B9
	!fill 7, >DATA_UNKNOWN_G
	!fill 5, 1+>DATA_UNKNOWN_G

DATA_LA3C5
	!byte 3, 3, 1, 1
DATA_LA3C9
	!byte 4, 4, 2, 2

LA3CE
    ldx $08
	lda DATA_LA3A8,x
	sta $10
	lda DATA_LA3AB,x
	sta $11
	rts

LA3DB
    lda $08
	asl
	asl
	adc $0d
	tax
	lda DATA_LA3AD-1,x
	sta $10
	lda DATA_LA3B9-1,x
	sta $11
	rts

handle_player_movement
    ldy #0
	dec $1b
	bne LA3F8
	lda $1a
	sta $1b
	rts

LA3F8
    sty $06
	sty $05
	ldx #0
	stx $0c
@LA400
    lda $0080,y
	sta $07,x
	iny
	inx
	cpx #5
	bcc @LA400
	iny
	iny
	sty $06
	jsr LA297
	jsr LA2FF
	jsr LABBA
	jsr LA314
	bne @LA421
	lda $0d
	sta $0c
@LA421
    lda $09
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
	sta $83,x
	cpy #128
	beq @LA46D
	bne @LA463

@LA43F
    lda $08
	bne @LA446
	jmp LA921

@LA446
    lsr $9114
	bcs @LA457
@LA44B
    ldy $0d
	lda DATA_LA3C5-1,y
	sta $09
	jsr LA362
	bcc @LA463
@LA457
    ldy $0d
	lda DATA_LA3C9-1,y
	sta $09
	jsr LA362
	bcs @LA44B
@LA463
    lda $09
	sta $0c
	ldx $05
	lda #0
	sta $82,x
@LA46D
    jsr LA972
	jsr LA3DB
	jsr LA38D
	dec $07
@LA478
    jsr LA384
	dec $07
	bne @LA478
	ldx $05
	lda #8
	sec
	sbc $80,x
	tay
	jsr delay_using_Y
	bit $0b
	bpl @LA4B5
	lda $08
	bne @LA49E
	ldy $0f
	cpy #118
	bne @LA4B5
	jsr @LA4AE
	jmp LA904

@LA49E
    ldy $0f
	cpy #102
	bne @LA4B5
	jsr @LA4AE
	ldx #6
	ldy #112
	jmp LA908

@LA4AE
    lda #0
	ldx $05
	sta $84,x
	sec
@LA4B5
    rts

;-----------------------------------------------------------------------------------

DATA_UNKNOWN_G
	!byte $14, $14, $55, $7d, $7d, $55, $14, $14
DATA_UNKNOWN_G1
	!byte $3c, $3c, $ff, $d7, $d7, $ff, $3c, $3c
DATA_UNKNOWN_G2
	!byte $28, $28, $aa, $96, $96, $aa, $28, $28
DATA_UNKNOWN_G3
	!byte $14, $14, $96, $96, $55, $55, $ff, $ff
DATA_UNKNOWN_G4
	!byte $ff, $ff, $55, $55, $96, $96, $14, $14
DATA_UNKNOWN_G5
	!byte $d8, $d8, $d5, $d5, $d5, $d5, $d8, $d8
DATA_UNKNOWN_G6
	!byte $27, $27, $57, $57, $57, $57, $27, $27
DATA_UNKNOWN_G7
	!byte $3c, $3c, $be, $be, $ff, $ff, $55, $55
DATA_UNKNOWN_G8
	!byte $55, $55, $ff, $ff, $be, $be, $3c, $3c
DATA_UNKNOWN_G9
	!byte $78, $78, $7f, $7f, $7f, $7f, $78, $78
DATA_UNKNOWN_G10
	!byte $2d, $2d, $fd, $fd, $fd, $fd, $2d, $2d
DATA_UNKNOWN_G11
	!byte $28, $28, $eb, $eb, $aa, $aa, $55, $55
DATA_UNKNOWN_G12
	!byte $55, $55, $aa, $aa, $eb, $eb, $28, $28
DATA_UNKNOWN_G13
	!byte $bc, $bc, $ba, $ba, $ba, $ba, $bc, $bc
DATA_UNKNOWN_G14
	!byte $39, $39, $a9, $a9, $a9, $a9, $39, $39

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
	cpx #21
	bcc .set_maze_build_from_address

    ;current maze number can exceed the 20 defined maze maps,
    ;so subtract 10 from current maze number to get one of the 20 maze maps
	txa
.decide_maze_to_use
    sbc #10
	cmp #21
	bcs .decide_maze_to_use
	tax
.set_maze_build_from_address
    lda data_maze_addresses_low-1,x
	sta maze_address_low
	lda data_maze_addresses_high-1,x
	sta maze_address_high
	lda #0
	sta $17
@LA7B4
    jsr LA899
	jsr LA8D6
	tax
	cpx #3
	bcc @LA7C8
	dex
	jsr LA868
	jsr LA899
	ldx #1
@LA7C8
    jsr LA868
	inc $17
	lda $17
	cmp #110
	bcc @LA7B4
	lda #10
	sta $17
	lda #<DATA_A83E
	sta $10
	lda #>DATA_A83E
	sta $11
@LA7DF
    jsr LA899
	jsr LA266
	dec $17
	bpl @LA7DF
	lda #10
	sta $17
	lda #<DATA_A846
	sta $10
	lda #>DATA_A846
	sta $11
@LA7F5
    jsr LA899
	jsr LA23A
	dec $17
	bpl @LA7F5
	lda #99
	sta $17
	lda #<DATA_A84E
	sta $10
	lda #>DATA_A84E
	sta $11
@LA80B
    jsr LA899
	jsr LA266
	lda $17
	sec
	sbc #11
	sta $17
	bne @LA80B
	lda #<DATA_A856
	sta $10
	lda #>DATA_A856
	sta $11
	lda #99
	sta $17
@LA826
    jsr LA899
	jsr LA23A
	lda $17
	sec
	sbc #11
	sta $17
	bne @LA826
	rts

;-----------------------------------------------------------------------------------

DATA_A836
	!byte $a0
	!byte $a0
	!byte $a0
	!byte $a0
	!byte $00
	!byte $00
	!byte $00
	!byte $00
DATA_A83E
	!byte $a5
	!byte $a5
	!byte $a5
	!byte $a5
	!byte $00
	!byte $00
	!byte $00
	!byte $00
DATA_A846
	!byte $55
	!byte $55
	!byte $55
	!byte $55
	!byte $00
	!byte $00
	!byte $00
	!byte $00
DATA_A84E
	!byte $a0
	!byte $a0
	!byte $a0
	!byte $a0
	!byte $50
	!byte $50
	!byte $50
	!byte $50
DATA_A856
	!byte $50
	!byte $50
	!byte $50
	!byte $50
	!byte $50
	!byte $50
	!byte $50
	!byte $50
DATA_LA85E
    !byte <DATA_A836
	!byte <DATA_A83E
	!byte <DATA_A84E
DATA_LA861
    !byte >DATA_A836
	!byte >DATA_A83E
DATA_LA863
    !byte >DATA_A84E
	!byte $08
DATA_LA865
    !byte $00
	!byte $00
	!byte $08

;-----------------------------------------------------------------------------------

LA868
    stx $0d
	lda DATA_LA85E,x
	sta $10
	lda DATA_LA861,x
	sta $11
	jsr LA23A
	ldx $0d
	beq @LA898
	lda $0e
	clc
	adc DATA_LA863,x
	sta $0e
	lda $0f
	adc DATA_LA865,x
	sta $0f
	lda $10
	clc
	adc #8
	sta $10
	bcc @LA895
	inc $11
@LA895
    jmp LA23A

@LA898
    rts

LA899
    lda $17
	ldx #0
	sec
@LA89E
    inx
	sbc #11
	bcs @LA89E
	adc #11
	asl
	asl
	asl
	asl
	sta $0e
	txa
	asl
	asl
	asl
	asl
	sta $0f
	rts

LA8B3
    lda $0f
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
	lda $0e
	lsr
	lsr
	lsr
	lsr
	clc
	adc $17
	sta $17
	rts

LA8D6
    lda $17
	and #3
	tax
	lda $17
	lsr
	lsr
	tay
	lda (maze_address_low),y
@LA8E2
    cpx #3
	bcs @LA8EB
	lsr
	lsr
	inx
	bne @LA8E2
@LA8EB
    and #3
	rts

;-----------------------------------------------------------------------------------

DATA_UNKNOWN_4
	!byte $55, $55, $55, $55, $00, $00, $00, $00

;-----------------------------------------------------------------------------------

LA8F6
	lda #0
	sta $08
	lda $80
	sta $07
	lda #7
	jsr LA91C
	clc
LA904
    ldx #166
	ldy #128
LA908
    stx $0e
	sty $0f
	lda #<DATA_UNKNOWN_4
	sta $10
	lda #>DATA_UNKNOWN_4
	sta $11
	bcs @LA919
	jmp LA266

@LA919
    jmp LA23A

LA91C
    sta $06
	jsr LA297
LA921
    jsr LA3DB
	jmp @LA92D

@LA927
    jsr LA297
	jsr LA3CE
@LA92D
    jsr LA23A
	jsr LA3A0
	dec $07
	bne @LA927
	rts

update_heading
    stx $0e
	sty $0f
	ldy #0
	sty $5c
@LA940
    jsr set_screen_coordinates
	lda #0
	sta $11
	ldy $5c
	lda (text_pointer_low),y
	beq @LA966
	sec
	sbc #64
	ldy #3
@LA952
    asl
	rol $11
	dey
	bne @LA952
	sta $10
	lda #128
	clc
	adc $11
	jsr LA986
	inc $5c
	bne @LA940
@LA966
    rts

set_screen_coordinates
    lda #0
	sta $10
	lda #133
	sta $11
	jmp LA23A

LA972
    lda #0
	sta $10
	lda #133
	sta $11
	jmp LA266

plot_A_on_screen
    asl
	asl
	asl
	ora #128
	sta $10
	lda #129
LA986
    sta $11
	jsr LA266
	lda $0e
	clc
	adc #8
	sta $0e
	rts

;-----------------------------------------------------------------------------------

data_score_heading
	!pet "score"
	!fill 8,$60
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
	sta $0e
	lda #8
	sta $0f
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

update_player_score_large_amount
    sed
	clc
	adc player_score+2
	sta player_score+2
	bcc .clear_decimal_and_end
	lda #0
update_player_score
    sed
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
    cld
	rts

;-----------------------------------------------------------------------------------

plot_player_score_on_screen
    ldx #0
	lda #0
	ldy #48
plot_score_on_screen
    sty $0e
	sta $0f
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
	jsr set_screen_coordinates
	pla
	jsr plot_A_on_screen
@LAA64
    jsr set_screen_coordinates
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
	sta $0e
	lda #8
	sta $0f
	jsr set_screen_coordinates
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
	cmp #255
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
	cmp #255
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
	cmp #255
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

clear_all_sound_channels
    ;clear sounds on each channel
    lda #%00101010  ;aux colour red, volume 10
	sta _VOLUME
	ldx #<data_clear_all_sound_channels
	ldy #>data_clear_all_sound_channels
	jsr prepare_sound_data
	jmp play_sounds

;-----------------------------------------------------------------------------------

set_enemy_snake_start_position
    lda current_maze
	cmp #1
	bne @LAB42
	lda #5
	sta $9f
	sta $bd
	sta $db
@LAB42
    lda #0
	sta $9e
	lda #120
	sta $da

	ldx #31
LAB4C
    lda $80,x
	sta $07
	lda #1
	sta $08
	txa
	clc
	adc #7
	jsr LA91C
	ldx #6
	ldy #112
	clc
    jmp LA908

;-----------------------------------------------------------------------------------

DATA_UNKNOWN_7
	!byte 2, 1, 4, 3
DATA_UNKNOWN_7A
	!byte $32, $50, $6e, $8c, $aa, $be, $d2, $e1
	!byte $f0, $fa

;-----------------------------------------------------------------------------------

handle_enemy_snake_movement
    dec $1d
	bne LAB7A
	lda $1c
	sta $1d
	rts

LAB7A
    lda #0
	sta $51
	ldx #31
@LAB80
    stx $1e
	ldy $51
	lda $002e,y
	bpl @LAB93
	cmp #128
	beq @LAB9D
	jsr LACB7
	jmp @LABAD

@LAB93
    ldy $7f,x
	beq @LABA8
	dey
	tya
	sta $7f,x
	beq @LABA5
@LAB9D
    ldy #7
	jsr delay_using_Y
	jmp @LABAD

@LABA5
    jsr LAB4C
@LABA8
    ldy $1e
	jsr LA3F8
@LABAD
    inc $51
	lda $1e
	clc
	adc #30
	tax
	cpx #92
	bcc @LAB80
	rts

LABBA
    ldx $08
	bne @LABBF
@LABBE
    rts

@LABBF
    bit $13
	bmi @LABBE
	jsr LAC3E
	cmp #128
	bcc @LABBE
	jsr LAC3E
	ldy current_maze
	cpy #11
	bcc @LABD5
	ldy #10
@LABD5
    cmp DATA_UNKNOWN_7A-1,y
	bcc @LABED
@LABDA
    jsr LAC3E
	and #3
	clc
	adc #1
	ldy $0d
	cmp DATA_UNKNOWN_7-1,y
	bne @LABEA
	tya
@LABEA
    sta $09
	rts

@LABED
    lda $0d
	cpx #2
	beq @LAC20
	bit $77
	bpl @LAC0B
@LABF7
    ldx #1
	ldy $0f
	cpy $87
	beq @LAC0B
	bcs @LAC03
	ldx #2
@LAC03
    cmp DATA_UNKNOWN_7-1,x
	beq @LAC0A
	stx $09
@LAC0A
    rts

@LAC0B
    ldx #4
	ldy $0e
	cpy $86
	beq @LAC19
	bcs @LAC03
	ldx #3
	bne @LAC03

@LAC19
    ldy $0f
	cpy $87
	bne @LABF7
@LAC1F
    rts

@LAC20
    ldx #3
	ldy $2b
	beq @LABDA
	cpy $0e
	beq @LAC30
	bcs @LAC03
	ldx #4
	bne @LAC03

@LAC30
    ldx #2
	ldy $2c
	cpy $0f
	beq @LAC1F
	bcs @LAC03
	ldx #1
	bne @LAC03

LAC3E
    stx $7c
	lda $77
	sec
	adc $7a
	adc $7b
	sta $77
	ldx #3
@LAC4B
    lda $77,x
	sta $78,x
	dex
	bpl @LAC4B
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
@LAC6C
    ldy $2e,x
	beq @LAC77
	cpy #128
	beq @LAC77
	dey
	sty $2e,x
@LAC77
    dex
	bpl @LAC6C
	rts

;-----------------------------------------------------------------------------------

DATA_AC7B
	!byte $00
	!byte $00
	!byte $00
	!byte $30
	!byte $30
	!byte $00
	!byte $00
    !byte $00
DATA_AC83
	!byte $00
	!byte $00
	!byte $28
	!byte $3c
	!byte $3c
	!byte $28
	!byte $28
	!byte $00
DATA_AC8B
	!byte $00
	!byte $28
	!byte $28
	!byte $3c
	!byte $3c
	!byte $28
	!byte $28
	!byte $00
DATA_AC93
	!byte $00
	!byte $00
	!byte $00
	!byte $10
	!byte $10
	!byte $00
	!byte $00
	!byte $00
DATA_AC9B
	!byte $00
	!byte $00
	!byte $14
	!byte $3c
	!byte $3c
	!byte $14
	!byte $00
	!byte $00
DATA_ACA3
	!byte $00
	!byte $14
	!byte $14
	!byte $3c
	!byte $3c
	!byte $14
    !byte $14
	!byte $00
DATA_LACAB
	!byte <DATA_AC7B
	!byte <DATA_AC83
	!byte <DATA_AC8B
	!byte <DATA_AC93
    !byte <DATA_AC9B
	!byte <DATA_ACA3
DATA_LACB1
	!byte >DATA_AC7B
	!byte >DATA_AC83
	!byte >DATA_AC8B
	!byte >DATA_AC93
	!byte >DATA_AC9B
	!byte >DATA_ACA3

;-----------------------------------------------------------------------------------

LACB7
    ldx $1e
	sta $52
	lda $80,x
	sta $07
	txa
	clc
	adc #7
	sta $06
@LACC5
    jsr LA297
	jsr LA972
	lda $52
	and #7
	lsr
	cmp #2
	bcc @LACE2
	tax
	lda DATA_LACAB-2,x
	sta $10
	lda DATA_LACB1-2,x
	sta $11
	jsr LA23A
@LACE2
    jsr LA3A0
	dec $07
	bne @LACC5
	rts

LACEA
    lda current_maze
	cmp #21
	bcc @LACF2
	lda #20
@LACF2
    pha
	lsr
	tax
	tay
	lda #0
	sed
	clc
@LACFA
    adc #2
	dex
	bpl @LACFA
	sta $4a
	clc
	lda #0
@LAD04
    adc #1
	dey
	bpl @LAD04
	sta $4b
	pla
	tax
	lda #0
	sta $4d
	sta $4c
@LAD13
    clc
	lda #80
	adc $4c
	sta $4c
	lda #1
	adc $4d
	sta $4d
	dex
	bpl @LAD13
	cld
	rts

LAD25
    ldx #5
LAD27
    lda $7b,x
	cmp #6
	bcs @LAD58
	asl
	adc $7b,x
	inc $7b,x
	stx $50
	adc $50
	sta $50
	tax
	lda #0
	sta $80,x
	lda $7e,x
	sta $0e
	lda $7f,x
	sta $0f
	jsr LA314
	bne @LAD59
	ldx $50
	lda #0
	sta $7d,x
	lda $0f
	sta $82,x
	lda $0e
	sta $81,x
@LAD58
    rts

@LAD59
    ldx $50
	ldy $7d,x
	jsr @LAD73
	cpy #4
	jsr @LAD6B
	inx
	jsr @LAD73
	cpy #1
@LAD6B
    bne @LAD70
	clc
	adc #8
@LAD70
    sta $81,x
	rts

@LAD73
    lda $7e,x
	sec
	sbc #6
	and #248
	clc
	adc #6
	rts

LAD7E
    ldx $1e
LAD80
    jsr LB243
	jsr LA972
	ldx $50
	dec $80,x
	lda $80,x
	cmp #2
	bcs @LAD9C
	lda $86,x
	sta $0e
	lda $87,x
	sta $0f
	jsr LA972
	clc
@LAD9C
    rts

LAD9D
    ldy #2
	ldx $1e
@LADA1
    lda $0085,y
	sec
	sbc $87,x
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

handle_player_and_enemy_snake_interactions
    ldx #11
	lda #0
@LADBB
    sta $34,x
	dex
	bpl @LADBB
	sta $7c
	ldx #31
	txa
@LADC5
    sta $05
	stx $1e
	lda $7f,x
	bne @LAE26
	lda $80,x
	sta $07
	ldx $1e
	ldy #2
@LADD5
    lda $0085,y
	sec
	sbc $87,x
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
	lda $2e,x
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
	adc #30
	tax
	cmp #92
	bcc @LADC5
@LAE26
    lda #0
	sta $7c
	ldx #31
@LAE2C
    stx $1e
	lda $7f,x
	bne @LAE7F
	ldx $7c
	lda $3d,x
	bne @LAE73
	lda $31,x
	bne @LAE73
	ldx $80
	dex
	stx $07
	ldx #9
@LAE43
    stx $06
	ldy $1e
	lda #2
	sta $51
@LAE4B
    lda $0086,y
	sec
	sbc $80,x
	bcs @LAE57
	eor #255
	adc #1
@LAE57
    cmp #5
	bcs @LAE69
	inx
	iny
	dec $51
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
	adc #30
	tax
	cmp #92
	bcc @LAE2C
@LAE7F
    lda #0
	sta $4e
	ldy #31
@LAE85
    sty $1e
	ldx $4e
	lda $2e,x
	bne @LAEB7
	lda $34,x
	beq @LAEC6
	lda $0080,y
	cmp $80
	bcc @LAE9B
	jmp handle_player_dies

@LAE9B
    ldy #137
	sty $2e,x
	sta $4f
@LAEA1
    lda $4a
	clc
	jsr update_player_score
	dec $4f
	bne @LAEA1
	jsr plot_player_score_on_screen
	jsr LAD25
	jsr LB05E
	jsr LB7B1
@LAEB7
    inc $4e
	lda $1e
	clc
	adc #30
	tay
	cmp #92
	bcc @LAE85
	jmp @LAF13

@LAEC6
    lda $37,x
	beq @LAEEC
	lda #3
	sta $2e,x
	lda $4b
	clc
	jsr update_player_score
	jsr plot_player_score_on_screen
	jsr LB05E
	ldx #<data_sound_clip_8
	ldy #>data_sound_clip_8
	jsr prepare_sound_data
	jsr LAD7E
	ldx $4e
	bcs @LAEEC
	lda #128
	sta $2e,x
@LAEEC
    lda $31,x
	bne @LAEB7
	lda $3a,x
	beq @LAEB7
	lda #5
	sta $31,x
	ldx #<data_sound_clip_9
	ldy #>data_sound_clip_9
	jsr prepare_sound_data
	ldx #0
	lda $2d
	cmp #2
	bne @LAF0B
	stx $2d
	stx $2b
@LAF0B
    jsr LAD80
	bcs @LAEB7
	jmp handle_player_dies

@LAF13
    ldx #31
@LAF15
    lda $80,x
	cmp $80
	bcc @LAF1E
	lda #1
	!byte $2c
@LAF1E
    lda #2
	sta $81,x
	txa
	clc
	adc #30
	tax
	cmp #92
	bcc @LAF15
	ldx #2
@LAF2D
    lda $2e,x
	bpl @LAF37
	dex
	bpl @LAF2D
	jmp LBA09

@LAF37
    rts

;-----------------------------------------------------------------------------------

DATA_NO_LABEL_9
	!byte $1a
	!byte $af
	!byte $20
	!byte $62
	!byte $b3
	!byte $20
	!byte $e4
	!byte $b3
	!byte $e8
	!byte $e0
	!byte $07
	!byte $d0
	!byte $f2
	!byte $a9
	!byte $40
	!byte $85
	!byte $1e
	!byte $a9
	!byte $50
	!byte $85
	!byte $1f
	!byte $a5
	!byte $10
	!byte $38
	!byte $e9
	!byte $01
	!byte $0a
	!byte $aa
	!byte $bd
	!byte $02
	!byte $af
	!byte $85
	!byte $c2
	!byte $bd
	!byte $03
	!byte $af
	!byte $85
	!byte $c3
	!byte $a0
	!byte $00
	!byte $98
	!byte $48
	!byte $b1
	!byte $c2
	!byte $20
	!byte $62
	!byte $b3
	!byte $68
	!byte $a8
	!byte $a5
	!byte $1e
	!byte $18
	!byte $69
	!byte $08
	!byte $85
	!byte $1e
	!byte $c8
	!byte $c0
	!byte $06
	!byte $d0
	!byte $eb
	!byte $20
	!byte $29
	!byte $b3
	!byte $09
	!byte $20
	!byte $85
	!byte $35
	!byte $e6
	!byte $28
	!byte $a5
	!byte $28
	!byte $f0
	!byte $07
	!byte $c9
	!byte $7f
	!byte $f0
	!byte $03
	!byte $4c
	!byte $8c
	!byte $af
	!byte $20
	!byte $3d
	!byte $b0
	!byte $20
	!byte $29
	!byte $b3
	!byte $09
	!byte $20
	!byte $c5
	!byte $35
	!byte $f0
	!byte $e7
	!byte $4c
	!byte $73
	!byte $b2
	!byte $a9
	!byte $3c
	!byte $85
	!byte $1e
	!byte $a2
	!byte $07
	!byte $a0
	!byte $00
	!byte $a9
	!byte $4e
	!byte $85
	!byte $1f
	!byte $8a
	!byte $48
	!byte $20
	!byte $7e
	!byte $b3
	!byte $68
	!byte $aa
	!byte $a9
	!byte $00
	!byte $91
	!byte $00
	!byte $a0
	!byte $14
	!byte $91
	!byte $00
	!byte $20
	!byte $e4
	!byte $b3
	!byte $ca
	!byte $10
	!byte $e5
	!byte $60
	!byte $54
	!byte $5c
	!byte $b4
	!byte $bc
	!byte $be
	!byte $be
	!byte $be
	!byte $be
	!byte $47
	!byte $01
	!byte $0d
	!byte $05
	!byte $20
	!byte $4f
	!byte $16
	!byte $05
	!byte $12
	!byte $20
	!byte $3e
	!byte $ad
	!byte $20
	!byte $73
	!byte $b2
	!byte $20
	!byte $ee
	!byte $ab
	!byte $20
	!byte $c1
	!byte $b1
	!byte $a9
	!byte $38
	!byte $85
	!byte $1e
	!byte $a9
	!byte $58
	!byte $85
	!byte $1f
	!byte $a2
	!byte $00
	!byte $bd
	!byte $c2
	!byte $af
	!byte $20
	!byte $62
	!byte $b3
	!byte $20
	!byte $e4
	!byte $b3
	!byte $e8
	!byte $e0
	!byte $09
	!byte $d0
	!byte $f2
	!byte $20
	!byte $2a
	!byte $a7
	!byte $20
	!byte $2a
	!byte $a7
	!byte $20
	!byte $67
	!byte $a1
	!byte $20
	!byte $2a
	!byte $a7
	!byte $4c
	!byte $2a
	!byte $a7
	!byte $05
	!byte $ff
DATA_LB000
	!byte $00
	!byte $00
	!byte $38
	!byte $ee
	!byte $bb
	!byte $ee
	!byte $38
	!byte $00
DATA_LB008
	!byte $00
	!byte $00
	!byte $14
	!byte $ff
	!byte $55
	!byte $ff
	!byte $14
	!byte $00
DATA_LB00F
	!byte $00
	!byte $00
	!byte $3c
	!byte $ff
	!byte $ff
	!byte $ff
	!byte $3c
	!byte $00
DATA_LB018
    !byte $1f
	!byte $3d
	!byte $5b

;-----------------------------------------------------------------------------------

clear_25_2d_2b
    lda #0
	sta $25
	sta $2d
	sta $2b
	rts

LB024
    lda #1
	lsr $9124  ;Timer least significant byte (LSB) of count
	bcc @LB02D
	lda #0
@LB02D
    sta $21
	jsr LAC3E
	and #63
	ora #15
	sta $20
	rts

LB039
    lda #<DATA_LB00F
	sta $10
	lda #>DATA_LB00F
	sta $11
	jmp LA266

LB044
    jsr LAC3E
	pha
	ora #63
	sta $28
	pla
	and #3
	ora #1
	sta $29
	lda $2d
	cmp #2
	bne @LB05D
	lda #1
	sta $29
@LB05D
    rts

LB05E
    lda $4e
	cmp $26
	bne @LB06E
	lda $25
	cmp #3
	beq @LB06E
	lda #0
	sta $25
@LB06E
    rts

LB06F
    ldy $25
	bne @LB0A6
	ldx #2
@LB075
    lda $2e,x
	cmp #128
	bne @LB0A1
	stx $27
	ldx #2
@LB07F
    lda $2e,x
	bmi @LB09C
	ldy DATA_LB018,x
	lda $0080,y
	cmp #3
	bcc @LB09C
	lda $0084,y
	bmi @LB09C
	stx $26
	inc $25
	jsr LB024
@LB099
    jmp @LB185

@LB09C
    dex
	bpl @LB07F
	bmi @LB099

@LB0A1
    dex
	bpl @LB075
	bmi @LB099

@LB0A6
    dec $20
	bne @LB117
	dec $21
	bpl @LB117
	cpy #3
	bne @LB0E3
	ldy $27
	lda #0
	sta $002e,y
	sta $25
	ldx DATA_LB018,y
	lda #1
	tay
	sta $80,x
	lda #2
	cmp $80
	bcs @LB0CA
	iny
@LB0CA
    tya
	sta $81,x
	ldy #2
@LB0CF
    lda $0022,y
	sta $87,x
	dex
	dey
	bpl @LB0CF
	txa
	clc
	adc #8
	tax
	jsr LAD27
	jmp @LB158

@LB0E3
    cpy #1
	bne @LB0EE
	jsr LB024
	inc $25
	bne @LB162
@LB0EE
    ldy $26
	ldx DATA_LB018,y
	jsr LB243
	jsr LA314
	bne @LB101
	inc $21
	inc $20
	bne @LB117
@LB101
    jsr LB024
	inc $25
	ldy $26
	ldx DATA_LB018,y
	jsr LAD80
	ldx #2
@LB110
    lda $0d,x
	sta $22,x
	dex
	bpl @LB110
@LB117
    ldy $25
	cpy #1
	beq @LB185
	cpy #3
	bne @LB162
	ldx #2
@LB123
    lda $85,x
	sec
	sbc $22,x
	bcs @LB12E
	eor #255
	adc #1
@LB12E
    cmp #5
	bcs @LB158
	dex
	bne @LB123
	stx $25
	lda $23
	sta $0e
	lda $24
	sta $0f
	jsr LA972
	jsr LAD25
	lda $4c
	jsr update_player_score_large_amount
	lda $4d
	jsr update_player_score
	jsr plot_player_score_on_screen
	jsr LB7B1
	jmp @LB185

@LB158
    lda $23
	sta $0e
	lda $24
	sta $0f
	bne @LB177
@LB162
    ldy $26
	ldx DATA_LB018,y
	stx $06
	lda $80,x
	asl
	adc $80,x
	adc $06
	adc #4
	sta $06
	jsr LA297
@LB177
    jsr LB039
	lda #<DATA_LB000
	sta $10
	lda #>DATA_LB000
	sta $11
	jsr LA23A
@LB185
    lda $2d
	bne @LB195
	lda player_lives
	cmp #9
	bcs @LB194
@LB18F
    inc $2d
	jmp LB044
@LB194
    rts

@LB195
    cmp #3
	bne @LB1DC
	ldx #31
@LB19B
    ldy #2
	stx $1e
@LB19F
    lda $87,x
	sec
	sbc $002a,y
	bcs @LB1AB
	eor #255
	adc #1
@LB1AB
    cmp #5
	bcs @LB1D0
	dex
	dey
	bne @LB19F
	lda $2b
	sta $0e
	lda $2c
	sta $0f
	lda #0
	sta $2b
	sta $2d
	jsr LA972
	jsr LB7B1
	lda $1e
	clc
	adc #5
	tax
	jmp LAD27

@LB1D0
    lda $1e
	clc
	adc #30
	tax
	cmp #92
	bcc @LB19B
	bcs LB22D

@LB1DC
    dec $28
	bne @LB214
	dec $29
	bpl @LB214
	ldx #0
	jsr LB243
	jsr LA314
	bne @LB1F4
	inc $29
	inc $28
	bne @LB214
@LB1F4
    jsr @LB18F
	lda $2d
	cmp #2
	beq @LB214
	ldx #0
	jsr LAD80
	bcs @LB20F
	ldx #0
	jsr LB243
	jsr LB259
	jmp LB80C

@LB20F
    jsr LB259
	bne LB22D
@LB214
    lda $2d
	cmp #3
	beq LB22D
	cmp #1
	beq LB258
	lda $80
	asl
	adc $80
	adc #4
	sta $06
	jsr LA297
	jmp LB235

LB22D
    lda $2b
	sta $0e
	lda $2c
	sta $0f
LB235
    jsr LB039
	lda #<DATA_LB008
	sta $10
	lda #>DATA_LB008
	sta $11
	jmp LA23A

LB243
    lda $80,x
	stx $50
	asl
	adc $80,x
	adc $50
	tax
	ldy #2
@LB24F
    lda $84,x
	sta $000d,y
	dex
	dey
	bpl @LB24F
LB258
    rts

LB259
    lda $0e
	sta $2b
	lda $0f
	sta $2c
	lda $0d
	sta $2a
	rts

;-----------------------------------------------------------------------------------

DATA_UNKNOWN_A
	!byte $0a
	!byte $2a
	!byte $3a
	!byte $2a
	!byte $ea
	!byte $ea
	!byte $ea
	!byte $2a
DATA_UNKNOWN_A1
	!byte $00
	!byte $80
	!byte $c0
	!byte $80
	!byte $b0
	!byte $b0
	!byte $b0
	!byte $80
DATA_UNKNOWN_A2
	!byte $1a
	!byte $90
	!byte $10
	!byte $90
	!byte $00
	!byte $00
	!byte $00
	!byte $00
DATA_UNKNOWN_A3
	!byte $40
	!byte $60
	!byte $40
	!byte $60
	!byte $00
	!byte $00
	!byte $00
	!byte $00
DATA_LB286
    !byte $00
	!byte $f0
	!byte $e0
	!byte $f0
	!byte $00
	!byte $10
	!byte $20
	!byte $10
	!byte $00
	!byte $f0
	!byte $00
	!byte $10
DATA_LB292
    !byte $e0
	!byte $f0
	!byte $00
	!byte $10
	!byte $20
	!byte $10
	!byte $00
	!byte $f0
	!byte $f0
	!byte $00
	!byte $10
	!byte $00
DATA_LB29E
    !byte $02
	!byte $00
DATA_LB2A0
    !byte $08
	!byte $00
	!byte $09
	!byte $00
	!byte $0a
	!byte $00
	!byte $0b

;-----------------------------------------------------------------------------------

clear_frog_on_screen
    lda #%10000000  ;128
	sta frog_display
LB2AB
    jsr LAC3E
	and #%01111111  ;127
	ora #%00011111  ;31
	sta $43
	rts

LB2B5
    stx $0e
	sty $0f
	ldx #1
@LB2BB
    lda $0e,x
	sec
	sbc $41,x
	bcs @LB2C6
	eor #255
	adc #1
@LB2C6
    cmp #9
	bcs @LB2D3
	dex
	bpl @LB2BB
	jsr LA972
	lda #0
	rts

@LB2D3
    lda #3
	rts

plot_frog_on_screen
    bit frog_display
	bpl @LB2DD
	jmp @LB358

@LB2DD
    ldx #6
	stx $1e
	dex
	bne @LB2E6
@LB2E4
    stx $1e
@LB2E6
    ldy #1
@LB2E8
    lda $82,x
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
	lda #5
	clc
	jsr update_player_score
	jsr plot_player_score_on_screen
	ldx #5
	bne @LB320

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
@LB320
    jsr LAD27
	jsr LB42B
	jsr LB7B1
	jmp clear_frog_on_screen

@LB32C
    lda $1e
	clc
	adc #30
	tax
	cpx #97
	bcc @LB2E4
	lda $2d
	cmp #3
	bne @LB349
	ldx $2b
	ldy $2c
	jsr LB2B5
	bne @LB349
	sta $2d
	sta $2b
@LB349
    lda $25
	cmp #3
	bne @LB358
	ldx $23
	ldy $24
	jsr LB2B5
	sta $25
@LB358
    dec $43
	beq @LB361
	bit frog_display
	bpl @LB392
	rts

@LB361
    ldx #<data_frog_ribbit_sound_clip
	ldy #>data_frog_ribbit_sound_clip
	jsr prepare_sound_data
	jsr LB2AB
	bit frog_display
	bpl @LB3B1
	asl frog_display
	jsr LAC3E
	ldy #20
	ldx #4
	and #3
	beq @LB384
	cmp #2
	bcs @LB395
	ldy #164
	ldx #0
@LB384
    sty $42
	stx $44
	jsr LAC3E
	and #112
	clc
	adc #20
	sta $41
@LB392
    jmp @LB428

@LB395
    ldx #4
	ldy #6
	cmp #2
	beq @LB3A1
	ldx #164
	ldy #2
@LB3A1
    stx $41
	sty $44
	jsr LAC3E
	and #48
	clc
	adc #20
	sta $42
	bne @LB392
@LB3B1
    jsr LB42B
	ldx $2b
	ldy $2c
	lda $2d
	cmp #3
	beq @LB3C8
	ldx $23
	ldy $24
	lda $25
	cmp #3
	bne @LB3F1
@LB3C8
    stx $0e
	sty $0f
	ldx #1
@LB3CE
    ldy DATA_LB29E,x
	lda $41,x
	sec
	sbc $0e,x
	bcs @LB3E0
	eor #255
	adc #1
	iny
	iny
	iny
	iny
@LB3E0
    cmp #25
	bcs @LB409
	pha
	lda DATA_LB2A0,y
	tay
	pla
	cmp #9
	bcs @LB409
	dex
	bpl @LB3CE
@LB3F1
    ldy #255
	jsr LAC3E
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
    lda $41
	clc
	adc DATA_LB286,y
	cmp #165
	bcc @LB416
@LB413
    jmp clear_frog_on_screen

@LB416
    sta $41
	lda $42
	clc
	adc DATA_LB292,y
	cmp #165
	bcs @LB413
	cmp #20
	bcc @LB413
	sta $42
@LB428
    lda #0
	!byte $2c
LB42B
    lda #128
	sta $45
	lda $41
	sta $0e
	lda $42
	sta $0f
	lda #<DATA_UNKNOWN_A
	ldx #>DATA_UNKNOWN_A
	jsr @LB465
	lda $0e
	clc
	adc #8
	sta $0e
	lda #<DATA_UNKNOWN_A1
	ldx #>DATA_UNKNOWN_A1
	jsr @LB465
	lda $0f
	clc
	adc #8
	sta $0f
	lda #<DATA_UNKNOWN_A3
	ldx #>DATA_UNKNOWN_A3
	jsr @LB465
	lda $0e
	sec
	sbc #8
	sta $0e
	lda #<DATA_UNKNOWN_A2
	ldx #>DATA_UNKNOWN_A2
@LB465
    sta $10
	stx $11
	bit $45
	bpl @LB470
	jmp LA266

@LB470
    jmp LA23A

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

    ;Set auxiliary timers
	lda #64
	sta $911b
	sta $912b

    ;Set timers
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
	stx $0e
	jsr set_screen_coordinates
	ldx scroll_heading_delay
	dex
	dex
	beq .reset_scroll_delay
	stx scroll_heading_delay
	rts

.reset_scroll_delay
    ldx #0
	stx $0e
	jsr set_screen_coordinates

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

    ;display "creative software" in heading
	lda #<data_heading_publisher
	sta text_pointer_low
	lda #>data_heading_publisher
	sta text_pointer_high
	ldx #12
	ldy #0
	jsr update_heading

    ;play opening short tune on game start
	lda #38
	sta sound_loop_counter
.play_opening_tune_loop
    jsr play_sounds
	ldy #25
	jsr delay_using_Y
	dec sound_loop_counter
	bne .play_opening_tune_loop

    ;display "presents" text in heading
	lda #<data_heading_presents_title
	sta text_pointer_low
	lda #>data_heading_presents_title
	sta text_pointer_high
	ldx #56
	ldy #8
	jsr update_heading

    ;continue opening short tune on game start
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

    ;display "serpentine" in heading
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
	!byte $06, $ed, $01, $00, $0f, $f0, $03, $00
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
data_sound_clip_8_extra
	!byte $01, $dc, $01, $00, $01, $b4, $ff
data_sound_clip_8
	!byte $02
	!byte <data_sound_clip_8_extra
	!byte >data_sound_clip_8_extra
	!byte $ff
data_sound_clip_9_extra
	!byte $01, $b4, $01, $dc, $ff
data_sound_clip_9
	!byte $02
	!byte <data_sound_clip_9_extra
	!byte >data_sound_clip_9_extra
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

LB7B1
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
@LB7E8
    jsr play_sounds
	lda sound_loop_counter
	lsr
	lsr
	lsr
	jsr LACB7
	ldx $4e
	lda DATA_LB018,x
	tax
	lda $80,x
	sta $07
	lda #1
	sta $08
	txa
	clc
	adc #7
	jsr LA91C
	dec sound_loop_counter
	bne @LB7E8
LB80C
    jsr LBA41
	lda $2d
	cmp #3
	bne @LB818
	jsr LB8CD
@LB818
    jsr update_player_loses_life
	bcs end_of_game

    ;Life lost, play next one
	lda #3
	sta $80

	ldx #4
.delay_using_X_0
    ldy #255
	jsr delay_using_Y
	dex
	bne .delay_using_X_0

	jmp play_one_life

;-----------------------------------------------------------------------------------

end_of_game
    ;All lives lost, end of game, play "last post" tune
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
	!byte $19, $9c, $01, $00, $0f, $9c, $01, $00
	!byte $3c, $b5, $01, $00, $19, $9c, $01, $00
	!byte $0f, $b5, $01, $00, $3c, $c4, $01, $00
	!byte $19, $b5, $01, $00, $0f, $c4, $01, $00
	!byte $3c, $ce, $01, $00, $19, $c4, $01, $00
	!byte $19, $b5, $01, $00, $3c, $9c, $01, $00
	!byte $19, $9c, $01, $00, $0f, $9c, $01, $00
	!byte $3c, $b5, $01, $00, $ff
data_last_post_end_sound_clip
	!byte $03
	!byte <data_last_post_end_sound_clip_extra
	!byte >data_last_post_end_sound_clip_extra
	!byte $ff

;-----------------------------------------------------------------------------------

LB8CD
    jsr clear_all_sound_channels
	ldx #<data_baby_snake_sound_clip
	ldy #>data_baby_snake_sound_clip
	jsr prepare_sound_data
	jsr LB22D

	ldx #4
.delay_using_X_4_1
    ldy #255
	jsr delay_using_Y
	dex
	bne .delay_using_X_4_1

	jsr play_sound
	lda #0
	sta $2d
	ldx #2
@LB8ED
    lda $2a,x
	sta $85,x
	dex
	bpl @LB8ED
	lda $80
	pha
	lda #1
	sta $80
	jsr LAD25
	ldy #0
	jsr LA3F8
	jsr LB916
	pla
	sta $80
	jmp add_one_to_player_lives

LB90C
    jsr clear_all_sound_channels
	ldx #<data_clear_all_sound_channels2
	ldy #>data_clear_all_sound_channels2
	jsr prepare_sound_data
LB916
    lda #166
	cmp $86
	beq @LB953
	jsr @LB9C3
	beq @LB927
@LB921
    jsr @LB9CB
	jmp LB916

@LB927
    jsr @LB9B7
	bcc @LB921
	lda #2
	ldx $87
	cpx #119
	bcc @LB936
	lda #1
@LB936
    jsr @LB9B9
	bcc @LB942
	ldy $09
	lda DATA_UNKNOWN_7-1,y
	bne @LB936
@LB942
    jsr @LB9CB
	jsr @LB9C3
	bne @LB942
	jsr @LB9B7
	bcc @LB921
	lda $85
	bne @LB936
@LB953
    lda $87
	cmp #118
	beq @LB989
	jsr @LB9C3
	beq @LB964
@LB95E
    jsr @LB9CB
	jmp @LB953

@LB964
    lda #2
	jsr @LB9B9
	bcc @LB95E
	lda #4
	jsr @LB9B9
@LB970
    jsr @LB9CB
	jsr @LB9C3
	bne @LB970
	lda #2
	jsr @LB9B9
	bcs @LB970
@LB97F
    jsr @LB9CB
	jsr @LB9C3
	bne @LB97F
	beq @LB927

@LB989
    clc
	jsr LA904
	lda #2
	sta $82
	lda #255
	sta $83
	jsr @LB9CB
	lda #4
	sta $82
@LB99C
    jsr @LB9CB
	ldx #0
	jsr LB243
	ldy $0f
	cpy #134
	bne @LB99C
	ldx $0e
	cpx #166
	bne @LB99C
	sec
	jsr LA904
	jmp clear_all_sound_channels

@LB9B7
    lda #3
@LB9B9
    sta $82
	sta $09
	jsr @LB9C3
	jmp LA362

@LB9C3
    ldy #7
	jsr LA299
	jmp LA2FF

@LB9CB
    ldy #0
	jsr LA3F8
	jsr play_sounds
	jsr plot_frog_on_screen
	lda $2d
	cmp #3
	bne @LB9DF
	jsr LB22D
@LB9DF
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
	bcs .max_cave_number_so_end
	inx
	stx current_maze
.max_cave_number_so_end
    rts

;-----------------------------------------------------------------------------------

LBA09
    lda #20
	sta $1f
@LBA0D
    jsr play_sounds
	jsr LAB7A
	jsr more_player_and_enemy_snake_interactions
	lda #0
	sta $08
	lda $80
	sta $07
	lda #7
	jsr LA91C
	ldy #17
	jsr delay_using_Y
	dec $1f
	bne @LBA0D

	jsr clear_all_sound_channels
	jsr set_current_maze_to_next_one
	jsr LB90C
	lda $2d
	cmp #3
	bne .goto_play_one_life
	jsr LB8CD
.goto_play_one_life
    jmp play_one_life

;-----------------------------------------------------------------------------------

LBA41
    ldx #38
@LBA43
    stx $06
	stx $1e
	lda $79,x
	sta $51
@LBA4B
    jsr LA297
	jsr LA972
	jsr LA3A0
	dec $51
	bne @LBA4B
	lda $1e
	clc
	adc #30
	tax
	cpx #99
	bcc @LBA43
	lda frog_display
	bmi @LBA69
	jsr LB42B
@LBA69
    lda $25
	cmp #3
	bne @LBA7A
	lda $23
	sta $0e
	lda $24
	sta $0f
	jmp LA972
@LBA7A
    rts

;-----------------------------------------------------------------------------------

data_clear_all_sound_channels2_extra
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
data_clear_all_sound_channels2
	!byte $02
	!byte <data_clear_all_sound_channels2_extra
	!byte >data_clear_all_sound_channels2_extra
	!byte $03
	!byte <data_clear_all_sound_channels2_extra
	!byte >data_clear_all_sound_channels2_extra
	!byte $ff
data_baby_snake_sound_clip
	!byte $02
	!byte <data_baby_snake_sound_clip_extra
	!byte >data_baby_snake_sound_clip_extra
	!byte $03
	!byte <data_baby_snake_sound_clip_extra
	!byte >data_baby_snake_sound_clip_extra
	!byte $ff

data_unknown_main
	!byte $10
	!byte $01
	!byte $15
	!byte $0c
	!byte $20
	!byte $1a
	!byte $15
	!byte $1a
	!byte $05
	!byte $0c
	!byte $0f
	!byte $c0
	!byte $78
	!byte $a9
	!byte $02
	!byte $8d
	!byte $1e
	!byte $91
	!byte $20
	!byte $83
	!byte $b4
	!byte $20
	!byte $9d
	!byte $a1
	!byte $a9
	!byte $00
	!byte $85
	!byte $00
	!byte $a9
	!byte $10
	!byte $85
	!byte $01
	!byte $a2
	!byte $10
	!byte $a0
	!byte $00
	!byte $a9
	!byte $ff
	!byte $91
	!byte $00
	!byte $c8
	!byte $d0
	!byte $fb
	!byte $e6
	!byte $01
	!byte $ca
	!byte $d0
	!byte $f6
	!byte $a0
	!byte $f2
	!byte $a9
	!byte $05
	!byte $99
	!byte $ff
	!byte $95
	!byte $88
	!byte $d0
	!byte $fa
	!byte $a2
	!byte $00
	!byte $bd
	!byte $e3
	!byte $ba
	!byte $18
	!byte $69
	!byte $40
	!byte $9d
	!byte $00
	!byte $01
	!byte $e8
	!byte $e0
	!byte $0c
	!byte $90
	!byte $f2
	!byte $a9
	!byte $01
	!byte $85
	!byte $5e
	!byte $a9
	!byte $00
	!byte $85
	!byte $5d
	!byte $85
	!byte $1f
	!byte $aa
	!byte $0a
	!byte $a8
	!byte $20
	!byte $38
	!byte $a9
	!byte $a5
	!byte $1f
	!byte $18
	!byte $69
	!byte $04
	!byte $85
	!byte $1f
	!byte $c9
	!byte $55
	!byte $90
	!byte $ef
	!byte $02
	!byte $30
	!byte $00
	!byte $00
	!byte $81
	!byte $c3
	!byte $3c
	!byte $24
	!byte $24
	!byte $3c
	!byte $24
	!byte $24
	!byte $18
	!byte $02
	!byte $7c
	!byte $58
	!byte $1c
	!byte $74
	!byte $44
	!byte $06
	!byte $18
	!byte $01
	!byte $7e
	!byte $d8
	!byte $18
	!byte $38
	!byte $28
	!byte $0c
	!byte $18
	!byte $40
	!byte $3e
	!byte $1a
	!byte $38
	!byte $2e
	!byte $22
	!byte $60
	!byte $18
	!byte $80
	!byte $7e
	!byte $1b
	!byte $18
	!byte $1c
	!byte $14
	!byte $30
	!byte $98
	!byte $40
	!byte $7c
	!byte $1c
	!byte $1c
	!byte $18
	!byte $18
	!byte $3c
	!byte $18
	!byte $00
	!byte $7c
	!byte $9c
	!byte $1c
	!byte $18
	!byte $18
	!byte $3c
	!byte $00
	!byte $07
	!byte $0f
	!byte $0f
	!byte $07
	!byte $00
	!byte $3f
	!byte $7f
	!byte $80
	!byte $3f
	!byte $75
	!byte $c9
	!byte $ca
	!byte $72
	!byte $2b
	!byte $1f
	!byte $e0
	!byte $fe
	!byte $ff
	!byte $ff
	!byte $fe
	!byte $fc
	!byte $ff
	!byte $ff
	!byte $00
	!byte $ff
	!byte $5d
	!byte $92
	!byte $52
	!byte $4c
	!byte $aa
	!byte $ff
	!byte $00
	!byte $0e
	!byte $fb
	!byte $fb
	!byte $0e
	!byte $00
	!byte $fc
	!byte $fe
	!byte $01
	!byte $fc
	!byte $77
	!byte $4b
	!byte $4a
	!byte $34
	!byte $a8
	!byte $f0
	!byte $00
	!byte $00
	!byte $01
	!byte $01
	!byte $00
	!byte $00
	!byte $3f
	!byte $7f
	!byte $80
	!byte $3f
	!byte $75
	!byte $c9
	!byte $ca
	!byte $72
	!byte $2b
	!byte $1f
	!byte $3c
	!byte $ff
	!byte $ff
	!byte $ff
	!byte $ff
	!byte $7e
	!byte $ff
	!byte $ff
	!byte $00
	!byte $ff
	!byte $5d
	!byte $92
	!byte $52
	!byte $4c
	!byte $aa
	!byte $ff
	!byte $00
	!byte $00
	!byte $80
	!byte $80
	!byte $00
	!byte $00
	!byte $fc
	!byte $fe
	!byte $01
	!byte $fc
	!byte $77
	!byte $4b
	!byte $4a
	!byte $34
	!byte $a8
	!byte $f0
	!byte $00
	!byte $70
	!byte $df
	!byte $df
	!byte $70
	!byte $00
	!byte $3f
	!byte $7f
	!byte $80
	!byte $3f
	!byte $75
	!byte $c9
	!byte $ca
	!byte $72
	!byte $2b
	!byte $1f
	!byte $07
	!byte $7f
	!byte $ff
	!byte $ff
	!byte $7f
	!byte $3f
	!byte $ff
	!byte $ff
	!byte $00
	!byte $ff
	!byte $5d
	!byte $92
	!byte $52
	!byte $4c
	!byte $aa
	!byte $ff
	!byte $00
	!byte $e0
	!byte $f0
	!byte $f0
	!byte $e0
	!byte $00
	!byte $fc
	!byte $fe
	!byte $01
	!byte $fc
	!byte $77
	!byte $4b
	!byte $4a
	!byte $34
	!byte $a8
	!byte $f0
	!byte $07
	!byte $1f
	!byte $7f
	!byte $78
	!byte $f0
	!byte $e0
	!byte $e0
	!byte $e0
	!byte $f0
	!byte $78
	!byte $7f
	!byte $1f
	!byte $07
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $e0
	!byte $f0
	!byte $78
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $78
	!byte $f0
	!byte $e0
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $c0
	!byte $c0
	!byte $c0
	!byte $c0
	!byte $f8
	!byte $fc
	!byte $cc
	!byte $cc
	!byte $cc
	!byte $cc
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $3c
	!byte $7e
	!byte $e7
	!byte $c3
	!byte $e7
	!byte $7e
	!byte $3c
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $37
	!byte $3f
	!byte $39
	!byte $30
	!byte $39
	!byte $3f
	!byte $3f
	!byte $30
	!byte $30
	!byte $30
	!byte $00
	!byte $00
	!byte $00
	!byte $0e
	!byte $06
	!byte $06
	!byte $06
	!byte $86
	!byte $c6
	!byte $c6
	!byte $c6
	!byte $86
	!byte $0f
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $18
	!byte $00
	!byte $38
	!byte $18
	!byte $18
	!byte $18
	!byte $18
	!byte $18
	!byte $3c
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $1c
	!byte $36
	!byte $30
	!byte $30
	!byte $fc
	!byte $30
	!byte $30
	!byte $30
	!byte $30
	!byte $30
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $30
	!byte $30
	!byte $30
	!byte $fc
	!byte $30
	!byte $30
	!byte $30
	!byte $36
	!byte $1c
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $3c
	!byte $7e
	!byte $e7
	!byte $ff
	!byte $e0
	!byte $7e
	!byte $3c
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $37
	!byte $3d
	!byte $38
	!byte $30
	!byte $30
	!byte $30
	!byte $30
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $80
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $07
	!byte $18
	!byte $20
	!byte $47
	!byte $4e
	!byte $8c
	!byte $98
	!byte $90
	!byte $80
	!byte $80
	!byte $80
	!byte $40
	!byte $40
	!byte $20
	!byte $18
	!byte $07
	!byte $e0
	!byte $18
	!byte $04
	!byte $02
	!byte $02
	!byte $01
	!byte $01
	!byte $01
	!byte $01
	!byte $01
	!byte $01
	!byte $02
	!byte $02
	!byte $04
	!byte $18
	!byte $e0
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $7f
	!byte $5f
	!byte $6f
	!byte $77
	!byte $58
	!byte $4b
	!byte $6b
	!byte $3b
	!byte $1b
	!byte $0b
	!byte $07
	!byte $1c
	!byte $1f
	!byte $10
	!byte $18
	!byte $17
	!byte $ef
	!byte $ef
	!byte $ff
	!byte $ff
	!byte $00
	!byte $ff
	!byte $c1
	!byte $d5
	!byte $d5
	!byte $c1
	!byte $ff
	!byte $00
	!byte $00
	!byte $c0
	!byte $40
	!byte $40
	!byte $f0
	!byte $f8
	!byte $fc
	!byte $fe
	!byte $01
	!byte $ff
	!byte $c7
	!byte $c7
	!byte $ff
	!byte $ff
	!byte $ff
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $01
	!byte $42
	!byte $3c
	!byte $3e
	!byte $7e
	!byte $3e
	!byte $1c
	!byte $24
	!byte $04
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $81
	!byte $42
	!byte $3c
	!byte $3e
	!byte $ff
	!byte $7f
	!byte $3e
	!byte $24
	!byte $44
	!byte $04
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $80
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $02
	!byte $01
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $07
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $81
	!byte $42
	!byte $3c
	!byte $3e
	!byte $ff
	!byte $7f
	!byte $3f
	!byte $18
	!byte $44
	!byte $84
	!byte $06
	!byte $00
	!byte $00
	!byte $00
	!byte $40
	!byte $80
	!byte $00
	!byte $00
	!byte $00
	!byte $80
	!byte $e0
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $08
	!byte $06
	!byte $01
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $07
	!byte $18
	!byte $01
	!byte $00
	!byte $00
	!byte $00
	!byte $01
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $89
	!byte $48
	!byte $3c
	!byte $32
	!byte $eb
	!byte $6f
	!byte $7f
	!byte $1c
	!byte $00
	!byte $84
	!byte $04
	!byte $02
	!byte $00
	!byte $00
	!byte $20
	!byte $40
	!byte $00
	!byte $00
	!byte $40
	!byte $00
	!byte $f0
	!byte $00
	!byte $00
	!byte $80
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $10
	!byte $0c
	!byte $02
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $0e
	!byte $30
	!byte $40
	!byte $06
	!byte $00
	!byte $00
	!byte $03
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $08
	!byte $88
	!byte $00
	!byte $3c
	!byte $32
	!byte $e1
	!byte $6d
	!byte $6f
	!byte $3e
	!byte $1c
	!byte $80
	!byte $02
	!byte $01
	!byte $00
	!byte $18
	!byte $20
	!byte $00
	!byte $00
	!byte $20
	!byte $40
	!byte $00
	!byte $f8
	!byte $04
	!byte $00
	!byte $10
	!byte $40
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $10
	!byte $08
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $18
	!byte $40
	!byte $80
	!byte $04
	!byte $08
	!byte $00
	!byte $06
	!byte $00
	!byte $00
	!byte $00
	!byte $08
	!byte $00
	!byte $00
	!byte $00
	!byte $14
	!byte $32
	!byte $e1
	!byte $0d
	!byte $2b
	!byte $2c
	!byte $1c
	!byte $00
	!byte $00
	!byte $00
	!byte $01
	!byte $08
	!byte $00
	!byte $00
	!byte $10
	!byte $20
	!byte $00
	!byte $00
	!byte $3c
	!byte $00
	!byte $00
	!byte $08
	!byte $00
	!byte $20
	!byte $00
	!byte $00
	!byte $00
	!byte $30
	!byte $18
	!byte $04
	!byte $03
	!byte $06
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $04
	!byte $fe
	!byte $38
	!byte $00
	!byte $00
	!byte $00
	!byte $00
	!byte $20
	!byte $30
	!byte $fe
	!byte $18
	!byte $06
	!byte $00
	!byte $00
	!byte $44
	!byte $38
	!byte $08
	!byte $04
	!byte $0c
	!byte $00
	!byte $00
	!byte $1f
	!byte $1f
	!byte $3f
	!byte $3f
	!byte $7f
	!byte $7f
	!byte $ff
	!byte $ff
	!byte $f8
	!byte $f8
	!byte $fc
	!byte $fc
	!byte $fe
	!byte $fe
	!byte $ff
	!byte $ff
	!byte $a9
	!byte $00
	!byte $85
	!byte $06
	!byte $20
	!byte $ee
	!byte $ab
	!byte $20
	!byte $21
	!byte $af
	!byte $a9
	!byte $00
	!byte $85
	!byte $09
	!byte $85
	!byte $14
	!byte $85
	!byte $0d
	!byte $85
	!byte $0f
	!byte $a9
	!byte $50
	!byte $85
	!byte $2a
	!byte $a9
	!byte $75
	!byte $85
	!byte $2b
	!byte $20
	!byte $68
	!byte $bf
	!byte $a9
	!byte $04
	!byte $85
	!byte $29
	!byte $a9
	!byte $80
	!byte $85
	!byte $68
	!byte $a9
	!byte $7d
	!byte $85
	!byte $5b
	!byte $a9
	!byte $be
	!byte $85
	!byte $67
	!byte $85
	!byte $5a
	!byte $a9
	!byte $7c
	!byte $85
	!byte $11
	!byte $85
	!byte $12
	!byte $85
	!byte $13
	!byte $a9
	!byte $80
	!byte $85
	!byte $15
	!byte $a9
	!byte $ff
	!byte $85
	!byte $16
	!byte $a9
	!byte $7e
	!byte $85
	!byte $0c
	!byte $a2
	!byte $03
	!byte $a9
	!byte $7e
	!byte $95
	!byte $63
	!byte $bd
	!byte $05
	!byte $b5
	!byte $95
	!byte $5f
	!byte $ca
	!byte $10
	!byte $f4
	!byte $a9
	!byte $7f
	!byte $85
	!byte $63
	!byte $a9
	!byte $00
	!byte $85
	!byte $34
	!byte $85
	!byte $69
	!byte $85
	!byte $31
	!byte $a2
	!byte $09
	!byte $95
	!byte $b8
	!byte $ca
	!byte $10
	!byte $fb
	!byte $a2
	!byte $0f
	!byte $a9
	!byte $7e
	!byte $95
	!byte $7a
	!byte $ca
	!byte $10
	!byte $f9
	!byte $a9
	!byte $00
	!byte $a2
	!byte $06
	!byte $95
	!byte $17
	!byte $ca
	!byte $10
	!byte $fb
	!byte $a2
	!byte $09
	!byte $95
	!byte $c2
	!byte $ca
	!byte $10
	!byte $fb
	!byte $a2
	!byte $0f
	!byte $20
	!byte $56
	!byte $b3
	!byte $c9
	!byte $7d
	!byte $b0
	!byte $f9
	!byte $c9
	!byte $10
	!byte $90
	!byte $f5
	!byte $95
	!byte $4a
	!byte $20
	!byte $56
	!byte $b3
	!byte $95
	!byte $3a
	!byte $ca
	!byte $10
	!byte $eb
	!byte $a9
	!byte $01
	!byte $85
	!byte $06
	!byte $20
	!byte $ee
	!byte $ab
	!byte $20
	!byte $28
	!byte $a5
	!byte $20
	!byte $b0
	!byte $a6
	!byte $20
	!byte $93
	!byte $a2
	!byte $20
	!byte $e6
	!byte $a1
	!byte $20
	!byte $47
	!byte $aa
	!byte $20
	!byte $94
	!byte $a7
	!byte $20
	!byte $3e
	!byte $a8
	!byte $20
	!byte $99
	!byte $ab
	!byte $20
	!byte $a4
	!byte $ac
	!byte $20
	!byte $a7
	!byte $ad
	!byte $20
	!byte $19
	!byte $ae
	!byte $20
	!byte $cb
	!byte $a3
	!byte $20
	!byte $d7
	!byte $a2
	!byte $20
	!byte $a4
	!byte $aa
	!byte $20
	!byte $29
	!byte $ac
	!byte $20
	!byte $e2
	!byte $a8
	!byte $20
	!byte $80
	!byte $a8
	!byte $20
	!byte $82
	!byte $a3
	!byte $20
	!byte $d5
	!byte $a4
	!byte $20
	!byte $5c
	!byte $b0
	!byte $20
	!byte $3d
	!byte $b0
	!byte $20
	!byte $72
	!byte $bf
	!byte $e6
	!byte $28
	!byte $4c
	!byte $21
	!byte $bf
	!byte $a9
	!byte $00
	!byte $85
	!byte $37
	!byte $85
	!byte $33
	!byte $85
	!byte $5c
	!byte $60
	!byte $02
	!byte $ad
	!byte $71
	!byte $6f
	!byte $a0
	!byte $00
	!byte $99
	!byte $21
	!byte $6f
	!byte $60
	!pet "oppe"
	!byte $61
	!pet "As01, files scratched,01,00"
	!byte $00
	!pet "cserpentine $6",$0d
	!byte $00
	!byte $43
	!byte $33
	!byte $50
	!byte $62
	!byte $6d
	!pet "clear "
	!byte $62
	!byte $73
	!pet "wha   "
	!byte $62
	!byte $7b
	!pet "cleap "
	!byte $62
	!byte $7f
	!pet "plotch"
	!byte $62
	!byte $8e
	!pet "pbp   "
	!byte $62
	!pet $99,"shifp "
	!byte $62
	!byte $a3
	!pet "dshift"
	!byte $62
	!byte $a9
	!pet "leshif"
	!byte $62
	!pet "Hpbpl  "
	!byte $62
	!pet "Jshif  "
	!byte $00
end_of_program
