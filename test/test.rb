require 'tk'                                                                       
require 'rubygems'
require 'pongo'                                                                    
require 'pongo/renderer/tk_renderer'                                               
require 'pongo/logger/standard_logger'                                             
include Pongo                                                                      
                                                                                   
class Test
def initialize
root = TkRoot.new
@canvas = TkCanvas.new(root, :width => 500, :height => 350)
@canvas.pack

# レンダラとかロガーとか重力とかいろいろ設定
APEngine.renderer = Renderer::TkRenderer.new(@canvas)
APEngine.logger = Logger::StandardLogger.new

# パーティクルはグループに登録しないと駄目らしいので準備
@default_group = Group.new
@default_group.collide_internal = true

# 落下物。箱とか丸とか
@default_group.add_particle(RectangleParticle.new(275, 90, 20, 30))
@default_group.add_particle(CircleParticle.new(255, 150, 3))

# 地面
@default_group.add_particle(RectangleParticle.new(250, 250, 300, 50, :fixed => true))

# グループをエンジンに登録
APEngine.add_group(@default_group)

# 実行
TkTimer.start(10) do |timer|
  APEngine.step
  APEngine.draw
end 
Tk.mainloop
end
end

Test.new
