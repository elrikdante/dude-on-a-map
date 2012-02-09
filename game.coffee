"use strict"
canvas = document.getElementById 'c'
context = canvas.getContext '2d'
[canvas.width, canvas.height] = [320,320]
fps = 0
last_frame_count = 0
frames = 0
turf = null

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


#- game loop
game_loop= ->
  frames++
  clear()
  turf.draw()
  setTimeout(game_loop, 1000/60)


#- models
class Turf
  constructor: (@image_src='images/turf.png')->
    @image = new Image()
    @image.src = @image_src
    @image.width = @width = 32
    @image.height = @height = 32
    @x = @y = 0
  draw: ->
    [target_x,target_y] = [(@x << 5), (@y << 5)]
    context.drawImage @image,
                      0,
                      0,
                      @image.width,
                      @image.height,
                      target_x,
                      target_y,
                      @image.width,
                      @image.height
window.onload= ->
  turf = new Turf()
  console.log('dude on a map')
  console.log(turf)
  game_loop()
  update_fps()
