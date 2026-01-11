require "dxopal"

%x{
  // lib.js の内容をここに直接書いてもよい
}

class MemorySound
  SAMPLING_RATE = 44100

  attr_reader :base64str

  def initialize(base64str)
    @base64str = base64str
  end

  def self.generate(duration_msec, &block)
    b64str = nil
    %x{
      const jsms = new JsMemorySound({
        bitsPerSample: 16,
        numChannels: 1,
        sampleRate: #{SAMPLING_RATE},
        durationMsec: duration_msec,
      });
      jsms.generate(block);
      b64str = jsms.toBase64();
    }

    MemorySound.new(b64str)
  end
end

def sound_register_from_memory(name, mem_sound)
  Sound.register(name, "data:audio/wav;base64," + mem_sound.base64str)
end

# --------------------------------

dur_msec = 500
freq = 440
volume = 0.2

memory_sound = MemorySound.generate(dur_msec) { |_, t_sec|
  Math.sin(2 * Math::PI * t_sec * freq) * volume
}

sound_register_from_memory(:s1, memory_sound)

Window.load_resources do
  Window.loop do
    if Input.mouse_push?(M_LBUTTON)
      Sound[:s1].play
    end

    Window.draw_font(10, 10, "click to play sound", Font.default, color: C_WHITE)
  end
end
