class Button
  attr_reader :x, :y, :w, :h
  attr_reader :name, :label
  attr_accessor :enabled

  def initialize(x, y, w, h, name:, label:, callback:)
    @x, @y, @w, @h = [x, y, w, h]
    @name = name
    @label = label
    @callback = callback
    @enabled = true
  end

  def inside?(x, y)
    return false if x < @x
    return false if y < @y
    return false if x > @x + @w
    return false if y > @y + @h

    true
  end

  def run_callback
    return unless @enabled

    SoundEffect[:se1].play
    @callback.call(self)
    add_effect ButtonClickEffect.from_button(self)
  end

  def self.draw(btn)
    alpha_ratio = btn.enabled ? 1.0 : 0.3

    x2 = btn.x + btn.w
    y2 = btn.y + btn.h
    Window.draw_box_fill(
      btn.x, btn.y,
      x2, y2,
      [255 * alpha_ratio, 255, 255, 255]
    )
    Window.draw_box_fill(
      btn.x + 2, btn.y + 2,
      x2, y2,
      [30 * alpha_ratio, 0, 0, 0]
    )

    c_black2 = [255 * alpha_ratio, 40, 40, 40]
    Window.draw_box(
      btn.x, btn.y,
      x2, y2,
      c_black2
    )
    Window.draw_font(btn.x + 4, btn.y + 4, btn.label, FONT, { color: c_black2 })
  end

  def self.draw_effect(eff)
    alpha = 60 * (1.0 - eff.ratio)
    alpha = [alpha, 0].max
    Window.draw_box_fill(
      eff.x, eff.y,
      eff.x + eff.w, eff.y + eff.h,
      [alpha, 0, 0, 0]
    )
  end
end

class ButtonClickEffect
  DURATION = 0.25

  attr_reader :x, :y, :w, :h # px

  def initialize(x, y, w, h)
    @x, @y, @w, @h = [x, y, w, h]
    @t_start = Time.now
  end

  def self.from_button(btn)
    new(btn.x, btn.y, btn.w, btn.h)
  end

  def vanish?
    @t_start + DURATION <= Time.now
  end

  def ratio
    (Time.now - @t_start) / DURATION
  end
end

# --------------------------------

class Timer
  @@map = {}

  def self.interval(name, interval_sec)
    t_now = Time.now

    unless @@map.key?(name)
      @@map[name] = t_now
    end
    t_next = @@map[name]

    if t_next <= t_now
      @@map[name] = t_now + interval_sec
      yield
    end
  end
end

# --------------------------------

def register_se_se1
  SoundEffect.register(:se1, 50, WAVE_TRI) do
    [440, 5]
  end
end

def register_se_ring
  i = 0
  vol = 20
  interval = 80
  freq = 880
  SoundEffect.register(:se_ring, 1000, WAVE_TRI) do
    i += 1
    msec = i

    if    msec < interval * 1 then [freq, vol]
    elsif msec < interval * 2 then [freq, 0]
    elsif msec < interval * 3 then [freq, vol]
    elsif msec < interval * 4 then [freq, 0]
    elsif msec < interval * 5 then [freq, vol]
    elsif msec < interval * 6 then [freq, 0]
    elsif msec < interval * 7 then [freq, vol]
    elsif msec < interval * 8 then [freq, 0]
    else
      [880, 0]
    end
  end
end
