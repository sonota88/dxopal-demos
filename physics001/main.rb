case RUBY_ENGINE
when "opal"  then require "dxopal"
when "jruby" then require "dxjruby"
else raise "unsupported engine (#{RUBY_ENGINE})"
end

FPS = 60
DT_BASE = 1.0 / 60.0
$dt = DT_BASE

WIN_W = 240
WIN_H = 400

FONT_DEBUG = Font.new(10, "monospace")
C_PARTICLE = [20, 20, 20]
NUM_PARTICLES = 5

# --------------------------------

def pre_tick
  if (
      (Input.key_down?(K_LCONTROL) && Input.key_push?(K_R)) ||
      (Input.key_down?(K_RCONTROL) && Input.key_push?(K_R)) ||
      Input.key_push?(K_F5)
    )
    `location.reload()`
  end
end

class Vector
  attr_reader :x, :y
  attr_writer :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def +(v) Vec(@x + v.x, @y + v.y) end
  def -(v) Vec(@x - v.x, @y - v.y) end

  def *(val) Vec(@x * val, @y * val) end
  def /(val) Vec(@x / val, @y / val) end

  def magnitude
    Math.sqrt(magnitude_sq)
  end

  def magnitude_sq
    @x ** 2 + @y ** 2
  end

  def normalize
    self / magnitude()
  end

  def inspect
    "(vec #{@x}, #{@y})"
  end
end

def Vec(x, y)
  Vector.new(x, y)
end

class Ball
  R = 10 # radius

  attr_reader :pos   # position
  attr_accessor :vel # velocity

  def initialize(x, y)
    @pos = Vec(x, y)
    @vel = Vec(1, 1)
    @vel_ratio = 1
  end

  def x() @pos.x end
  def y() @pos.y end
  def x=(val) @pos.x = val end
  def y=(val) @pos.y = val end

  def update
    @pos = @pos + (@vel * @vel_ratio * $dt_ratio)
  end

  def change_vel_ratio
    @vel_ratio = 0.1 + rand()
  end
end

class Particle
  R = 50

  attr_accessor :pos
  attr_accessor :pos_prev
  attr_accessor :vel
  attr_accessor :disp # displacement

  def initialize(pos)
    @pos = pos
    @pos_prev = pos
    @vel = Vec(0, 0)
    @disp = Vec(0, 0)
  end

  def x() @pos.x end
  def y() @pos.y end
  def x=(val) @pos.x = val end
  def y=(val) @pos.y = val end

  def add_disp(v)
    @disp = @disp + v
  end

  def reset_pos_prev
    @pos_prev = @pos.dup
  end

  def inspect
    ["(Particle", @pos.inspect, @vel.inspect, ")"].join(" ")
  end
end

module Simulation
  V_GRAVITY = Vec(0, 0.01)
  VEL_DAMPING = 0.99

  def self.apply_gravity(particles, dt)
    particles.each { |pt|
      pt.vel = pt.vel + (V_GRAVITY * dt)
    }
  end

  def self.predict_positions(particles, dt)
    particles.each { |pt|
      pt.reset_pos_prev()
      pos_delta = pt.vel * dt * VEL_DAMPING
      pt.pos = pt.pos + pos_delta
    }
  end

  def self.relax_particles(particles)
    int_r = Particle::R * 2 # interaction radius
    int_r_sq = int_r ** 2

    particles.each { |pt1|
      particles.each { |pt2|
        next if pt1 == pt2

        v12 = pt2.pos - pt1.pos # pt1 => pt2
        mag_sq = v12.magnitude_sq()
        if mag_sq < int_r_sq
          mag = Math.sqrt(mag_sq)
          ratio = mag / int_r # 近いと 0
          # ratio = ratio * ratio
          ratio_inv = 1.0 - ratio # 近いと 1
          v12_norm = v12.normalize

          # pt1 => pt2
          pt2.disp = pt2.disp + (v12_norm * ratio_inv)
          # pt1 <= pt2
          pt1.disp = pt1.disp - (v12_norm * ratio_inv)
        end
      }
    }
  end

  def self.relax_ball(particles, ball)
    int_r = Ball::R + Particle::R
    int_r_sq = int_r * int_r
    particles.each { |pt2|
      v12 = pt2.pos - ball.pos # ball => pt2
      mag_sq = v12.magnitude_sq()
      if mag_sq < int_r_sq
        mag = Math.sqrt(mag_sq)
        ratio = mag / int_r
        ratio_inv = 1.0 - ratio
        v12_norm = v12.normalize

        # ball => pt2
        pt2.disp = pt2.disp + (v12_norm * ratio_inv)
      end
    }
  end

  def self.relax(particles, ball)
    particles.each { |pt|
      pt.disp = Vec(0, 0)
    }
    relax_particles(particles)
    relax_ball(particles, ball)
    particles.each { |pt|
      pt.pos = pt.pos + pt.disp
    }
  end

  def self.world_boundary(particles)
    x_min = Particle::R
    y_min = Particle::R
    x_max = WIN_W - Particle::R
    y_max = WIN_H - Particle::R

    particles.each { |pt|
      if pt.x < x_min
        temp = pt.pos.x
        pt.pos.x = pt.pos_prev.x
        pt.pos_prev.x = temp
      end
      if pt.y < y_min
        temp = pt.pos.y
        pt.pos.y = pt.pos_prev.y
        pt.pos_prev.y = temp
      end

      if pt.x > x_max
        temp = pt.pos.x
        pt.pos.x = pt.pos_prev.x
        pt.pos_prev.x = temp
      end
      if pt.y > y_max
        temp = pt.pos.y
        pt.pos.y = pt.pos_prev.y
        pt.pos_prev.y = temp
      end
    }
  end

  def self.compute_next_velocity(particles, dt)
    particles.each { |pt|
      new_vel = (pt.pos - pt.pos_prev) / dt
      pt.vel = new_vel
    }
  end
