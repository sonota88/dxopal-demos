require "dxopal"
require_remote "nes.rb"

TWO_PI = 2 * Math::PI
FONT_MAIN = Font.new(14, "monospace")
MASTER_VOLUME = 0.1

class MemorySound
  SAMPLING_RATE = 44100
  SEC_PER_SAMPLE = 1.0 / SAMPLING_RATE

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

$current_sound = nil

def play(sound)
  $current_sound.stop if $current_sound
  $current_sound = sound
  $current_sound.play
end

# --------------------------------

BUTTONS = [
  {
    name: "ms1", text: "example 1",
    onclick: ->(){ play Sound[:ms1] }
  },
  {
    name: "ms2", text: "example 2",
    onclick: ->(){ play Sound[:ms2] }
  },
  {
    name: "ms3", text: "example 3",
    onclick: ->(){ play Sound[:ms3] }
  },
  {
    name: "ms4", text: "example 4",
    onclick: ->(){ play Sound[:ms4] }
  },
  {
    name: "ms5", text: "example 5",
    onclick: ->(){ play Sound[:ms5] }
  },
  {
    name: "ms6", text: "example 6",
    onclick: ->(){ play Sound[:ms6] }
  },
  {
    name: "ms7", text: "example 7",
    onclick: ->(){ play Sound[:ms7] }
  },
  {
    name: "nes_tri_220", text: "NES triangle 220Hz",
    onclick: ->(){ play Sound[:nes_tri_220] }
  },
  {
    name: "nes_tri_110", text: "NES triangle 110Hz",
    onclick: ->(){ play Sound[:nes_tri_110] }
  },
  {
    name: "nes_tri_down", text: "NES triangle down",
    onclick: ->(){ play Sound[:nes_tri_down] }
  },
  {
    name: "nes_noise_0", text: "NES noise 400e=0",
    onclick: ->(){ play Sound[:nes_noise_0] }
  },
  {
    name: "nes_noise_1", text: "NES noise 400e=1",
    onclick: ->(){ play Sound[:nes_noise_1] }
  },
  {
    name: "nes_noise_13", text: "NES noise 400e=13",
    onclick: ->(){ play Sound[:nes_noise_13] }
  },
  {
    name: "nes_noise_14", text: "NES noise 400e=14",
    onclick: ->(){ play Sound[:nes_noise_14] }
  },
  {
    name: "nes_noise_15", text: "NES noise 400e=15",
    onclick: ->(){ play Sound[:nes_noise_15] }
  },
  {
    name: "nes_noise_se1", text: "NES noise se 1",
    onclick: ->(){ play Sound[:nes_noise_se1] }
  },
  {
    name: "nes_noise_se2", text: "NES noise se 2",
    onclick: ->(){ play Sound[:nes_noise_se2] }
  },
  {
    name: "tonejs_fm", text: "Tone.js FMSynth",
    onclick: ->(){ play Sound[:tonejs_fm] }
  },
  {
    name: "tonejs_metal", text: "Tone.js MetalSynth",
    onclick: ->(){ play Sound[:tonejs_metal] }
  },
]

def button_get(i)
  if 0 <= i
    BUTTONS[i]
  else
    nil
  end
end

BUTTON_H = 40
WIN_W = 400
WIN_H = BUTTON_H * BUTTONS.size

# --------------------------------

def osc_sin(x)
  Math.sin(x)
end

def osc_pulse(x, duty_ratio = 0.5)
  ratio = (x.to_f % TWO_PI) / TWO_PI
  if ratio < duty_ratio
    1.0
  else
    -1.0
  end
end

def wavetable_normalize(wt)
  max = wt.map(&:abs).max
  wt.map { |x| x.to_f / max }
end

def wavetable_get(wt, x)
  ratio = (x.to_f / TWO_PI) % 1
  i = (wt.size * ratio).floor
  wt[i]
end

# 4c: 60 / 4a: 69
def to_hz(note_no)
  n = note_no - (5 * 12 + 9)
  440.0 * (2.0 ** (n.to_f / 12))
end

