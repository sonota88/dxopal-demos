# Written by noanoa:
# https://noanoa07.blog.jp/archives/2159950.html

# --------------------------------

# DXRuby版 ブロック崩し
# http://blog.livedoor.jp/noanoa07/archives/2045851.html
# を DXOpal に移植
# Original;
# 2014-03-17 松江Ruby会議05に参加してきた - mirichiの日記
# http://d.hatena.ne.jp/mirichi/20140317/p1
# License: public domain

# require 'dxopal'
# include DXOpal

case RUBY_ENGINE
when "opal"  then require "dxopal"
when "jruby" then require "dxjruby"
else raise "unsupported engine (#{RUBY_ENGINE})"
end

bar   =  Sprite.new(0, 460, Image.new(100,  20, C_WHITE))

walls = [Sprite.new(  0, 0, Image.new( 20, 480, C_BLUE)),
         Sprite.new(  0, 0, Image.new(640,  20, C_BLUE)),
         Sprite.new(620, 0, Image.new( 20, 480, C_BLUE)),
         bar]

ball  =  Sprite.new(300, 400, Image.new(20, 20).circle_fill(10, 10, 10, C_WHITE))
dx = 4
dy = -4

image = Image.new(58, 18, C_WHITE)
blocks = []
5.times do |y|
  10.times do |x|
    blocks << Sprite.new(21 + 60 * x , 21 + 20 * y, image)
  end
end

Window.load_resources do
  Window.loop do
    bar.x = Input.mouse_pos_x

    Sprite.draw(walls)

    ball.x += dx
    if ball === walls
      ball.x -= dx
      dx = -dx
    end

    col_x = ball.check(blocks).first
    if col_x
      col_x.vanish
      ball.x -= dx
      dx = -dx
    end

    ball.y += dy
    if ball === walls
      ball.y -= dy
      dy = -dy
    end

    col_y = ball.check(blocks).first
    if col_y
      col_y.vanish
      ball.y -= dy
      dy = -dy
    end

    ball.draw

    Sprite.draw(blocks)
  end
end
