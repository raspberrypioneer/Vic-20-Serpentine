# Serpentine technical analysis

Serpentine is a 6502 cartridge game for an expanded Commodore VIC-20. The player guides a
growing snake through successive maze layouts, avoiding larger enemy snakes while eating weaker
ones, frogs, and eggs. This document gives the architectural context for the annotated
disassembly in main.asm.

## Program structure

The cartridge starts at $a000. start_of_program initialises the VIC and VIA timers, score and
pseudo-random state, then enters the opening title sequence. Fire transfers directly into a game
session; no ordinary return path leads back from the title or game-over screens.

    start_of_program
        -> initialise system and pseudo-random state
        -> run_opening_title_screen
           -> title attract loop: scroll message, enemy movement, theme and joystick input
        |
        v
    start_game_play
        -> reset score, lives and maze level
        -> play_one_life
           -> initialise snake/egg/frog state and draw maze
           -> play_pre_maze_tune
           -> game_play_loop
              -> player movement
              -> enemy movement and collision resolution
              -> egg, frog, sound and joystick updates
              -> speed adjustment
        |
        +-> handle_player_death -> resolve_player_life_loss
        |                         -> next life or run_game_over_sequence
        |
        +-> handle_maze_completion
           -> advance_maze_level -> player_snake_goes_home
           -> optional baby-snake return -> play_one_life

The game loop is cooperative rather than interrupt-driven. SEI remains in effect and timing is
provided by busy-wait loops and software counters. The two VIA Timer 1 counters are configured at
startup and their changing values seed the pseudo-random generator.

## Memory map and runtime state

| Area | Address | Purpose |
|---|---:|---|
| Cartridge program | $a000-$bfff | Code, data, maze definitions, bitmaps, sound data and padding for the 8K cartridge image. |
| Video matrix | $0200-$02f1 | 242 character indices forming the 22-by-11 display grid. |
| Character bitmap RAM | $1000-$17ff | The bitmap canvas addressed by the plotting routines. |
| Colour RAM | $9600 onward | Per-character display colours. |
| VIC registers | $9000-$900f | Display position, memory selection, sound, colour and border. |
| Zero page | $00-$7c | Drawing workspace, snake state, eggs, frog, scores, sound state and pseudo-random state. |
| Snake records | $80 onward | Player record followed by three 30-byte enemy record areas. |

The zero-page aliases are deliberately contextual. For example, $0d-$0f are normally
current_direction, screen_column, and screen_row, while maze drawing also uses $0d as
maze_part_to_plot. Likewise, several short-lived offsets share $50-$52. These aliases are working
registers, not persistent objects, and callers must not expect them to survive unrelated routines.

Each snake record contains its length, colour, current direction, home-transition state, entrance
state, and up to six direction/column/row segment triples. The player record begins at $80; the
enemy records include a preceding entrance-delay byte and are processed through offsets from the
same base table.

## Character mode used as a bitmap canvas

The VIC-20 has no hardware bitmap mode or hardware sprites. Conventional VIC-20 games normally
reuse a small set of redefined character glyphs. Serpentine instead makes the character generator
RAM behave like a bitmap canvas.

initialise_bitmap_grid_index fills the video matrix with sequential character indices. Each visible
cell therefore refers to a different eight-byte character bitmap at $1000, rather than sharing a
glyph with another cell. compute_bitmap_screen_address_from_screen_row_column converts a pixel-style
coordinate into that bitmap address and bit position. The plot and erase routines then set, merge,
shift, or clear individual bitmap bits.

This arrangement permits snake segments, maze pieces, eggs and the frog to overlap at arbitrary bit
offsets within a cell. plot_bitmap_on_screen merges source pixels with the existing canvas;
erase_bitmap_on_screen removes a bitmap while preserving unaffected pixels. The screen still uses
VIC character mode, but the unique character mappings make it function as a compact bitmap-style
playfield.

The VIC is configured for 22 columns and 11 tall character rows, producing the game's logical
176-by-176-pixel playing area. Maze navigation is based on an 11-by-11 grid of 16-pixel cells,
which is why movement and wall tests repeatedly check 8- and 16-pixel alignment.

## Mazes and movement

Twenty maze definitions are stored in packed form. Each byte contains four two-bit maze-part values;
the final byte has two unused parts, giving 110 defined parts for the 11-by-10 map area. The
renderer selects a maze by maze_level, decodes each part and plots the required horizontal and
vertical bitmap sections. Levels above 20 reuse maze layouts 11-20 while score awards remain capped
at level 20.

