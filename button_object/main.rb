require "dxopal"
include DXOpal

WIN_W = 512
WIN_H = 400

C_BLACK2 = [255, 40, 40, 40]
FONT = Font.new(12, "monospace")

$log = []

def log(msg)
  msg2 = format("%s  %s", Time.now.strftime("%T.%L"), msg)
  puts msg2
  $log << msg2
  if $log.size > 20
    $log.shift
  end
end

class Button
  attr_reader :x, :y, :w, :h
  attr_reader :name, :label

  def initialize(x, y, w, h, name:, label:, callback:)
    @x, @y, @w, @h = [x, y, w, h]
    @name = name
    @label = label
    @callback = callback
  end

  def inside?(x, y)
    return false if x < @x
    return false if y < @y
    return false if x > @x + @w
    return false if y > @y + @h

    true
  end

  def run_callback
    @callback.call(self)
    $game.add_effect ButtonClickEffect.from_button(self)
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

def pre_tick
  if (
      (Input.key_down?(K_LCONTROL) && Input.key_push?(K_R)) ||
      (Input.key_down?(K_RCONTROL) && Input.key_push?(K_R)) ||
      Input.key_push?(K_F5)
    )
    `location.reload()`
  end
end

class Game
  def initialize
    @buttons = [
      Button.new(
        8, 8, 80, 20,
        name: "btn1", label: "button 1",
        callback: ->(btn){
          log "clicked: #{btn.name} #{btn.inspect}"
        }
      ),
      Button.new(
        100, 8, 80, 20,
        name: "btn2", label: "button 2",
        callback: ->(btn){
          log "clicked:   #{btn.name} #{btn.inspect}"
        }
      )
    ]

    @effects = []
  end

  def add_effect(eff)
    @effects << eff
  end

  def draw_log
    y = 36
    $log.reverse_each{ |msg|
      Window.draw_font(4, y, msg, FONT, { color: C_BLACK2 })
      y += 20
    }
  end

  def draw_button(btn)
    x2 = btn.x + btn.w
    y2 = btn.y + btn.h
    Window.draw_box_fill(
      btn.x, btn.y,
      x2, y2,
      [255, 255, 255, 255]
    )
    Window.draw_box_fill(
      btn.x + 2, btn.y + 2,
      x2, y2,
      [30, 0, 0, 0]
    )
    Window.draw_box(
      btn.x, btn.y,
      x2, y2,
      C_BLACK2
    )
    Window.draw_font(btn.x + 4, btn.y + 4, btn.label, FONT, { color: C_BLACK2 })
  end

  def draw_effect(eff)
    alpha = 60 * (1.0 - eff.ratio)
    Window.draw_box_fill(
      eff.x, eff.y,
      eff.x + eff.w, eff.y + eff.h,
      [alpha, 0, 0, 0]
    )
  end

  def tick
    if Input.mouse_push?(M_LBUTTON)
      clicked_button = @buttons.find { |btn|
        btn.inside?(Input.mouse_x, Input.mouse_y)
      }
      if clicked_button
        # ボタンがクリックされた
        clicked_button.run_callback()
      else
        # ボタン以外の場所がクリックされた
      end
    end

    # draw
    draw_log()
    @buttons.each { |it| draw_button(it) }
    @effects.each { |it| draw_effect(it) }

    # clean
    @effects.reject! { |it| it.vanish? }
  end
end

# --------------------------------

Window.width  = WIN_W
Window.height = WIN_H
Window.bgcolor = [245, 245, 245]
Window.fps = 60

$game = Game.new

Window.load_resources do
  Window.loop do
    pre_tick
    $game.tick
  end
end
