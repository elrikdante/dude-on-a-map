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
for direction in ['NORTH','SOUTH','EAST','WEST']
  @["#{direction}"] = {NORTH: 1, SOUTH: 2, EAST: 4, WEST: 8}[direction]
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
  setTimeout(game_loop, 1000/60)

#- models
class Turf
  constructor: (options={})->
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
                      @x << 5,
                      @y << 5,
                      @image.width,
                      @image.height
    @animate() if @animated and @ready_to_animate()
  animate: ->

  ready_to_animate: ->
    !!((frames%@frame_rate)==0)

class Water extends Turf
  constructor: (options={}) ->
    @image_srcs = {0: 'images/water0.png', 1: 'images/water1.png'}
    option_defaults={frames: 2,frame_rate: 20,animated: true, image_src: 'images/water0.png'}
    super options.reverse_merge(option_defaults)
  animate: ->
    @frame = (@frame+1) % @frames
    @image.src = @image_srcs[@frame]

class Hero
  constructor: (options={})->
    option_defaults =
      x: 0
      y: 0
      width: 32
      height: 32
      image_src: 'images/link.png'
      dir: 0
      moving: false
    options.reverse_merge(option_defaults)
    @.reverse_merge(options)
    @image = new Image()
    @image.src = @image_src
    @image.width = @width
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

  move_to: (@x,@y,options={}) ->
    option_defaults =
      animate: true
    options.reverse_merge(option_defaults)

  check_moving: ->
    if @moving
      console.log 'moving'
      moving_states = {}
      moving_states[NORTH] = {x: 0, y: -1}
      moving_states[SOUTH] = {x: 0, y: 1}
      moving_states[EAST] = {x: 1, y: 0}
      moving_states[WEST] = {x: -1, y: 0}
      xo = yo = 0
      for dir in Object.keys(moving_states)
        if @dir & dir
          xo += moving_states[dir].x
          yo += moving_states[dir].y
      @move_to @x + xo, @y + yo

  heading: (dir) ->
    @dir & dir.dirname

  start_moving: (dir) ->
    @dir = switch dir.dirname | @dir
      when 3,12 then dir
      else dir.dirname | @dir
    @moving = true

  stop_moving: (dir)->
    if (dir.EAST? and @heading(WEST)) or (dir.WEST? and @heading(EAST)) or (dir.NORTH? and @heading(SOUTH)) or (dir.SOUTH? and @heading(NORTH))
      @dir = dir.dirname
      return
    @dir = switch pending_dir = @dir ^ dir.dirname
      when 0
        console.log 'stopped'
        @moving = false
        dir.dirname
      else pending_dir

#- map
map_data = [1, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,1,
            0, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0,
            0, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0,
            0, 0 ,0 ,1 ,1 ,1 ,1 ,0 ,0 ,0,
            0, 0 ,1 ,1 ,1 ,1 ,1 ,1 ,0 ,0,
            0, 0 ,1 ,1 ,1 ,1 ,1 ,1 ,0 ,0,
            0, 0 ,0 ,1 ,1 ,1 ,1 ,0 ,0 ,0,
            0, 0 ,0 ,0 ,1 ,0 ,0 ,0 ,0 ,0,
            0, 0 ,0 ,0 ,1 ,0 ,0 ,0 ,0 ,0,
            1, 0 ,0 ,0 ,1 ,0 ,0 ,0 ,0 ,1 ]

tile_mappings = {
  0: Turf,
  1: Water
}

map = for x in [0..9]
        for y in [0..9]
          screen_x = x
          screen_y = 9 - y
          index = screen_y * 10 + screen_x
          struct = map_data[index]
          options = {
            x: x,
            y: y
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
  hero.start_moving DIR_WEST
KeyBoard.A_released = ->
  hero.stop_moving DIR_WEST

KeyBoard.D_pressed = ->
  hero.start_moving DIR_EAST
KeyBoard.D_released = ->
  hero.stop_moving DIR_EAST

KeyBoard.W_pressed = ->
  hero.start_moving DIR_NORTH
KeyBoard.W_released = ->
  hero.stop_moving DIR_NORTH

KeyBoard.S_pressed = ->
  hero.start_moving DIR_SOUTH
KeyBoard.S_released = ->
  hero.stop_moving DIR_SOUTH

window.KeyBoard = KeyBoard
window.onload= ->
  hero = new Hero()
  game_loop()
  update_fps()
  window.hero = hero
