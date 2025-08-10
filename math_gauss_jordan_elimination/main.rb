case RUBY_ENGINE
when "opal"  then require "dxopal"
when "jruby" then require "dxjruby"
else raise "unsupported engine (#{RUBY_ENGINE})"
end

WIN_W = 512
WIN_H = 512

C_LINE = [200, 0, 0, 0]

def gen_line_xs
  div = 256
  (0..div).to_a.map{ |x| (x.to_f / div) * 2 - 1 }
end

LINE_XS = gen_line_xs()

class Ball
  attr_reader :x, :y

  def initialize
    @x = rand * 2 - 1
    @y = rand * 2 - 1

    theta = Math::PI * 2 * rand()
    @dx = Math.sin(theta) * 0.005
    @dy = Math.cos(theta) * 0.005
  end

  def update
    @dx = -@dx if @x < -1 || @x > 1
    @dy = -@dy if @y < -1 || @y > 1
    @x += @dx
    @y += @dy
  end
end

def to_px_x(x)
  (x.to_f + 1) / 2 * WIN_W
end

def to_px_y(y)
  (1 - (y.to_f + 1) / 2) * WIN_H
end

# --------------------------------

def swap_row(m, ri_focused)
  max = 0
  max_ri = ri_focused

  (ri_focused...m.size).each{ |ri|
    v = m[ri][ri_focused].abs
    if v > max
      max = v
      max_ri = ri
    end
  }

  raise if max == 0

  # swap
  temp = m[ri_focused]
  m[ri_focused] = m[max_ri]
  m[max_ri] = temp

  m
end

def mult_sub(m, ri_self, ri_other)
  ci = ri_self
  # 自分の行
  row_self = m[ri_self]
  # 相手の係数
  c_other = m[ri_other][ci]
  # 相手の係数に合わせる
  row_self2 = row_self.map{ |v| v * c_other }

  row_temp = []
  row_self2.zip(m[ri_other])
    .each{ |v_self, v_other|
      row_temp << v_other - v_self
    }
  m[ri_other] = row_temp

  m
end

def proc_row(m, ri)
  m = swap_row(m, ri)

  # 自分の行を pivot で割る / m[ri][ri] を 1 にする
  v_pivot = m[ri][ri].to_f
  m[ri] = m[ri].map{ |v| v / v_pivot }

  ris_other = (0...(m.size)).to_a - [ri]
  ris_other.each{ |ri_other|
    m = mult_sub(m, ri, ri_other)
  }

  m
end

def gauss_jordan_elimination(m)
  (0...m.size).each{ |ri|
    m = proc_row(m, ri)
  }
  m
end

# --------------------------------

def draw_line?(pt1, pt2)
  (pt1[1] >= 0 || pt2[1] >= 0) &&
    (pt1[1] <= WIN_H || pt2[1] <= WIN_H)
end

def tick
  $balls.each{ |ball|
    ball.update
    Window.draw_circle_fill(to_px_x(ball.x), to_px_y(ball.y), 10, C_RED)
  }

  # make matrix
  m =
    $balls.map{ |ball|
      # [x^0, x^1, x^2, ..., x^(n-1), y]
      (0...$balls.size).to_a.map{ |i| ball.x ** i } + [ball.y]
    }

  begin
    m2 = gauss_jordan_elimination(m)

    # coefficient
    cs = m2.map{ |row| row.last }

    points = LINE_XS.map{ |x|
      # y = (c0 * x^0) + (c1 * x^1) + (c2 * x^2) + ...
      y = (0...cs.size).to_a
            .map{ |n| cs[n] * (x ** n) }
            .sum
      [x, y]
    }

    points
      .map{ |x, y| [to_px_x(x), to_px_y(y)] }
      .each_cons(2){ |pt1, pt2|
        if draw_line?(pt1, pt2)
          Window.draw_line(*pt1, *pt2, C_LINE)
        end
      }
  rescue => e
    p e
  end
end

# --------------------------------

Window.width  = WIN_W
Window.height = WIN_H
Window.fps = 30

Window.bgcolor = [245, 245, 245]

$balls = []
5.times {
  $balls << Ball.new
}

Window.load_resources do
  Window.loop do
    tick
  end
end
