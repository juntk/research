require 'rubygems'
require 'tk'
require 'pongo'
require 'pongo/renderer/tk_renderer'
require 'pongo/logger/standard_logger'

include Pongo

class AcrobotTest
    def initialize(windowSize = [640,480])
        @time = 0
        @sec = 0
        @windowWidth = windowSize[0]
        @windowHeight = windowSize[1]

        APEngine.setup
        root = TkRoot.new{}
        @canvas = TkCanvas.new(root, :width=>640, :height=>480)
        @canvas.pack
        APEngine.renderer = Renderer::TkRenderer.new(@canvas)
        APEngine.logger = Logger::StandardLogger.new
        gravity = 9.8
        APEngine.add_force(VectorForce.new(false, 0 , gravity))
        APEngine.damping = 1
        mass = 1
        @joint1 = CircleParticle.new(
            @windowWidth/2,
            0,
            mass,
            :fixed=>false,
            :fill_alpha=>0,
            :line_alpha=>0
        )
        @group = Pongo::Group.new
        @group.collide_internal = true
        @group.add_particle(@joint1)
        APEngine.add_group(@group)
    end
    def run()
        TkTimer.start(67) do |t|
            @time += 1
            begin
                APEngine.step
                APEngine.draw
            rescue
                puts 't'
            end
            puts @time
            if @time % 16 == 0 then
                p @joint1.curr
                p @joint1.velocity
                @sec += 1
                sleep 1
            end
        end
        Tk.mainloop
    end
end

a = AcrobotTest.new
a.run()
