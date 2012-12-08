require 'rubygems'
require 'pongo'
require 'pongo/renderer/tk_renderer'
require 'pongo/logger/standard_logger'

class AcrobotArm
    attr_accessor :length, :height, :mass
    attr_accessor :elasticity, :stiffness, :velocity
    attr_accessor :line_color, :fill_color
    def initialize
        # アームの長さ
        @length = 16
        # アームの太さ
        @height = 1
        # アームの重さ
        @mass = 1
        # 弾性
        @elasticity = 1
        # 剛性
        @stiffness = 1
        # 速度
        @velocity = 0
        # スタイル
        @line_color = 0x000fff
        @fill_color = 0xfff000
    end
end
