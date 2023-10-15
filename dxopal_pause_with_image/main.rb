require "dxopal"
include DXOpal

WIN_W = 300
WIN_H = 300

class Ball
  attr_reader :x, :y

  def initialize
    @x = rand(WIN_W)
    @y = rand(WIN_H)
    @dx = 2
    @dy = 2
  end

  def update
    @dx = -@dx if @x < 0 || @x > WIN_W
    @dy = -@dy if @y < 0 || @y > WIN_H
    @x += @dx
    @y += @dy
  end
end

# --------------------------------

def tick(img)
  $ball.update
  img.circle_fill($ball.x, $ball.y, 10, C_RED)
end

def tick_with_pause
  if $paused
    Window.draw(0, 0, $img)
    Window.draw_box_fill(0, 0, WIN_W, WIN_H, [100, 0,0,0])
    Window.draw_font(0, 0, "...PAUSE...", Font.default, color: C_WHITE)
  else
    $img.box_fill(0, 0, WIN_W, WIN_H, [245,245,245])
    tick($img)
    Window.draw(0, 0, $img)
  end

  if Input.key_push?(K_SPACE)
    $paused = ! $paused
  end
end

# --------------------------------

Window.width  = WIN_W
Window.height = WIN_H
# Window.fps = 30

Window.bgcolor = [245, 245, 245]

$ball = Ball.new
$paused = false
$img = Image.new(WIN_W, WIN_H)

Window.load_resources do
  Window.loop do
    tick_with_pause
  end
end
