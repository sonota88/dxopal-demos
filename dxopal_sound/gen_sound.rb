require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "wavefile", "1.1.2"
end

include WaveFile

def osc_tri(ratio)
  if    ratio < 0.25 then  4 * ratio
  elsif ratio < 0.75 then -4 * ratio + 2
  else                     4 * ratio - 4
  end
end

# --------------------------------

pattern = [
  [1000,  200, 0.5],
  [1000,  400, 0.25],
  [1000,  600, 0.5],
  [1000,  800, 0.25],
  [1000, 1000, 0.5],
]

pattern_range = []
t = 0
pattern.each do |dur_msec, hz, amp|
  pattern_range << {
    t_min: t,
    t_max: t + dur_msec,
    hz: hz,
    amp: amp,
  }
  t += dur_msec
end
duration_msec = t

def get_param(pattern_range, t_msec)
  pat = pattern_range.find { |_pat|
    _pat[:t_min] <= t_msec && t_msec < _pat[:t_max]
  }
  raise if pat.nil?

  [pat[:hz], pat[:amp]]
end

# --------------------------------

# サンプリングレート（サンプル数 / 秒）
srate = 44100
# 全体のサンプル数
num_samples = srate * (duration_msec.to_f / 1000)

# --------------------------------

samples = []

(0...num_samples).each do |i|
  all_ratio = i.to_f / num_samples
  t_msec = duration_msec * all_ratio
  hz, amp = get_param(pattern_range, t_msec)

  num_samples_per_cycle = srate.to_f / hz
  i_in_cycle = i % num_samples_per_cycle
  ratio = i_in_cycle / num_samples_per_cycle

  samples[i] = osc_tri(ratio) * amp
end

# --------------------------------

buffer_format = Format.new(:mono, :float, srate)
buffer = Buffer.new(samples, buffer_format)

out_file = "s1.wav"
file_format = Format.new(:mono, :pcm_16, srate)
Writer.new(out_file, file_format) do |writer|
  writer.write(buffer)
end
