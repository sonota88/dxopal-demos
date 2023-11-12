require "dxopal"
include DXOpal
include Math

C_GRID = [200, 200, 200]

WIN_W = 512
WIN_H = 512
PI2 = PI * 2
DIV = 32

FONT_SPECTRUM = Font.new(12, "monospace")

# pi2, pi2/2, pi2/3, ... pi2/(DIV/2)
CYCLES = (1..(DIV / 2)).map{ |n| PI2 / n }

class Plot
  X_MIN = 0
  X_MAX = PI2
  X_W = X_MAX - X_MIN

  Y_MIN = -2
  Y_MAX = 2
  Y_W = Y_MAX - Y_MIN

  X_MIN_PX = 100
  X_MAX_PX = WIN_W - 20
  X_W_PX = X_MAX_PX - X_MIN_PX

  Y_MIN_PX = 0
  Y_MAX_PX = WIN_H - 1
  Y_W_PX = Y_MAX_PX - Y_MIN_PX

  def self.to_px_x(x)
    ratio = (x.to_f - X_MIN) / X_W
    ratio_to_x_px(ratio)
  end

  def self.ratio_to_x_px(ratio)
    ratio * X_W_PX + X_MIN_PX
  end

  def self.to_px_y(y)
    ratio = (y.to_f - Y_MIN) / Y_W
    (1 - ratio) * WIN_H
  end

  def self.from_px_x(px_x)
    ratio = (px_x.to_f - X_MIN_PX) / X_W_PX
    ratio_to_x(ratio)
  end

  def self.ratio_to_x(ratio)
    ratio * X_W + X_MIN
  end

  def self.from_px_y(px_y)
    ratio = (px_y - Y_MIN_PX) / Y_W_PX
    (1 - ratio) * Y_W + Y_MIN
  end
end

# 0 ~ PI2
XS = []
(0...DIV).each_with_index{ |_, i|
  ratio = (i + 0.5) / DIV
  XS << Plot::X_W * ratio
}

def pre_tick
  if (
      (Input.key_down?(K_LCONTROL) && Input.key_push?(K_R)) ||
      (Input.key_down?(K_RCONTROL) && Input.key_push?(K_R)) ||
      Input.key_push?(K_F5)
    )
    `location.reload()`
  end
end

# --------------------------------

def gen_samples
  (0..DIV)
    .map{ |i|
      ratio = i.to_f / DIV
      yield(ratio, ratio * PI2)
    }
end

def gen_samples_zero
  gen_samples{ |_, _| 0 }
end

def gen_samples_sine
  gen_samples{ |_, x| Math.sin(x) }
end

def gen_samples_sq
  gen_samples{ |ratio, _| ratio < 0.5 ? 1 : -1 }
end

def gen_samples_tri
  gen_samples{ |ratio, _|
    r4 = ratio * 4
    if    r4 < 1 then  r4
    elsif r4 < 3 then -r4 + 2
    else               r4 - 4
    end
  }
end

def gen_samples_saw
  gen_samples{ |ratio, _| -2 * ratio + 1 }
end

# --------------------------------

def x_to_sample_index(x)
  if x < Plot::X_MIN
    return nil
  elsif x > Plot::X_MAX
    return nil
  else
    ratio = (x - Plot::X_MIN) / Plot::X_W
    (DIV * ratio).floor
  end
end

def sample_index_to_x(i)
  ratio = (i.to_f + 0.5) / DIV
  Plot.ratio_to_x(ratio)
end

def draw_sample(x, y, color = [120, 120, 120])
  x_px = Plot.to_px_x(x)
  y_px = Plot.to_px_y(y)
  w = Plot::X_W_PX.to_f / DIV
  w_half = w / 2
  x_px2_1 = x_px - w_half
  Window.draw_box_fill(
    x_px2_1,
    y_px - 1,
    x_px2_1 + w,
    y_px + 1,
    color
  )
  Window.draw_circle_fill(
    x_px2_1 + w_half,
    y_px,
    3,
    color
  )
end

