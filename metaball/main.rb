require "dxopal"
include DXOpal

CELL_WIDTH = 8
CELL_WIDTH_HALF = CELL_WIDTH / 2.0
NUM_CELLS_X = 50
NUM_CELLS_Y = 50

# fixed ball center
FIXED_X = 160
FIXED_Y = 120

def calc_dist_sq(x1, y1, x2, y2)
  (x2 - x1) ** 2 + (y2 - y1) ** 2
end

def dist_to_z(dist)
  return 1 if dist < 1

  1.0 / dist
end

def in_metaball?(x, y, mx, my)
  dist1_sq = calc_dist_sq(x, y, FIXED_X, FIXED_Y)
  dist2_sq = calc_dist_sq(x, y, mx, my)

  z1 = dist_to_z(dist1_sq)
  z2 = dist_to_z(dist2_sq)

  0.0002 <= z1 + z2
end

def tick
  mx = Input.mouse_x
  my = Input.mouse_y

  (0...NUM_CELLS_Y).each { |cy|
    (0...NUM_CELLS_X).each { |cx|
      y = cy * CELL_WIDTH
      x = cx * CELL_WIDTH
      if in_metaball?(x + CELL_WIDTH_HALF, y + CELL_WIDTH_HALF, mx, my)
        Window.draw_box_fill(x, y, x + CELL_WIDTH, y + CELL_WIDTH, C_BLACK)
      end
    }
  }
end

# --------------------------------

Window.width = CELL_WIDTH * NUM_CELLS_X
Window.height = CELL_WIDTH * NUM_CELLS_Y
Window.fps = 20

Window.bgcolor = [240, 240, 240]

Window.load_resources do
  Window.loop do
    tick
  end
end
