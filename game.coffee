"use strict"
canvas = document.getElementById 'c'
context = canvas.getContext '2d'
[canvas.width, canvas.height] = [320,320]
fps = 0
last_frame_count = 0
frames = 0
map = null
hero = null
#- constants
for direction in ['NORTH','SOUTH','EAST','WEST', 'NORTH_EAST', 'NORTH_WEST', 'SOUTH_EAST','SOUTH_WEST']
  @["#{direction}"] = {NORTH: 1, SOUTH: 2, EAST: 4, WEST: 8, NORTH_EAST: 5, NORTH_WEST: 9, SOUTH_EAST: 6, SOUTH_WEST: 10}[direction]
  @["DIR_#{direction}"] = new ->
    @[direction] = true
    @.dirname = window[direction]
    @.movement = false
    @.marked_for_deletion = false
    @.delete = ->
      @marked_for_deletion = true
    @

#- helper methods
rgba = (r,g,b,a) ->
  colors = for color in [r,g,b]
    ~~(color)
  colors.push(a)
  "rgba(#{colors.join(',')})"

rgb = (r,g,b) -> rgba(r,g,b,1)

pixel_coords_to_tile_coords = (x,y) ->
  [(x >> 5),(y >> 5)]

clear = ->
  context.fillStyle = rgb(0xd0,0xe7,0xf9)
  context.beginPath()
  context.rect 0,
               0,
               canvas.width,
               canvas.height
  context.closePath()
  context.fill()

update_fps= ->
  fps = frames - last_frame_count
  document.getElementById('fps').innerText= [fps, 60].join('/') + ' FPS'
  last_frame_count = frames
  setTimeout(update_fps, 1000)

get_dir = (loc1,loc2) ->
  return NORTH_EAST if loc1.x < loc2.x and loc1.y > loc2.y
  return NORTH_WEST if loc1.x > loc2.x and loc1.y > loc2.y
  return SOUTH_WEST if loc1.x > loc2.x and loc1.y < loc2.y
  return SOUTH_EAST if loc1.x < loc2.x and loc1.y < loc2.y
  return EAST if loc1.x < loc2.x
  return WEST if loc1.x > loc2.x
  return SOUTH if loc1.y > loc2.y
  return NORTH

class Highlighter
  @.current_hightlight = null
  @.highlight = (target) ->
    context.strokeStyle = rgb(0xff,0xff,0x00)
    context.beginPath()
    context.strokeRect(target.x,target.y, target.width, target.height)
    context.closePath()
    context.fill()
    @current_hightlight = target
  @.refresh = ->
    @highlight(@current_hightlight) if @current_hightlight? and (frames%4==0)

Object.prototype.reverse_merge= (other_hash) ->
  for attrib of other_hash
    @[attrib] = other_hash[attrib] if !@[attrib]?
  @

#- game loop
game_loop= ->
  frames++
  clear()
  for x in map
    for turf in x
      turf.draw()
  hero.draw()
  hero.check_moving()
  Highlighter.refresh()
  setTimeout(game_loop, 1000/60)
#- Graphics
window.Icon = class Icon
  #- set up public attributes
  failed: false
  success: false
  width: null
  height: null
  states: {}
  frame_rate: 3
  current_frame: 0
  current_state: 0
  target: null

  constructor: (target,options={}) ->
    @target = target if target?
    @.reverse_merge(options)
    #- set up a private attributes
    image = new Image()
    image.onerror = @on_fail
    image.onload = @on_success

    #- privileged methods
    @.set_source = (new_src) ->
     image.src = new_src
    @.set_source(options.src) if options.src?

    #- using the failure alerts and such, we can show a place holder for broken images, etc.
    @.image_data = ->
      if @success? then image else null
    do =>
      i = 0
      for dir in [NORTH,SOUTH, EAST, WEST]
        @states[dir] = {x_off: i * (@frame_rate * @width) , y_off: 0}
        i++

    #- return the final object
    console.log @
    @


  on_fail: ->
    console.log 'image failed'
    @failed = true
    delete @.success

  on_success: ->
    console.log 'image loaded'
    @success = true
    delete @.failed

  x_offset: ->
    frame = frames
    offset = 0
    #- what do you mean we don't have a state for that direction!
    try
      offset = @states[@target.dir].x_off
    catch exception
      flat_dir = @target.dir & ~(NORTH|SOUTH)
      offset = @states[flat_dir].x_off
    (@current_frame = (@current_frame + 1) % @frame_rate) if @target.moving and @target.ready_to_animate()
    offset += (@current_frame * @width)
    offset
  y_offset: ->
    0
