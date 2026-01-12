module Nes
  MASTER_CLOCK_HZ = 236_250_000.0 / 11
  CPU_CLOCK_HZ = MASTER_CLOCK_HZ / 12 # 1_789_772.7272727273

  # 参考:
  #   ファミコンのノイズ音を作ってみた（最低限の部分だけ）
  #   https://qiita.com/sonota88/items/d2c7d91d7058cda63e82
  #   APU Noise - NESdev Wiki
  #   https://www.nesdev.org/wiki/APU_Noise
  class Noise
    PERIOD_TABLE = [
      # 0x00 0x01 ...                                                  ... 0x0E  0x0F
        4,   8,   16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068
    ]

    NUM_SAMPLES = 32_767

    class Generator
      def initialize
        # shift register
        @shift_reg = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
      end

      # 下位から i 桁目のビット
      def shift_reg_bit(i)
        @shift_reg[14 - i]
      end

      def update_shift_reg
        next_bit = shift_reg_bit(1) ^ shift_reg_bit(0) # XOR
        @shift_reg = [next_bit] + @shift_reg[0..13]
      end

      def self.generate_values
        vs = []
        g = Generator.new
        NUM_SAMPLES.times {
          g.update_shift_reg()
          vs << g.shift_reg_bit(0) * 2 - 1 # -1.0<= .. <=1.0 に補正
        }
        vs
      end
    end

    VALUES = Generator.generate_values

    # --------------------------------

    # reg400e_period: $400E:3-0 にセットする値（0<=, <=15）
    def initialize(reg400e_period)
      update_reg400e_period(reg400e_period)

      @pos = 0.0
      @pos_prev = 0.0
    end

    def update_reg400e_period(reg400e_period)
      period = PERIOD_TABLE[reg400e_period]
      @raw_sampling_rate = CPU_CLOCK_HZ / (period + 1)
    end

    def progress(sec)
      @pos_prev = @pos
      @pos += sec * @raw_sampling_rate
    end

    def _value_at(pos)
      i = pos.floor % NUM_SAMPLES
      VALUES[i]
    end

    def value
      i0 = @pos_prev.floor
      i1 = @pos.floor
      if i0 == i1
        _value_at(i0)
      else
        # 簡易なリサンプリング
        n = i1 - i0 + 1
        ((i0 + 1)..i1).to_a.map { |i| _value_at(i) }.sum / n
      end
    end
  end

  module Triangle
    module TableGenerator
      def self.generate
        ns = (
          8.upto(15).to_a +
          15.downto(0).to_a +
          0.upto(7).to_a
        )
        vs = ns.map { |n| n.to_f / 15 } # 0.0 <= .. <= 1.0
        vs.map { |v| v * 2 - 1 } # -1.0 <= .. <= 1.0
      end
    end

    TABLE = TableGenerator.generate

    # x: radian
    def self.osc(x)
      ratio = x / (Math::PI * 2)
      cr = ratio % 1 # ratio in cycle
      i = (cr * 32).floor
      TABLE[i]
    end
  end
end
