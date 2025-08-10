case RUBY_ENGINE
when "opal"  then require "dxopal"
when "jruby" then require "dxjruby"
else raise "unsupported engine (#{RUBY_ENGINE})"
end

WIN_W = 400
WIN_H = 400

RING_R_MIN = 4

$rings = []
$t_drop = Time.now

def pre_tick
  if (
      (Input.key_down?(K_LCONTROL) && Input.key_push?(K_R)) ||
      (Input.key_down?(K_RCONTROL) && Input.key_push?(K_R)) ||
      Input.key_push?(K_F5)
    )
    `location.reload()`
  end
end

class Vec
  attr_reader :x, :y

  def initialize(x, y) @x, @y = x, y end

  def negate(v) Vec(-v.x, -v.y) end
  def +(v) Vec(@x + v.x, @y + v.y) end
  def -(v) self + negate(v) end
  def *(val) Vec(@x * val, @y * val) end
  def magnitude() Math.sqrt(@x ** 2 + @y ** 2) end
  def to_a() [@x, @y] end
end

def Vec(x, y) Vec.new(x, y) end

def circular_each_cons(xs)
  xs.each_cons(2) { |a, b| yield(a, b) }
  yield(xs[-1], xs[0])
end

class Ring
  attr_reader :points, :center, :r

  DURATION = 120.0

  def initialize(vec_c, r)
    @t_birth = Time.now
    @center = vec_c
    @r = r # radius

    num_points = 20 + r
    @points =
      (0...num_points)
        .map { |i|
          ratio = i.to_f / num_points
          rad = Math::PI * 2 * ratio
          px = @center.x + Math::sin(rad) * r
          py = @center.y + Math::cos(rad) * r
          Vec(px, py)
        }
  end

  def clean?
    @t_birth + DURATION < Time.now
  end

  def age_ratio
    (Time.now - @t_birth) / DURATION
  end

  # Dropping Paint
  # https://people.csail.mit.edu/jaffer/Marbling/Dropping-Paint
  def move(ring)
    @points = @points.map { |v_p|
      v_c = ring.center

      v_cp = v_p - v_c

      scale = Math.sqrt(
        1 + ( (ring.r ** 2) / (v_cp.magnitude ** 2) )
      )

      v_c + v_cp * scale
    }
  end

  INTERPOLATE_LIMIT_LO = RING_R_MIN
  INTERPOLATE_LIMIT_HI = RING_R_MIN * 2

  def interpolate
    new_points = []

    circular_each_cons(@points) { |pt1, pt2|
      new_points << pt1
      v_line = pt2 - pt1
      if INTERPOLATE_LIMIT_LO < v_line.magnitude && v_line.magnitude <= INTERPOLATE_LIMIT_HI
        new_points << (pt1 + pt2) * 0.5
      else
        # 間隔が狭い → 補完不要
        # 間隔が広すぎる → あきらめて放置
      end
    }
    @points = new_points
  end
end

def drop(vec_c)
  r = RING_R_MIN + rand(80)
  new_ring = Ring.new(vec_c, r)

  $rings.each { |ring|
    ring.move(new_ring)
    ring.interpolate() # optional
  }

  $rings << new_ring
end

def draw_ring(ring)
  alpha = (1.0 - ring.age_ratio) * 255
  color = [alpha, 0, 0, 0]
  diameter_min = RING_R_MIN * 2
  skipped = Set.new

  circular_each_cons(ring.points) { |pt1, pt2|
    length = (pt2 - pt1).magnitude
    if length < diameter_min
      Window.draw_line(*pt1.to_a, *pt2.to_a, color)
    else
      # 最低直径より広い → 輪をまたいでいる可能性が高いので描画をスキップ
      skipped << pt1
      skipped << pt2
    end
  }

  v_adj = Vec(0.5, 0.5)
  skipped.each { |pt|
    Window.draw_circle_fill(*((pt + v_adj).to_a), 0.75, color)
  }
end

# --------------------------------

def tick
  if $t_drop + 0.5 < Time.now
    $t_drop = Time.now
    drop(Vec(rand() * WIN_W, rand() * WIN_H))
  end

  $rings.each { |it| draw_ring(it) }
  $rings.reject! { |it| it.clean? }
end

Window.width  = WIN_W
Window.height = WIN_H
Window.fps = 10
Window.bgcolor = [240, 240, 240]

Window.load_resources do
  puts "load_resources ... done"

  Window.loop do
    pre_tick
    tick
  end
end
