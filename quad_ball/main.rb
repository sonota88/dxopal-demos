require "dxopal"
include DXOpal

# ul ur
# bl br

WIN_W = 512
WIN_H = 512

C_LINE = [255, 255, 255]

class Ball
  attr_reader :x, :y

  def initialize
    @x = rand(WIN_W)
    @y = rand(WIN_H)
    @dx = 1 + rand()
    @dy = 1 + rand()
  end

  def update
    @dx = -@dx if @x < 0 || @x > Window.width
    @dy = -@dy if @y < 0 || @y > Window.height
    @x += @dx
    @y += @dy
  end
end

def box_color(n)
  if n == 6
    C_RED
  else
    val = 255 - (n + 1) * 30
    [val, val, val]
  end
end

def draw_quad(xmin, ymin, xmax, ymax, mx, my, n)
  return if n > 6

  w = xmax - xmin
  h = ymax - ymin

  x1, x2 =
    if mx - xmin < w/2
      [  0, w/2]
    else
      [w/2,   w]
    end

  y1, y2 =
    if my - ymin < h/2
      [  0, h/2]
    else
      [h/2,   h]
    end

  Window.draw_box_fill(xmin + x1, ymin + y1, xmin + x2, ymin + y2, box_color(n))

  Window.draw_box(xmin, ymin, xmax, ymax, C_LINE)
  Window.draw_line(xmin + w/2, ymin, xmin + w/2, ymax, C_LINE)
  Window.draw_line(xmin, ymin + h/2, xmax, ymin + h/2, C_LINE)

  draw_quad(xmin + x1, ymin + y1, xmin + x2, ymin + y2, mx, my, n + 1)
end

def draw(mx, my)
  draw_quad(0, 0, WIN_W, WIN_H, mx, my, 0)
  Window.draw_circle(mx, my, 15, C_RED)
end

def tick
  mx = Input.mouse_x
  my = Input.mouse_y

  if (0 < mx && mx < WIN_W) && (0 < my && my < WIN_H)
    draw(mx, my)
  else
    $ball.update
    draw($ball.x, $ball.y)
  end
end

# --------------------------------

Window.width  = WIN_W
Window.height = WIN_H
Window.fps = 20

Window.bgcolor = [245, 245, 245]

$ball = Ball.new

Window.load_resources do
  Window.loop do
    tick
  end
end
