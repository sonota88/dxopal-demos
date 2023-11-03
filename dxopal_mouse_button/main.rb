require "dxopal"
include DXOpal

WIN_W = 512
WIN_H = 400

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

class MouseButton
  def initialize(code)
    @code = code
    @state = :up
    @state_prev = :up
    @pushed = false
  end

  def update
    @state_prev = @state
    @state = Input.mouse_down?(@code) ? :down : :up

    @pushed =
      case @state_prev
      when :up
        case @state
        when :down
          true
        else
          false
        end
      else
        false
      end
  end

  def push?
    @pushed
  end

  def dump
    {
      state_prev: @state_prev,
      state: @state,
      pushed: @pushed
    }.inspect
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

def tick
  Window.draw_box_fill(0, 0, WIN_W, 12, [20, 0, 0, 0])

  line0 =
    if Input.mouse_down?(M_LBUTTON)
      "down:     true"
    else
      "down: false"
    end
  Window.draw_font(0, 0, line0, FONT, { color: [0, 0, 0] })

  y = 20
  $log.reverse_each{ |msg|
    Window.draw_font(0, y, msg, FONT, { color: [0, 0, 0] })
    y += 20
  }

  if $mbtn_l.push?
    log "push"
  elsif Input.mouse_release?(M_LBUTTON)
    log "    release"
  end
end

# --------------------------------

Window.width  = WIN_W
Window.height = WIN_H
Window.bgcolor = [245, 245, 245]
Window.fps = 60

$mbtn_l = MouseButton.new(M_LBUTTON)

Window.load_resources do
  Window.loop do
    $mbtn_l.update
    pre_tick
    tick
  end
end
