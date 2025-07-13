case RUBY_ENGINE
when "opal"  then require "dxopal"
when "jruby" then require "dxjruby"
else
  raise "unsupported engine (#{RUBY_ENGINE})"
end

WIN_W = 640
WIN_H = 480

class Box
  attr_reader :x1, :y1, :x2, :y2

  def initialize
    w = 50
    @x1, @y1 = 10, 20
    @x2, @y2 = @x1 + w, @y1 + w
  end

  def move(dx, dy)
    @x1 += dx
    @y1 += dy
    @x2 += dx
    @y2 += dy
  end

  def include?(x, y)
    @x1 <= x && x <= @x2 \
    && @y1 <= y && y <= @y2
  end
end

def box_color(dragging, focused)
  c_box =
    if dragging
      C_BOX_FOCUSED
    else
      if focused
        C_BOX_FOCUSED
      else
        C_BOX
      end
    end

  alpha = dragging ? 120 : 255

  [alpha] + c_box
end

def format_bool(b)
  b.to_s.ljust(5)
end

C_BOX         = [100, 100, 100]
C_BOX_FOCUSED = [50, 150, 250]
FONT = Font.new(16, "monospace")

Window.width = WIN_W
Window.height = WIN_H
Window.bgcolor = [240, 240, 240]

box = Box.new

mx_prev = nil
my_prev = nil
dragging = false

Window.load_resources do
  Window.loop do
    mx = Input.mouse_x
    my = Input.mouse_y
    dx, dy =
      if mx_prev
        [mx - mx_prev, my - my_prev]
      else
        # for first tick
        [0, 0]
      end
    mx_prev = mx
    my_prev = my

    focused = box.include?(mx, my)

    if Input.mouse_down?(M_LBUTTON)
      if focused
        dragging = true
      else
        # keep
      end
    else
      dragging = false
    end

    if dragging
      box.move(dx, dy)
    end

    c_box = box_color(dragging, focused)

    Window.draw_box_fill(
      box.x1, box.y1,
      box.x2, box.y2,
      c_box
    )

    Window.draw_font(
      10, 10,
      format(
        "focused (%s) / down? (%s) / dragging (%s)",
        format_bool(focused), 
        format_bool(Input.mouse_down?(M_LBUTTON)),
        format_bool(dragging)
      ),
      FONT, color: C_BLACK
    )
  end
end
