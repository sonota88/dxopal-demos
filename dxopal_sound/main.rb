case RUBY_ENGINE
when "ruby"
  require 'dxruby'; include DXRuby

  SoundWrapper = DXRuby::Sound

  module Window
    def self.load_resources
      yield
    end
  end
when "opal"
  require 'dxopal'; include DXOpal

  class SoundWrapper
    @@id_max = 0

    def initialize(path_or_url)
      @@id_max += 1
      @name = "snd_#{@@id_max}"
      Sound.register(@name, path_or_url)
    end

    def _get() Sound[@name] end
    def play() _get.play end
    def stop() _get.stop end

    def set_volume(volume, time=0)
      _get.set_volume($master_volume.call(volume), time)
    end
  end
else
  raise "unsupported ruby engine (#{RUBY_ENGINE})"
end

# --------------------------------

BUTTON_H = 40
BUTTONS = [
  { name: "dxruby_compat" },
  { name: "stop" },
  { name: "volume_265", vol: 265 },
  { name: "volume_255", vol: 255 },
  { name: "volume_230", vol: 230 },
  { name: "volume_191", vol: 191 },
  { name: "volume_127", vol: 127 },
  { name: "volume_95" , vol:  95 },
  { name: "volume_63" , vol:  63 },
  { name: "volume_0"  , vol:   0 },
  { name: "volume_-10", vol: -10 },
]

WIN_W = 400
WIN_H = BUTTON_H * BUTTONS.size

FONT_MAIN = Font.new(14, "monospace")

def adjust_from_dxruby_volume(dxruby_vol)
  slope = 1.033203
  intercept = -27.21
  dxopal_vol = slope * dxruby_vol + intercept
  dxopal_vol < 0 ? 0 : dxopal_vol
end

def to_db(vol)
  ((vol / 255.0) - 1) * 96
end

def build_label(button)
  text = button[:name]

  if button[:name] == "dxruby_compat"
    if RUBY_ENGINE == "opal"
      text + format(" (%s)", $dxruby_compat ? "on" : "off")
    else
      "-"
    end
  elsif button[:name].start_with?("volume_")
    text = format("volume: %d (%.1f dB)", button[:vol], to_db(button[:vol]))
    if $dxruby_compat
      vol2 = adjust_from_dxruby_volume(button[:vol])
      text + format(" => %d (%.1f dB)", vol2, to_db(vol2))
    else
      text
    end
  else
    text
  end
end

$dxruby_compat = false

$master_volume = {
  "ruby" => ->(v){ v },
  "opal" => ->(v){
    if $dxruby_compat
      adjust_from_dxruby_volume(v)
    else
      v
    end
  },
}.fetch(RUBY_ENGINE)

# --------------------------------

Window.width = WIN_W
Window.height = WIN_H

s1 = SoundWrapper.new("./s1.wav")

Window.load_resources do
  Window.loop do
    # button index
    bi = (Input.mouse_y / BUTTON_H).floor

    if Input.mouse_push?(M_LBUTTON)
      button = BUTTONS[bi]
      if button
        case button[:name]
        when "stop"
          s1.stop
        when "dxruby_compat"
          if RUBY_ENGINE == "opal"
            $dxruby_compat = !$dxruby_compat
            s1.stop
          end
        else
          s1.stop
          s1.set_volume(button[:vol])
          s1.play
        end
      end
    end

    BUTTONS.each_with_index do |button, i|
      y = i * BUTTON_H

      if i == bi
        Window.draw_box_fill(0, BUTTON_H * bi, WIN_W, BUTTON_H * (bi + 1), C_BLUE)
      end

      Window.draw_line(0, y, WIN_W, y, C_WHITE)

      Window.draw_font(10, y + 6, build_label(button), FONT_MAIN, color: C_WHITE)
    end
  end
end
