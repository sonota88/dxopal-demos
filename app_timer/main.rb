case RUBY_ENGINE
when "opal"  then require "dxopal"
when "jruby" then require "dxjruby"
else raise "unsupported engine (#{RUBY_ENGINE})"
end

case RUBY_ENGINE
when "opal"  then require_remote   "utils.rb"
when "jruby" then require_relative "utils"
else raise "unsupported engine (#{RUBY_ENGINE})"
end

CELL_W = 48
WIN_W = CELL_W * 10
WIN_H = CELL_W * 8
FPS = 30

C_BLACK2 = [255, 40, 40, 40]

FONT = Font.new(18, "monospace")
FONT_L = Font.new(24, "monospace")

BUTTON_NAMES_TENKEY = 0.upto(9).map { |n| "btn_#{n}" } + ["btn_del"]

$input = [0, 0, 0, 0, 0, 0]
$buttons = []
$effects = []
$state = nil

# --------------------------------

# cell to pixel
def px(val)
  CELL_W * val
end

def add_effect(effect)
  $effects << effect
end

def format_hms(h, m, s)
  format("%02dh %02dm %02ds", h, m, s)
end

def input_to_hms(input)
  [
    input[0] * 10 + input[1],
    input[2] * 10 + input[3],
    input[4] * 10 + input[5]
  ]
end

def sec_to_hms(sec)
  hm, s = sec.round.divmod(60)
  h, m = hm.divmod(60)
  [h, m, s]
end

# --------------------------------

module State
  class Base
    def initialize
      update_buttons_state()
    end

    def update_buttons_state
      $buttons.each { |btn| btn.enabled = false }

      $buttons.each { |btn|
        if enabled_button_names.include?(btn.name)
          btn.enabled = true
        end
      }
    end

    def enabled_button_names
      ["btn_start", "btn_stop", "btn_reset", *BUTTON_NAMES_TENKEY]
    end

    def update() end

    def draw
      h, m, s = input_to_hms($input)
      draw_hms(h, m, s, C_BLACK2)
    end
  end

  class Input < Base
    def enabled_button_names
      [
        "btn_start",
        # "btn_stop",
        "btn_reset",
        *BUTTON_NAMES_TENKEY
      ]
    end
  end

  class Run < Base
    def initialize(sec)
      super()
      @t0 = Time.now
      @t_end = @t0 + sec
      @rest_sec = @t_end - @t0
    end

    def enabled_button_names
      [
        # "btn_start",
        "btn_stop",
        # "btn_reset",
        # *BUTTON_NAMES_TENKEY
      ]
    end

    def update
      @rest_sec = @t_end - Time.now

      if @rest_sec <= 0
        @rest_sec = 0
        $state = State::Ring.new
      end
    end

    def draw
      bar_width = 8 - 0.1
      rest_ratio = @rest_sec.to_f / (@t_end - @t0)

      x1 = px(1)
      y1 = px(2 - 0.3)
      y2 = px(2 - 0.1)

      Window.draw_box(
        x1, y1,
        px(1 + bar_width), y2,
        C_BLACK2
      )
      Window.draw_box_fill(
        x1, y1,
        px(1 + bar_width * rest_ratio), y2,
        C_BLACK2
      )

      h, m, s = sec_to_hms(@rest_sec)
      draw_hms(h, m, s, C_BLACK2)
    end
  end

  class Ring < Base
    def initialize
      super()
      @blink_flag = true
    end

    def update
      Timer.interval("ring_bell", 2) do
        SoundEffect[:se_ring].play
      end

      Timer.interval("ring_bell_blink", 0.5) do
        @blink_flag = !@blink_flag
      end
    end

    def enabled_button_names
      [
        # "btn_start",
        "btn_stop",
        # "btn_reset",
        # *BUTTON_NAMES_TENKEY
      ]
    end

    def draw
      draw_hms(0, 0, 0, color)
    end

    def color
      @blink_flag ? C_BLACK2 : [0, 0, 0, 0]
    end
  end
end

def draw_hms(h, m, s, color)
  Window.draw_font(
    px(1), px(2 + 0.1),
    format_hms(h, m, s),
    FONT_L, color: color
  )
end

# --------------------------------

tenkey_yi_offset = 3
[
  [1, 0, 7],
  [2, 0, 8],
  [3, 0, 9],
  [1, 1, 4],
  [2, 1, 5],
  [3, 1, 6],
  [1, 2, 1],
  [2, 2, 2],
  [3, 2, 3],
  [1, 3, 0],
].each { |xi, yi, n|
  $buttons << Button.new(
    px(xi), px(tenkey_yi_offset + yi),
    px(1 - 0.1), px(1 - 0.1),
    name: "btn_#{n}",
    label: "#{n}",
    callback: ->(btn){
      if $input[0] == 0
        $input.shift
        $input.push(n)
      end
    }
  )
}

$buttons << Button.new(
  px(3), px(tenkey_yi_offset + 3),
  px(1 - 0.1), px(1 - 0.1),
  name: "btn_del",
  label: "del",
  callback: ->(btn){
    $input.pop
    $input.unshift(0)
  }
)

$buttons << Button.new(
  px(5), px(3),
  px(4 - 0.1), px(1 - 0.1),
  name: "btn_start",
  label: "start",
  callback: ->(btn){
    sec = [
      $input[0] * 60 * 60 * 10,
      $input[1] * 60 * 60,
      $input[2] * 60 * 10,
      $input[3] * 60,
      $input[4] * 10,
      $input[5],
    ].sum

    $state = State::Run.new(sec)
  }
)

$buttons << Button.new(
  px(5), px(4),
  px(2 - 0.1), px(1 - 0.1),
  name: "btn_stop",
  label: "stop",
  callback: ->(btn){
    $state =
      case $state
      when State::Run  then State::Input.new
      when State::Ring then State::Input.new
      else $state
      end
  }
)

$buttons << Button.new(
  px(7), px(4),
  px(2 - 0.1), px(1 - 0.1),
  name: "btn_reset",
  label: "reset",
  callback: ->(btn){
    $input = [0, 0, 0, 0, 0, 0]
  }
)

# --------------------------------

Window.width = WIN_W
Window.height = WIN_H
Window.bgcolor = [240, 240, 240]
Window.fps = FPS

register_se_se1()
register_se_ring()

$state = State::Input.new

Window.load_resources do
  Window.loop do
    # input

    mx = Input.mouse_x
    my = Input.mouse_y

    if Input.mouse_push?(M_LBUTTON)
      clicked_button = $buttons.find { |btn|
        btn.inside?(mx, my)
      }
      if clicked_button
        clicked_button.run_callback()
      end
    end

    # update

    $state.update()

    # draw

    Window.draw_font(
      px(1), px(1),
      Time.now.strftime("%F %T"),
      FONT, color: C_BLACK2
    )

    $buttons.each { |it| Button.draw(it) }
    $effects.each { |it| Button.draw_effect(it) }
    $state.draw()

    # clean

    $effects.reject! { |it| it.vanish? }
  end
end