end

class Game
  def initialize
    @ball = Ball.new(
      20 + rand(50),
      20 + rand(50)
    )

    pr = Particle::R
    @particles =
      (0...NUM_PARTICLES).map { |_|
        Particle.new(
          Vec(
            pr + rand * (WIN_W - pr * 2),
            pr + rand * (WIN_H - pr * 2)
          )
        )
      }

    @t_ball_next = Time.now + 4

    @fps_samples = [FPS]
    @fps_avg = format("%.1f", @fps_samples[0])
  end

  def update_ball_auto
    x_min = Ball::R
    y_min = Ball::R
    x_max = WIN_W - Ball::R
    y_max = WIN_H - Ball::R

    if @ball.x < x_min
      @ball.x = x_min
      @ball.vel = Vec(-@ball.vel.x, @ball.vel.y)
    end
    if @ball.y < y_min
      @ball.y = y_min
      @ball.vel = Vec(@ball.vel.x, -@ball.vel.y)
    end

    if @ball.x > x_max
      @ball.x = x_max
      @ball.vel = Vec(-@ball.vel.x, @ball.vel.y)
    end
    if @ball.y > y_max
      @ball.y = y_max
      @ball.vel = Vec(@ball.vel.x, -@ball.vel.y)
    end

    @ball.update
  end

  def update_ball(x, y)
    @ball.x = x
    @ball.y = y
  end

  def draw_particle(particle)
    Window.draw_circle_fill(particle.x, particle.y, Particle::R, C_PARTICLE)
  end

  def draw_ball(ball)
    Window.draw_circle_fill(ball.x, ball.y, Ball::R, C_RED)
  end

  def tick
    mx = Input.mouse_x
    my = Input.mouse_y
    if (0 < mx && mx < WIN_W) && (0 < my && my < WIN_H)
      update_ball(mx, my)
    else
      update_ball_auto()
    end

    if @t_ball_next < Time.now
      @t_ball_next = Time.now + 2 + rand(4)
      @ball.change_vel_ratio()
    end

    # このあたりの処理の骨組みは以下を参考にしています
    # https://gitlab.com/Marcel.K/tutorials/-/blob/main/2D%20Particle%20Based%20Viscoelastic%20Fluid%20Simulation/07.%20Double%20Density%20Relaxation/Simulation.js

    # update velocity
    Simulation.apply_gravity(@particles, $dt_ratio)

    # pos => posPrev
    # update pos
    Simulation.predict_positions(@particles, $dt_ratio)

    # relax
    Simulation.relax(@particles, @ball)

    # update pos, posPrev
    Simulation.world_boundary(@particles)

    # update velocity (using pos - posPrev)
    Simulation.compute_next_velocity(@particles, $dt_ratio)

    @particles.each { |pt| draw_particle(pt) }
    draw_ball(@ball)

    if rand < 0.05
      @fps_samples << Window.real_fps
      @fps_samples.shift if @fps_samples.size > 100

      avg = @fps_samples.sum / @fps_samples.size
      @fps_avg = format("%.1f", avg)
    end
    # Window.draw_font(4, 4, "#{@fps_avg} fps", FONT_DEBUG, color: [0,0,0])
  end
end

# --------------------------------

Window.width  = WIN_W
Window.height = WIN_H
Window.fps = FPS
Window.bgcolor = [240, 240, 240]

Window.load_resources do
  puts "load_resources ... done"

  $game = Game.new
  t0 = Time.now

  Window.loop do
    now = Time.now
    $dt = now - t0
    $dt_ratio = $dt / DT_BASE * 2
    t0 = now

    begin
      pre_tick
      $game.tick
    rescue => e
      puts e
      # puts e.backtrace
      puts "----"
      e.backtrace.each { |bt| puts bt }
      puts "----"
      raise e
    end
  end
end