def lerp(v1, v2, v2_ratio)
  v1_ratio = 1.0 - v2_ratio
  v1 * v1_ratio + v2 * v2_ratio
end

# --------------------------------

def make_sound_1
  dur_msec = 500
  dur_sec = dur_msec.to_f / 1000
  freq = 440

  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    ratio_inv = 1.0 - t / dur_sec
    osc_sin(TWO_PI * t * freq) * ratio_inv * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_2
  dur_msec = 200
  dur_sec = dur_msec.to_f / 1000
  freq0 = 440
  freq1 = 220

  x = 0.0 # radian
  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    ratio = t / dur_sec
    ratio_inv = 1.0 - ratio
    freq = lerp(freq0, freq1, ratio)
    x_delta = TWO_PI * freq * MemorySound::SEC_PER_SAMPLE
    x += x_delta
    osc_pulse(x) * ratio_inv * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_3
  dur_msec = 200
  dur_sec = dur_msec.to_f / 1000
  freq_base = 1200
  w = freq_base * 0.9 # width
  freq = freq_base
  sec_per_cycle = 1.0 / freq
  cycle_i_prev = 0

  x = 0.0
  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    ratio = t / dur_sec
    ratio_inv = 1.0 - ratio
    x_delta = TWO_PI * freq * MemorySound::SEC_PER_SAMPLE
    x += x_delta

    ci = (t.to_f / sec_per_cycle).floor
    if ci != cycle_i_prev
      freq = freq_base - (w * 0.5) + rand * w
      cycle_i_prev = ci
    end

    osc_pulse(x) * (ratio_inv**2) * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_4
  dur_msec = 500
  dur_sec = dur_msec.to_f / 1000
  freq_base0 = 200
  freq_base1 = 2000
  freq_base = lerp(freq_base0, freq_base1, 0)
  w = freq_base * 0.9 # width
  freq = freq_base
  sec_per_cycle = 1.0 / freq
  cycle_i_prev = 0

  x = 0.0
  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    ratio = t / dur_sec
    ratio_inv = 1.0 - ratio
    x_delta = TWO_PI * freq * MemorySound::SEC_PER_SAMPLE
    x += x_delta

    ci = (t.to_f / sec_per_cycle).floor
    if ci != cycle_i_prev
      freq_base = lerp(freq_base0, freq_base1, ratio)
      w = freq_base * 0.9
      freq = freq_base - (w * 0.5) + rand * w
      cycle_i_prev = ci
    end

    osc_pulse(x) * (ratio_inv**2) * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_5
  dur_msec = 100
  dur_sec = dur_msec.to_f / 1000
  vol = 0.6

  unit = [0, 7, 4, 11].map { |nn| nn + 36 }
  note_nos = []
  note_nos += unit
  note_nos += unit.map { |nn| nn + 12 }
  note_nos += unit.map { |nn| nn + 24 }
  freqs = note_nos.map { |nn| to_hz(nn) }

  x = 0.0
  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    ratio = t / dur_sec
    i = (note_nos.size * ratio).floor
    freq = freqs[i]
    x_delta = TWO_PI * freq * MemorySound::SEC_PER_SAMPLE
    x += x_delta
    osc_pulse(x, 0.125) * vol * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_6
  samples = []
  dur_msec = 300
  dur_sec = dur_msec.to_f / 1000
  srate = MemorySound::SAMPLING_RATE
  num_samples = (srate * dur_sec).floor
  sec_per_sample = 1.0 / srate
  vol = 0.7

  freqs = [0, 4, 7, 11]
            .map { |nn| nn + 72 }
            .map { |nn| to_hz(nn) }
  freqs = freqs * 3

  x = 0.0
  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    ratio = i.to_f / num_samples
    ratio_inv = 1.0 - ratio

    v = osc_pulse(x, 0.25)

    fi = (freqs.size * ratio).floor
    freq = freqs[fi]

    x_delta = TWO_PI * freq * sec_per_sample
    x += x_delta

    v * ratio_inv * vol * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_7
  samples = []
  dur_msec = 500
  dur_sec = dur_msec.to_f / 1000
  srate = MemorySound::SAMPLING_RATE
  num_samples = (srate * dur_sec).floor
  sec_per_sample = 1.0 / srate
  vol = 0.8

  wt = wavetable_normalize(
    [7, -7, 7, -7, -0, -0, -0, -0,]
  )

  freqs = [0, 1, 2, 3]
            .map { |nn| nn * 0.5 }
            .map { |nn| nn + 60 }
            .map { |nn| to_hz(nn) }
  freqs = freqs * 3

  x = 0.0
  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    ratio = i.to_f / num_samples
    ratio_inv = 1.0 - ratio

    v = wavetable_get(wt, x)

    fi = (freqs.size * ratio).floor
    freq = freqs[fi]
    x_delta = TWO_PI * freq * sec_per_sample
    x += x_delta

    v * ratio_inv * vol * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_nes_tri(freq, freq_to: nil)
  dur_msec = 300
  dur_sec = dur_msec.to_f / 1000

  freq0 = freq
  freq1 = freq_to || freq

  x = 0.0
  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    ratio = t / dur_sec
    freq = lerp(freq0, freq1, ratio)
    x_delta = TWO_PI * freq * MemorySound::SEC_PER_SAMPLE
    x += x_delta
    Nes::Triangle.osc(x) * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_nes_noise(reg400e_period)
  dur_msec = 1000
  vol = 0.5

  nn = Nes::Noise.new(reg400e_period)

  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    nn.progress MemorySound::SEC_PER_SAMPLE
    nn.value * vol * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_nes_noise_se1
  dur_msec = 120
  dur_sec = dur_msec.to_f / 1000
  vol = 0.5

  rp = 10 # reg400e_period
  rp_prev = rp
  nn = Nes::Noise.new(rp)

  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    t_ratio = t.to_f / dur_sec

    rp =
      if t_ratio < 0.5
        10
      else
        0
      end

    if rp != rp_prev
      nn.update_reg400e_period(rp)
    end
    rp_prev = rp

    nn.progress MemorySound::SEC_PER_SAMPLE
    v = nn.value

    v * vol * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_nes_noise_se2
  dur_msec = 800
  dur_sec = dur_msec.to_f / 1000
  vol = 0.5

  rp = 2 # reg400e_period
  rp_prev = rp
  nn = Nes::Noise.new(rp)

  memory_sound = MemorySound.generate(dur_msec) { |i, t|
    ratio = t / dur_sec
    ratio_inv = 1 - ratio
    t_ratio = t.to_f / dur_sec

    rp, _vol =
      if t_ratio < 0.1
        if t_ratio < 0.08
          [2, 1]
        else
          [2, 0]
        end
      elsif t_ratio < 0.2
        if t_ratio < 0.18
          [8, 1]
        else
          [8, 0]
        end
      elsif t_ratio < 0.3
        [2, 1]
      else
        [8, 1]
      end

    if rp != rp_prev
      nn.update_reg400e_period(rp)
    end
    rp_prev = rp

    nn.progress MemorySound::SEC_PER_SAMPLE
    v = nn.value * _vol

    v * vol * (ratio_inv**2) * MASTER_VOLUME
  }

  memory_sound