#- models
class Turf
  constructor: (options={})->
    options.reverse_merge @attributes if @attributes?
    option_defaults =
       image_src: 'images/turf.png'
       x: 0
       y: 0
       width: 32
       height: 32
       frame: 0
       frames: 0
       animated: false
       frame_rate: 0
       density: 0
    options.reverse_merge(option_defaults)
    @.reverse_merge(options)
    @image = new Image()
    @image.src = @image_src
    @image.width =  @width
    @image.height = @height

  draw: ->
    context.drawImage @image,
                      0,
                      0,
                      @image.width,
                      @image.height,
                      @x,
                      @y,
                      @image.width,
                      @image.height
    @animate() if @animated and @ready_to_animate()

  animate: ->

  ready_to_animate: ->
    !!((frames%@frame_rate)==0)

  bumped: (bumper) ->

class Wall extends Turf
  bumped: (bumper) ->
    console.log 'You ran into a wall'
Wall.prototype.attributes =
  gay: true
  image_src: 'images/wall.png'
  density: true

class Water extends Turf
  animate: ->
    @frame = (@frame+1) % @frames
    @image.src = @image_srcs[@frame]

Water.prototype.attributes =
  frames: 2
  frame_rate: 20
  animated: true
  image_src: 'images/water0.png'
  density: true
  image_srcs:  {0: 'images/water0.png', 1: 'images/water1.png'}

class Hero
  constructor: (options={})->
    option_defaults =
      x: 0
      y: 0
      width:  20
      height: 32
      image_src: 'images/goku.png'
      image_width: 20
      image_height: 32
      frames:
        1:
          x_off: 20
          t_off: 10
      dir: SOUTH
      moving: false
      icon: null
    options.reverse_merge(option_defaults)
    @.reverse_merge(options)
    @icon = new Icon @,{width: @image_width, height: @image_height, src: @image_src}
    @move_to(@x,@y)

  ready_to_animate: ->
    ((frames % 4) == 0)

  heading: (dir) ->
    !!(@dir & dir)

  draw: ->
    context.drawImage @icon.image_data(),
                      @icon.x_offset(),
                      @icon.y_offset(),
                      @icon.width,
                      @icon.height,
                      @x,
                      @y,
                      @icon.width,
                      @icon.height

  move_to: (x,y,options={}) ->
    success = true
    option_defaults =
      animate: true
      ignore_density: false
    options.reverse_merge(option_defaults)
    unless options.ignore_density
      #- normalize the coordinates, so any lay offer is negated
      [offx , offy] = [x, y]
      offx += ~~(@width) if @heading(EAST)
      offy += ~~(@height) if @heading(SOUTH)
      [tile_x ,tile_y] = pixel_coords_to_tile_coords(offx - (offx&31),offy + (offy&31))
      tile = map[tile_x][tile_y]
      if tile? and @colliding_with(tile)?
        Highlighter.highlight(tile)
        tile.bumped(@)
        success = false
    [@x,@y] = [x,y] if success

  #- if colliding_with?(obj)
  colliding_with: (turf,options={}) ->
    options.reverse_merge {x: @x, y: @y}
    left1 = options.x
    left2= turf.x
    right1 = options.x + @width
    right2 = turf.x + turf.width
    top1 = options.y
    top2 = turf.y
    bottom1 = options.y + @height
    bottom2 = turf.y + turf.height
    return null if !turf.density
    return null if bottom1 < top2
    return null if top1 > bottom2
    return null if right1 < left2
    return null if left1 > right2
    true

  check_moving: ->
    if @moving
      moving_states = {}
      moving_states[NORTH] = {x: 0, y: -1}
      moving_states[SOUTH] = {x: 0, y: 1}
      moving_states[EAST] = {x: 1, y: 0}
      moving_states[WEST] = {x: -1, y: 0}
      xo = yo = 0
      for dir in Object.keys(moving_states)
        if !!(@dir & dir)
          xo += moving_states[dir].x
          yo += moving_states[dir].y
      @move_to @x + xo, @y + yo

  start_moving: (dir) ->
    @dir = switch (dir | @dir)
      when 3,12 then dir
      else (if @moving then (dir | @dir) else dir)
    @moving = true

  stop_moving: (dir)->
    @moving = switch @dir
      when NORTH_EAST,NORTH_WEST,SOUTH_EAST,SOUTH_WEST then true
      else false
    @dir = switch (pending_dir = @dir ^ dir)
      when 0, (NORTH|SOUTH),(EAST|WEST) then dir
      else pending_dir

