require "dxopal"
include DXOpal

CELL_W = 40
NUM_CELLS_X = 8
NUM_CELLS_Y = 6
WINDOW_W = CELL_W * NUM_CELLS_X
WINDOW_H = CELL_W * NUM_CELLS_Y

THRESHOLD_LIST = [20, 30, 40, 120].map { |thres| thres ** 2 }

C_GRID = [30, 0, 0, 0]

def calc_height(x1, y1, x2, y2)
  (x2 - x1) ** 2 + (y2 - y1) ** 2
end

def update_height(mx, my)
  (0..NUM_CELLS_Y).each { |cy|
    (0..NUM_CELLS_X).each { |cx|
      # セルの原点
      y = cy * CELL_W
      x = cx * CELL_W
      $height_map[cy][cx] = calc_height(x, y, mx, my)
    }
  }
end

def draw_grid
  (0..NUM_CELLS_X).each { |x|
    Window.draw_line(
      x * CELL_W, 0,
      x * CELL_W, 480,
      C_GRID
    )
  }

  (0..NUM_CELLS_Y).each { |y|
    Window.draw_line(
      0, y * CELL_W,
      640, y * CELL_W,
      C_GRID
    )
  }
end

def _calc_ratio(low, high, thres)
  h_total = high - low
  h = thres - low # eliminate offset
  h.to_f / h_total
end

def calc_ratio(from, to, thres)
  if from < to
    _calc_ratio(from, to, thres)
  elsif to < from
    1.0 - _calc_ratio(to, from, thres)
  else
    raise "must not happen"
  end
end

def to_line(h_tl, h_tr, h_bl, h_br, thres)
  pattern = [
    thres <= h_tl,
    thres <= h_tr,
    thres <= h_bl,
    thres <= h_br
  ].map { |high| high ? "*" : "." }.join

  case pattern
  when ".*" +
       "**"
    x = calc_ratio(h_tl, h_tr, thres)
    y = calc_ratio(h_tl, h_bl, thres)
    [x, 0, 0, y]

  when "*." +
       "**"
    x = calc_ratio(h_tl, h_tr, thres)
    y = calc_ratio(h_tr, h_br, thres)
    [x, 0, 1, y]

  when "**" +
       ".*"
    x = calc_ratio(h_bl, h_br, thres)
    y = calc_ratio(h_tl, h_bl, thres)
    [x, 1, 0, y]

  when "**" +
       "*."
    x = calc_ratio(h_bl, h_br, thres)
    y = calc_ratio(h_tr, h_br, thres)
    [x, 1, 1, y]

  # --------

  when "*." +
       ".."
    x = calc_ratio(h_tl, h_tr, thres)
    y = calc_ratio(h_tl, h_bl, thres)
    [x, 0, 0, y]

  when ".*" +
       ".."
    x = calc_ratio(h_tl, h_tr, thres)
    y = calc_ratio(h_tr, h_br, thres)
    [x, 0, 1, y]

  when ".." +
       "*."
    x = calc_ratio(h_bl, h_br, thres)
    y = calc_ratio(h_tl, h_bl, thres)
    [x, 1, 0, y]

  when ".." +
       ".*"
    x = calc_ratio(h_bl, h_br, thres)
    y = calc_ratio(h_tr, h_br, thres)
    [x, 1, 1, y]

    # ----

  when ".." +
       "**"
    yl = calc_ratio(h_tl, h_bl, thres)
    yr = calc_ratio(h_tr, h_br, thres)
    [0, yl, 1, yr]

  when "**" +
       ".."
    yl = calc_ratio(h_tl, h_bl, thres)
    yr = calc_ratio(h_tr, h_br, thres)
    [0, yl, 1, yr]

  when ".*" +
       ".*"
    xt = calc_ratio(h_tl, h_tr, thres)
    xb = calc_ratio(h_bl, h_br, thres)
    [xt, 0, xb, 1]

  when "*." +
       "*."
    xt = calc_ratio(h_tl, h_tr, thres)
    xb = calc_ratio(h_bl, h_br, thres)
    [xt, 0, xb, 1]

  else
    p_ ds: [h_tl, h_tr, h_bl, h_br], thres: thres
    raise "must not happen"
  end
end

def draw_contour(thres)
  (0...NUM_CELLS_Y).each { |cy|
    (0...NUM_CELLS_X).each { |cx|
      h_tl = $height_map[cy][cx]
      h_tr = $height_map[cy][cx + 1]
      h_bl = $height_map[cy + 1][cx]
      h_br = $height_map[cy + 1][cx + 1]

      hs = [h_tl, h_tr, h_bl, h_br]

      if hs.all? { |h| h <= thres }
        # no need to draw
      elsif hs.all? { |h| thres <= h }
        # no need to draw
      else
        rx1, ry1, rx2, ry2 = to_line(*hs, thres)
        Window.draw_line(
          CELL_W * (cx + rx1), CELL_W * (cy + ry1),
          CELL_W * (cx + rx2), CELL_W * (cy + ry2),
          C_BLACK
        )
      end
    }
  }
end

def tick
  update_height(Input.mouse_x, Input.mouse_y)
  draw_grid if `window.showGrid`
  THRESHOLD_LIST.each { |thres| draw_contour(thres) }
end

# --------------------------------

$height_map = []
(0..NUM_CELLS_Y).each { |cy|
  $height_map[cy] = []
  (0..NUM_CELLS_X).each { |cx|
    $height_map[cy][cx] = 0
  }
}

Window.width = WINDOW_W
Window.height = WINDOW_H
Window.fps = 30
Window.bgcolor = [240, 240, 240]

Window.load_resources do
  Window.loop do
    tick
  end
end