end

def make_sound_tonejs_fm
  duration_msec = 500
  b64str = nil

  %x{
    Tone.Offline(
      ()=>{
        const synth = new Tone.FMSynth({
          harmonicity: 0.2,
          modulationIndex: 50,
          oscillator: { type: "sine" },
          modulation: { type: "sine" },
          envelope: { attack: 0.0, decay: 0.2, sustain: 0.6, release: 0.8 },
          modulationEnvelope: { attack: 0.0, decay: 0.1, sustain: 0.5, release: 0.5 }
        });

        const gain = new Tone.Gain(2.0 * #{MASTER_VOLUME});
        synth.connect(gain);
        gain.toDestination();

        synth.triggerAttackRelease("A4", "8n", 0);
        synth.frequency.rampTo("A3", "8n");
      },
      duration_msec / 1000
    ).then((abuf)=>{
      const jsms = JsMemorySound.fromArrayBuffer(abuf, duration_msec);
      b64str = jsms.toBase64();
      #{ yield b64str };
    });
  }
end

def make_sound_tonejs_metal
  duration_msec = 500
  b64str = nil

  %x{
    Tone.Offline(
      ()=>{
        const synth = new Tone.MetalSynth({
          harmonicity: 20.16,
          modulationIndex: 18,
          resonance: 2000,
          octaves: 0.9,
          envelope: { attack: 0.005, decay: 0.35, release: 0.2 }
        });

        const gain = new Tone.Gain(#{MASTER_VOLUME});
        synth.connect(gain);
        gain.toDestination();

        synth.triggerAttackRelease("A4", "8n");
      },
      duration_msec / 1000
    ).then((abuf)=>{
      const jsms = JsMemorySound.fromArrayBuffer(abuf, duration_msec);
      b64str = jsms.toBase64();
      #{ yield b64str };
    });
  }
end

# --------------------------------

def start
  init_010
end

def init_010
  sound_register_from_memory(:ms1, make_sound_1)
  sound_register_from_memory(:ms2, make_sound_2)
  sound_register_from_memory(:ms3, make_sound_3)
  sound_register_from_memory(:ms4, make_sound_4)
  sound_register_from_memory(:ms5, make_sound_5)
  sound_register_from_memory(:ms6, make_sound_6)
  sound_register_from_memory(:ms7, make_sound_7)

  sound_register_from_memory(:nes_tri_220, make_sound_nes_tri(220))
  sound_register_from_memory(:nes_tri_110, make_sound_nes_tri(110))
  sound_register_from_memory(:nes_tri_down, make_sound_nes_tri(120, freq_to: 60))

  sound_register_from_memory(:nes_noise_0,  make_sound_nes_noise( 0))
  sound_register_from_memory(:nes_noise_1,  make_sound_nes_noise( 1))
  sound_register_from_memory(:nes_noise_13, make_sound_nes_noise(13))
  sound_register_from_memory(:nes_noise_14, make_sound_nes_noise(14))
  sound_register_from_memory(:nes_noise_15, make_sound_nes_noise(15))

  sound_register_from_memory(:nes_noise_se1, make_sound_nes_noise_se1)
  sound_register_from_memory(:nes_noise_se2, make_sound_nes_noise_se2)

  init_020
end

def init_020
  make_sound_tonejs_fm { |b64str|
    mem_sound = MemorySound.new(b64str)
    sound_register_from_memory(:tonejs_fm, mem_sound)
    init_030
  }
end

def init_030
  make_sound_tonejs_metal { |b64str|
    mem_sound = MemorySound.new(b64str)
    sound_register_from_memory(:tonejs_metal, mem_sound)
    main
  }
end

def main
  Window.width = WIN_W
  Window.height = WIN_H

  Window.load_resources do
    Window.loop do
      # button index
      bi =
        if Input.mouse_y == 0
          nil
        else
          (Input.mouse_y / BUTTON_H).floor
        end

      if Input.mouse_push?(M_LBUTTON)
        if Input.mouse_x < WIN_W
          button = button_get(bi)
          if button
            button[:onclick].call
          end
        end
      elsif Input.touch_push?
        bi = (Input.touch_y / BUTTON_H).floor
        if Input.touch_x < WIN_W
          button = button_get(bi)
          if button
            button[:onclick].call
          end
        end
      end

      BUTTONS.each_with_index do |button, i|
        y = i * BUTTON_H

        if i == bi
          # ハイライト
          Window.draw_box_fill(0, BUTTON_H * bi, WIN_W, BUTTON_H * (bi + 1), C_BLUE)
        end

        # 境界の線
        Window.draw_line(0, y, WIN_W, y, C_WHITE)

        Window.draw_font(10, y + 6, button[:text], FONT_MAIN, color: C_WHITE)
      end

      Window.draw_font(WIN_W - 40, 10, "y=#{Input.mouse_y.inspect}", FONT_MAIN, color: [80,80,80])
    end
  end
end

start