#- map
map_data = [0, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0,
            0, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0,
            0, 0 ,2 ,2 ,0 ,2 ,2 ,0 ,0 ,0,
            0, 0 ,2 ,1 ,1 ,1 ,2 ,0 ,0 ,0,
            0, 0 ,2 ,1 ,1 ,1 ,2 ,0 ,0 ,0,
            0, 0 ,2 ,2 ,1 ,2 ,2 ,0 ,0 ,0,
            0, 0 ,0 ,0 ,1 ,0 ,0 ,0 ,0 ,0,
            0, 0 ,0 ,0 ,1 ,0 ,0 ,0 ,0 ,0,
            0, 0 ,0 ,0 ,1 ,0 ,0 ,0 ,0 ,0,
            0, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0]


tile_mappings =
  0: Turf
  1: Water
  2: Wall

map = for x in [0..9]
  for y in [0..9]
    index = y * 10 + x
    struct = map_data[index]
    options = {
      x: x << 5,
      y: y << 5
    }
    new tile_mappings[struct](options)

#- keyboard

KeyBoard = do ->
  parse_key: (code) ->
    String.fromCharCode(code)
  parse_event: (key,event) ->
    [KeyBoard.parse_key(key.key_code()), event].join('_')


for key in [0..255]
  try
    button = KeyBoard.parse_key(key)
    KeyBoard["#{button}_pressed"] = ->
    KeyBoard["#{button}_released"] = ->
  catch exception
    console.log 'unabled to define helper method for ', key, KeyBoard.parse_key(key)

KeyboardEvent.prototype.key_code= ->
  @keyCode || @charCode

KeyboardEvent.prototype.pressed = ->
  event = KeyBoard.parse_event @, 'pressed'
  KeyBoard[event].call()

KeyboardEvent.prototype.released = ->
  event = KeyBoard.parse_event @, 'released'
  KeyBoard[event].call()

window.onkeydown = (key) ->
  key.pressed()

window.onkeyup = (key) ->
  key.released()

KeyBoard.A_pressed = ->
  hero.start_moving WEST
KeyBoard.A_released = ->
  hero.stop_moving WEST

KeyBoard.D_pressed = ->
  hero.start_moving EAST
KeyBoard.D_released = ->
  hero.stop_moving EAST

KeyBoard.W_pressed = ->
  hero.start_moving NORTH
KeyBoard.W_released = ->
  hero.stop_moving NORTH

KeyBoard.S_pressed = ->
  hero.start_moving SOUTH
KeyBoard.S_released = ->
  hero.stop_moving SOUTH

window.KeyBoard = KeyBoard
window.onload= ->
  hero = new Hero()
  game_loop()
  update_fps()
  window.hero = hero
