require 'tk'
require 'pongo'
require 'pongo/renderer/tk_renderer'
require 'pongo/logger/standard_logger'

include Pongo

class Test
	attr_accessor :width, :height

	def initialize
		@width = 640
		@height = 480
		@gravity = 9.8
		@lineWidth = 150
        @addVelocity = 10
		root = TkRoot.new { title 'Acrobot' }
		@canvas = TkCanvas.new(root, :width=>@width, :height=>@height)
		@canvas.pack
        @buf = []
		APEngine.setup
		APEngine.renderer = Renderer::TkRenderer.new(@canvas)
		APEngine.logger = Logger::StandardLogger.new
		APEngine.add_force VectorForce.new(false, 0, @gravity)

		@group = Group.new
		@group.collide_internal = true
	end
	
	def setObject()
		# tama
		"""
		mass: omosa
		fixed: kotei
		elasticity: dansei
		friction: masatsu
		"""
		@a = CircleParticle.new(@width/2,60,5,:fixed=>true)
		@b = CircleParticle.new(@width/2-@lineWidth,60,5,:mass=>25,
                                :fixed=>false)
		@c = CircleParticle.new(@width/2-@lineWidth*2,60,5,:elasticity=>1,:mass=>10)

		# line
		@line = SpringConstraint.new(@a, @b, :stiffness=>1)
		@line2 = SpringConstraint.new(@b, @c, :stiffness=>1)

		# floor
		base = RectangleParticle.new(0,460,@width*2,30,:fixed=>true)
		
		@group.add_particle(@a)
		@group.add_particle(@b)
		@group.add_particle(@c)
		@group.add_particle(base)
		@group.add_constraint(@line)
		@group.add_constraint(@line2)
		APEngine.add_group(@group)
        
        powerButton = TkButton.new(:text=> 'power')
        powerButton.command {
            tmp = @c.velocity
            if tmp.x >= 0 then
                tmp.x += @addVelocity
            else
                tmp.x -= @addVelocity
            end
            if tmp.y >= 0 then
                tmp.y += @addVelocity
            else
                tmp.y -= @addVelocity
            end
            @c.velocity = (Pongo::Vector.new(tmp.x, tmp.y))
        }
        powerButton.pack
	end

    def addForce()
        @group.particles[2].addForce(Pongo::Vector.new(5,-1))
    end
	
	def addGroup()
	end

    def getVector(aPoint1, aPoint2)
        c = Pongo::Vector.new
        c.x = aPoint2.x - aPoint1.x
        c.y = aPoint2.y - aPoint1.y
        return c
    end

    def getQuadrant(aPoint)
        if aPoint[1] >= 0 and aPoint[0] >= 0 then
            return 4
        elsif aPoint[1] >= 0 and aPoint[0] < 0 then
            return 3
        elsif aPoint[1] <= 0 and aPoint[0] < 0 then
            return 2
        elsif aPoint[1] < 0 and aPoint[0] > 0 then
            return 1
        end
        return nil
    end

    def getTan(aVector, aQuadrant)
        tan = aVector.y / aVector.x
        tan = Math.atan(tan)
        tan = tan * 180.0 / Math::PI
        if aQuadrant == 1 then
            tan = 90 + tan 
        elsif aQuadrant == 2 then
            tan += 0
        elsif aQuadrant == 3 then
            tan = 90 + tan 
        elsif aQuadrant == 4 then
            tan = 90 - tan 
        end
        return tan
    end

	def run()
		TkTimer.start(10) do |anime|
			begin
				APEngine.step
				APEngine.draw

                a = @group.particles[0].curr
                b = @group.particles[1].curr
                c = @group.particles[2].curr
                lineVector1 = getVector(a, b)
                lineVector2 = getVector(b, c)
                quadrant1 = getQuadrant([lineVector1.x, lineVector1.y])
                quadrant2 = getQuadrant([lineVector2.x, lineVector2.y])
                r1 = getTan(lineVector1, quadrant1)
                r2 = getTan(lineVector2, quadrant1)

                # renderer

                @buf.each do |v|
                    @canvas.delete(v)
                end
                @buf = []
                @buf << TkcLine.new(@canvas, a.x, a.y, a.x, a.y + 100, :fill=>'red')
                @buf << TkcLine.new(@canvas, b.x, b.y, b.x, b.y + 100, :fill=>'red')
                if quadrant1 == 3 or quadrant1 == 2 then
                    textPosAX = a.x-15
                else
                    textPosAX = a.x+15
                end
                if quadrant2 == 3 or quadrant2 == 2 then
                    textPosBX = b.x-15
                else
                    textPosBX = b.x+15
                end
                @buf << TkcText.new(@canvas, textPosAX, a.y+80,
                                    :text=>r1.to_i.to_s)
                @buf << TkcText.new(@canvas, textPosBX, b.y+80,
                                    :text=>r2.to_i.to_s)
			rescue
				APEngine.log($1)
			end
		end
		Tk.mainloop
	end
end

t = Test.new
t.setObject()
t.addGroup()
t.run()