class Param
  attr_reader :sin, :cos, :cycle

  def initialize(sin, cos, cycle)
    @sin = sin
    @cos = cos
    @cycle = cycle
  end

  def inspect
    format("(%.2f, %.2f)", @sin, @cos)
  end

  def sum
    @sin.abs + @cos.abs
  end
end

def draw_wave
  avg = $samples.sum / $samples.size.to_f

  w_quad = PI2 / DIV / 4
  xs2 = []
  XS.each{ |x|
    (-2..1).each{ |n|
      xs2 << x + w_quad * n
    }
  }
  xs2 << Plot::X_MAX

  ys =
    xs2.map{ |x|
      y = avg
      $params.each{ |amp|
        c_inv = PI2 / amp.cycle
        y += Math.sin(c_inv * x) * amp.sin + Math.cos(c_inv * x) * amp.cos
      }
      y
    }

  xs2.zip(ys).each_cons(2){ |xy1, xy2|
    x1, y1 = xy1
    x2, y2 = xy2
    Window.draw_line(
      Plot.to_px_x(x1), Plot.to_px_y(y1),
      Plot.to_px_x(x2), Plot.to_px_y(y2),
      [250, 0, 0]
    )
  }
end

def draw_spectrum
  yw = 20

  $params.each_with_index{ |amp, i|
    y = i * yw
    Window.draw_box_fill(0, y, amp.sum * 80, y + 20, [60, 0, 0,0])
    Window.draw_font(
      2, y + 4,
      format("% 2d: %.2f", PI2 / amp.cycle, amp.sum),
      FONT_SPECTRUM,
      color: C_BLACK
    )
  }
end

def draw_grid
  [0, PI, PI2].each{ |x|
    x_px = Plot.to_px_x(x)
    Window.draw_line(x_px, 0, x_px, WIN_H, C_GRID)
  }

  # y = 0
  Window.draw_line(0, WIN_H / 2, WIN_W, WIN_H / 2, C_GRID)
end

def draw_cursor(mx, my)
  x = Plot.from_px_x(mx)
  y = Plot.from_px_y(my)
  i = x_to_sample_index(x)
  if i
    x2 = sample_index_to_x(i)
    draw_sample(x2, y, [100, 200, 200, 200])
  end
end

def fourier_transform(samples)
  slice_w = Plot::X_W / DIV.to_f

  # 振幅=1 の場合の積分結果を基準とする
  area_base = PI

  CYCLES
    .map{ |cycle|
      c_inv = PI2 / cycle

      area = 0
      XS.zip(samples).each{ |x, y|
        h = y * Math.sin(c_inv * x)
        area += h * slice_w
      }
      amp_sin = area / area_base

      area = 0
      XS.zip(samples).each{ |x, y|
        h = y * Math.cos(c_inv * x)
        area += h * slice_w
      }
      amp_cos = area / area_base

      Param.new(amp_sin, amp_cos, cycle)
    }
end

def tick
  if Input.mouse_down?(M_LBUTTON)
    mx = Input.mouse_x
    my = Input.mouse_y
    if 0 <= my && my < WIN_H
      x = Plot.from_px_x(mx)
      y = Plot.from_px_y(my)

      ratio = (x - Plot::X_MIN) / Plot::X_W
      i = x_to_sample_index(x)

      if i
        $samples[i] = y
      end
    end
  end

  $params = fourier_transform($samples)

  draw_grid()
  XS.zip($samples).each{ |x, y| draw_sample(x, y) }
  draw_cursor(Input.mouse_x, Input.mouse_y)
  draw_wave()
  draw_spectrum()
end

# --------------------------------

Window.width  = WIN_W
Window.height = WIN_H
Window.fps = 30

Window.bgcolor = [245, 245, 245]

# $samples = gen_samples_zero()
# $samples = gen_samples_sine()
# $samples = gen_samples_sq()
# $samples = gen_samples_tri()
$samples = gen_samples_saw()

$params = nil

Window.load_resources do
  Window.loop do
    pre_tick()
    tick()
  end
end
