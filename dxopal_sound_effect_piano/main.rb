require "dxopal"
include DXOpal

WIN_W = 480
WIN_H = 120

NUM_KEYS = 13

class PianoKey
  KEYCODES = [
    K_A, # c
    K_W,
    K_S, # d
    K_E,
    K_D, # e
    K_F, # f
    K_T,
    K_G, # g
    K_Y,
    K_H, # a
    K_U,
    K_J, # b
    K_K, # c
  ]

  attr_reader :id, :type, :se_name, :pushed

  def initialize(id, type)
    @id = id
    @type = type # :white | :black
    @keycode = KEYCODES[id]
    @se_name = "se#{@id}"

    @key_down_prev = nil
    @key_down = nil
    @mouse_down_prev = nil
    @mouse_down = nil

    @pushed = false
  end

  def update(mouse_down_pkey_id)
    @key_down_prev = @key_down
    @mouse_down_prev = @mouse_down

    @key_down = Input.key_down?(@keycode)
    @mouse_down = (@id == mouse_down_pkey_id)

    @pushed =
      if @mouse_down && (@mouse_down_prev != @mouse_down)
        true
      elsif @key_down && (@key_down_prev != @key_down)
        true
      else
        false
      end
  end

  def down?
    @key_down || @mouse_down
  end
end

def get_mouse_down_pkey_id
  if Input.mouse_down?(M_LBUTTON)
    mx = Input.mouse_x
    my = Input.mouse_y

    if 0 <= mx && mx < WIN_W && 0 <= my && my < WIN_H
      ratio = mx.to_f / WIN_W
      (ratio * NUM_KEYS).floor
    else
      nil
    end
  else
    nil
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
  mouse_down_pkey_id = get_mouse_down_pkey_id()

  $pkeys.each{ |pkey|
    pkey.update(mouse_down_pkey_id)
  }

  $pkeys.each{ |pkey|
    i = pkey.id
    x1 = (i.to_f / NUM_KEYS.to_f) * WIN_W
    x2 = ((i + 1).to_f / NUM_KEYS.to_f) * WIN_W - 1

    color =
      case pkey.type
      when :white then [255, 255, 255]
      when :black then [0, 0, 0]
      else
        raise "must not happen"
      end

    y_max = WIN_H - 1

    Window.draw_box_fill(
      x1, 0,
      x2, y_max,
      color
    )
    Window.draw_box(
      x1, 0,
      x2, y_max,
      [0, 0, 0]
    )

    if pkey.down?
      Window.draw_box_fill(
        x1, 0,
        x2, y_max,
        [100, 255, 0, 0]
      )
    end
  }

  $pkeys
    .select{ |pkey| pkey.pushed }
    .each{ |pkey| SoundEffect[pkey.se_name].play }
end

# --------------------------------

Window.width  = WIN_W
Window.height = WIN_H
Window.fps = 60
Window.bgcolor = [245, 245, 245]

$pkeys =
  (0...NUM_KEYS).map{ |i|
    type = [1, 3, 6, 8, 10].include?(i) ? :black : :white
    PianoKey.new(i, type)
  }

$pkeys.each{ |pkey|
  note_no = pkey.id - 9 # 440Hz == 0
  freq = (440 * (2 ** (note_no / 12.0))).to_f
  vol = 50
  duration_msec = 2_000

  SoundEffect.register(pkey.se_name, duration_msec, WAVE_TRI) do
    if vol > 3
      vol -= 0.3
    elsif vol < 0
      vol = 0
    else
      vol -= 0.0015
    end

    [freq, vol]
  end
}

Window.load_resources do
  puts "load_resources ... done"

  Window.loop do
    pre_tick
    tick
  end
end