Directions use the compact values Up = 1, Down = 2, Right = 3 and Left = 4. Player input becomes
planned_direction; it is accepted only at the appropriate cell alignment and only if it is not a
U-turn. During movement, each segment receives the direction propagated by the preceding segment,
so the body follows the head without storing a path history.

The common movement routine also handles the special home transition state. $80 means an initial
exit from the home enclosure, $ff is the player return-entry sequence, and $00 is normal maze
movement. A separate $80/$00 flag keeps the home door open until the snake has fully exited.

## Enemies, collisions and completion

Enemy snakes use the same record format as the player but receive staggered entrance delays. Their
movement is paced by a global speed counter and individual tick state. A live enemy chooses a
planned direction using a mixture of player-targeting and pseudo-random turns; blocked or invalid
turns are retried through the same maze-validity logic used by the player.

handle_player_and_enemy_snake_interactions separates collision detection from resolution. It tests
player/enemy heads and body segments, records the results in three-byte per-enemy flag arrays, then
applies scores, body growth or removal, sound effects and death states. An enemy shorter than the
player becomes weak (green) and can be eaten; otherwise the player loses the encounter.

Enemy death uses negative tick values. $80 means fully dead, while other negative values animate
disintegration. Once all three enemy ticks are negative, handle_maze_completion holds the player
visible for 20 updates so the remaining death animations can finish, advances the maze level and
sends the player home.

## Eggs, frog and player lives

Player and enemy eggs share a three-stage lifecycle: developing, attached/laying, then detached and
hatchable. The player egg retains its final tail position and direction so a baby snake can hatch
there. A detached enemy egg may hatch into a replacement enemy, while either type of hatchable egg
can be eaten by the frog.

The frog alternates between an off-screen pseudo-random countdown and an on-screen path. It can be
eaten by a snake, eat hatchable eggs, or leave the playable area. Its bitmap is assembled from four
8-by-8 quadrants and is explicitly erased before each repositioning.

When a hatchable player egg survives a death or a cleared maze, it becomes a temporary two-segment
baby snake. The baby follows the player return-home route and awards one life, up to a maximum of
nine. During player death this offsets the life that is then removed, so the hatch effectively saves
the life.

## Score, sound and presentation

Player and high scores occupy three packed binary-coded decimal bytes each, supporting six decimal
digits. Decimal-mode routines add units/tens and hundreds/thousands amounts separately. Extra lives
are awarded at 20,000 points, then at 50,000-point intervals.

Score awards scale with maze level: enemy heads award 200 points times floor(level / 2) + 1 per
enemy segment, body segments award half that amount, and eggs award 150 points times level + 1.
The calculation caps the effective level at 20.

The four VIC sound voices are driven by table-based clips. prepare_sound_data expands a clip into
per-channel address, duration and position state; play_sounds advances active channels one tick at
a time. A few effects, notably the baby-egg hatch sweep, write VIC frequency registers directly.
The title and restart attract loops combine music with moving enemy snakes, while the title alone
also scrolls a 20-character RAM message window.

## Preserved anomalies and implementation quirks

The disassembly intentionally preserves original bytes and behaviour. Notable observations include:

- initialise_system_registers contains legacy bitmap-address stores and a bitmap write whose result
  has no later observable use; they remain for byte equivalence.
- The death-animation data defines six sparse frames, but the animation code selects only frames
  one and two.
- The title scroll's source-index limit permits its terminator index for one window at wrap-around,
  creating a brief repeated window before the next normal pass.
- Several code/data padding regions are retained from the cartridge image as junk1.asm and
  junk2.asm, rather than being replaced with generated fill bytes.
- maze_level stops advancing at 99, although maze layouts and score values are capped as described
  above.

## Source layout and verification

main.asm contains the complete cartridge disassembly: hardware symbols, zero-page aliases,
executable routines, tables, bitmaps and sound data. junk1.asm and junk2.asm preserve original
unidentified/padding bytes so the assembled cartridge remains identical to the source image.

se_build.bat assembles main.asm with ACME, adds the two-byte PRG load address and compares the result
against prg/Serpentine original.prg. The binary comparison is the essential verification step after
any label or comment change, and especially after changes near address-sensitive data or the
cartridge padding.

