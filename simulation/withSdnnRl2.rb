#encoding:utf-8
require 'tk'
require 'rubygems'
require 'pongo'
require 'pongo/renderer/tk_renderer'
require 'pongo/logger/standard_logger'
require './sdnn/main.rb'
require "./ReinforcementLearning/basicQLearning4.rb"

include Pongo

class Test
	attr_accessor :width, :height

	def initialize
        @sdnn = Sdnn.new
        @rate = 10
        @isNoMax = false
        @bql = BasicQLearning.new
        @bql.alpha = 0.5
        @bql.gamma = 0.5
        @reward = 60 # housyuu
		@width = 640
		@height = 480
		@gravity = 0
		@lineWidth = 150
        @addVelocity = 5
        @learning = true
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
		@a = CircleParticle.new(@width/2,60,6,:fixed=>true)
        """
		@b = CircleParticle.new(@width/2-@lineWidth,60,5,:mass=>10,
                                :fixed=>false)
		@c = CircleParticle.new(@width/2-@lineWidth*2,60,5,:elasticity=>1,:mass=>10)
        """
		@b = CircleParticle.new(@width/2,60+@lineWidth,6,:mass=>10,
                                :fixed=>false)
		@c = CircleParticle.new(@width/2,60+@lineWidth*2,6,:elasticity=>1,:mass=>10)

		# line
		@line = SpringConstraint.new(@a, @b, :stiffness=>1, :collidable=>true, :rect_height=>2)
		@line2 = SpringConstraint.new(@b, @c, :stiffness=>1, :collidable=>true, :rect_height=>2)
        p @line
        @lineLength = Math.sqrt((@b.curr.x - @a.curr.x)*(@b.curr.x - @a.curr.x) + (@b.curr.y - @a.curr.y)*(@b.curr.y - @a.curr.y))
        @line2Length = Math.sqrt((@c.curr.x - @b.curr.x)*(@c.curr.x - @b.curr.x) + (@c.curr.y - @b.curr.y)*(@c.curr.y - @b.curr.y))

		# floor
		base = RectangleParticle.new(0,460,@width*2,30,:fixed=>true)
		
		@group.add_particle(@a)
		@group.add_particle(@b)
		@group.add_particle(@c)
		@group.add_particle(base)
		@group.add_constraint(@line)
		@group.add_constraint(@line2)
		APEngine.add_group(@group)

        # start
        startButtonLQ = TkButton.new(:text=> 'start(+Learn+Qvalue)')
        startButtonLQ.command {
            @b.curr= Pongo::Vector.new(320,60+@lineWidth)
            @c.curr= Pongo::Vector.new(320,60+@lineWidth*2)
            @b.velocity = Pongo::Vector.new(0,0)
            @c.velocity = Pongo::Vector.new(0,0)
            @run = true
            @learning = true
            @qvalue = true
        }
        startButtonLQ.pack(:side=>'right')

        # restart (not learning)
        startButtonQ = TkButton.new(:text=> 'start(-Learn+Qvalue)')
        startButtonQ.command {
            @b.curr= Pongo::Vector.new(320,60+@lineWidth)
            @c.curr= Pongo::Vector.new(320,60+@lineWidth*2)
            @b.velocity = Pongo::Vector.new(0,0)
            @c.velocity = Pongo::Vector.new(0,0)
            @learning = false
            @qvalue = true
            @run = true
        }
        startButtonQ.pack(:side=>'right')

        # restart (not learning)
        startButton = TkButton.new(:text=> 'start(-Learn-Qvalue)')
        startButton.command {
            @b.curr= Pongo::Vector.new(320,60+@lineWidth)
            @c.curr= Pongo::Vector.new(320,60+@lineWidth*2)
            @b.velocity = Pongo::Vector.new(0,0)
            @c.velocity = Pongo::Vector.new(0,0)
            @learning = false
            @qvalue = false
            @run = true
        }
        startButton.pack(:side=>'right')

        # stop
        stopButton = TkButton.new(:text=> 'stop')
        stopButton.command {
            @run = false
        }
        stopButton.pack(:side=>'right')
        
        # power
        powerButton = TkButton.new(:text=> 'power')
        powerButton.command {
            addForce()
        }
        powerButton.pack(:side=>'right')




	end

    def addForce(tmp=@c.velocity)
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
    end
	
	def addGroup()
	end

    def getVector(aPoint1, aPoint2)
        c = Pongo::Vector.new
        if aPoint2.x > aPoint1.x then
            c.x = aPoint2.x - aPoint1.x
        else
            c.x = aPoint1.x - aPoint2.x
        end
        if aPoint2.y > aPoint1.y then
            c.y = aPoint2.y - aPoint1.y
        else
            c.y = aPoint1.y - aPoint2.y
        end
        return c
    end

    def getQuadrant2(aPoint1, aPoint2)
        if aPoint1.x > aPoint2.x then
            #left
            if aPoint1.y < aPoint2.y then
                #left-down
                return 3
            else
                #left-up
                return 2
            end
        else
            if aPoint1.y < aPoint2.y then
                #right-down
                return 4
            else
                #left-up
                return 1
            end
        end
        return nil
    end
    """
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
    """

    def getTan(aVector, aQuadrant)
        tan = aVector.y/aVector.x
        tan = Math.atan(tan)
        tan = tan * 180.0 / Math::PI
        if aQuadrant == 1 then
            tan = -1*(-90+tan) 
            tan =  tan 
        elsif aQuadrant == 2 then
            tan += 270
        elsif aQuadrant == 3 then
            tan = -1*(-90+tan)
            tan = tan 
            tan += 180
        elsif aQuadrant == 4 then
            tan += 90
        end
        print aQuadrant, ':', tan
        puts
        return tan
    end

	def run()
        @count = 0
        @ck = 0
		TkTimer.start(10) do |anime|
			begin
                if @run then
                    APEngine.step
                    APEngine.draw
                end

                a = @group.particles[0].curr
                b = @group.particles[1].curr
                c = @group.particles[2].curr
                lineVector1 = getVector(a, b)
                lineVector2 = getVector(b, c)
                quadrant1 = getQuadrant2(a, b)
                quadrant2 = getQuadrant2(b, c)
                rn1 = getTan(lineVector1, quadrant1)
                rn2 = getTan(lineVector2, quadrant1)
                
                r1 = rn1 / @rate
                r2 = rn2 / @rate

                puts r1.to_i % @rate

                maxCount = 0
                """
                if @qvalue == true and @b.curr.x <= 320 and @c.curr.x <= 320 and r2.to_i % @rate == 0 then
                """
                if @qvalue == true and ( rn2.to_i % @rate == 0) then

                    @inputLayer = [@lineLength.to_i/@rate, @line2Length.to_i/@rate,r1.to_i,  r2.to_i]
                    if @c.curr.y <= 60 or @b.curr.y <= 60 and @tmpILA != @inputLayer and @learning == true then
                        puts "報酬"
                        qValue = @sdnn.learning(@inputLayer,@reward)
                        drawQValue(qValue, @c.curr, @b.curr, @a.curr)
                        @tmpILA = @inputLayer
                        puts qValue
                        @a.user_data[:shape].fill = '#FF0000'
                        @b.user_data[:shape].fill = '#FF0000'
                        @c.user_data[:shape].fill = '#FF0000'
                        @line.p1.user_data[:shape].fill = '#FF0000'
                        @line2.p1.user_data[:shape].fill = '#FF0000'
                    else
                        p @line.p1
                        @a.user_data[:shape].fill = '#000000'
                        @b.user_data[:shape].fill = '#000000'
                        @c.user_data[:shape].fill = '#000000'
                        @line.p1.user_data[:shape].fill = '#000000'
                        @line2.p1.user_data[:shape].fill = '#000000'
                        #test
                        @rate2 = 1
                        pattern = []
                        pattern << [r1+@rate2, r2, -1*@addVelocity, 0]
                        pattern << [r1+@rate2, r2+@rate2, -1*@addVelocity,-1*@addVelocity]
                        pattern << [r1, r2+@rate2, 0, -1*@addVelocity]
                        pattern << [r1-@rate2, r2, @addVelocity, 0]
                        pattern << [r1-@rate2, r2-@rate2,@addVelocity,@addVelocity]
                        pattern << [r1, r2-@rate2, 0, @addVelocity]
                        max = -10000
                        maxi = nil
                        print 'check sentaku'
                        pattern.shuffle.each_with_index do |v,i|
                            if v[0] < 0 then
                                v[0] = 0
                            end
                            if v[1] < 0 then
                                v[1] = 0
                            end
                            tmpInputLayer = [@lineLength.to_i/@rate, @line2Length.to_i/@rate,v[0].to_i,  v[1].to_i]
                            p tmpInputLayer

                            reward = @sdnn.checkTest(tmpInputLayer)
                            print '!', reward
                            puts
                            if reward == max then
                                maxCount += 1
                            end
                            if reward > max then
                                max = reward
                                maxi = i
                            end
                        end
                            if maxi != nil and @tmpIL != @inputLayer then
                                if @learning == true then
                                    oldQValue = @sdnn.checkTest(@inputLayer)
                                    print 'old',oldQValue
                                    puts
                                    if maxCount == pattern.length-1  then
                                        @isNoMax = true
                                        puts 'maxなし'
                                        newQValue = @bql.getNewQValue(oldQValue, -60, max).to_i
                                    else
                                        newQValue = @bql.getNewQValue(oldQValue, 0, max).to_i
                                    end
                                    print 'new', newQValue
                                    puts
                                    qValue = @sdnn.learning(@inputLayer,newQValue)
                                    drawQValue(qValue, @c.curr, @b.curr, @a.curr)
                                end

                                nextP = pattern[maxi]
                                vX = @addVelocity
                                vY = vX
                                if @isNoMax == true then
                                    if rand(2) == 0 then
                                        vX *= -1
                                    else
                                        vX *= 1
                                    end
                                    if rand(2) == 0 then
                                        vY *= -1
                                    else
                                        vY *= 1
                                    end
                                end
                                if @isNoMax == false and nextP[1] > r2 then
                                    if quadrant2 == 4 then
                                        vX *= -1
                                        vY *= 1
                                    elsif quadrant2 == 3 then
                                        vX *= -1
                                        vY *= -1
                                    elsif quadrant2 == 2 then
                                        vY *= -1
                                    end
                                else
                                    if quadrant2 == 4 then
                                        vY *= -1
                                    elsif quadrant2 == 2 then
                                        vX *= -1
                                    elsif quadrant2 == 1 then
                                        vX *= -1
                                        vY *= -1
                                    end
                                end
                                @c.velocity = (Pongo::Vector.new(vX,vY))
                                #@b.velocity = (Pongo::Vector.new(nextP[3], nextP[3]))
                                @tmpIL = @inputLayer
                                #addForce()
                            end
                    end
                else
                    if @b.curr.y > 60 and @c.curr.y > 60 then
                        @a.user_data[:shape].fill = '#000000'
                        @b.user_data[:shape].fill = '#000000'
                        @c.user_data[:shape].fill = '#000000'
                        @line.p1.user_data[:shape].fill = '#000000'
                        @line2.p1.user_data[:shape].fill = '#000000'
                    end
                end
                
                # up down hantei you
                @upDownNew = @c.curr.y
                if @upDownOld != nil then
                    if @upDownNew > @upDownOld then
                        @upDown = 'up'
                    else
                        @upDown = 'down'
                    end
                end
                @upDownOld = @upDownNew


                # renderer

                @buf.each do |v|
                    @canvas.delete(v)
                end
                @buf = []
                @buf << TkcLine.new(@canvas, a.x, a.y, a.x, a.y-100, :fill=>'red')
                @buf << TkcLine.new(@canvas, b.x, b.y, b.x, b.y-100, :fill=>'red')
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
                                    :text=>rn1.to_i.to_s)
                @buf << TkcText.new(@canvas, textPosBX, b.y+80,
                                    :text=>rn2.to_i.to_s)
                @buf << TkcLine.new(@canvas, 0, @a.curr.y ,@width, @a.curr.y,:fill=> "#999999")
                if qValue != nil then
                end
                @canvas.raise(@line.p1.user_data[:shape])
                @canvas.raise(@line2.p1.user_data[:shape])
                @canvas.raise(@a.user_data[:shape])
                @canvas.raise(@b.user_data[:shape])
                @canvas.raise(@c.user_data[:shape])
            @canvas.postscript(:file => './ps/tmp'+@count.to_s+'.ps')
            @count += 1
			rescue
				APEngine.log($!)
			end
		end
		Tk.mainloop
	end
    def drawQValue(aValue, aP, aP2, aP3)
        if aValue < 0 then return end
        blue = aValue
        if aValue != 0
            at = 255 / aValue
            blue = aValue.to_i*4
        end
        blue = 255 - blue
        blue = blue.to_s(16)
        if blue.length == 1 then
            blue = '0' + blue
        end

        color = '#'+blue+blue+'FF'
        puts color
        tmpA = @beforeQValueLineA
        tmpB = @beforeQValueLineB
        @beforeQValueLineA = TkcLine.new(@canvas, aP.x, aP.y, aP2.x, aP2.y, :fill=>color)
        @beforeQValueLineB = TkcLine.new(@canvas, aP2.x, aP2.y, aP3.x, aP3.y, :fill=>color)
        if tmpA == nil or tmpB == nil then
            @canvas.lower(@beforeQValueLineA)
            @canvas.lower(@beforeQValueLineB)
        else
            @canvas.raise(@beforeQValueLineA, tmpA)
            @canvas.raise(@beforeQValueLineB, tmpB)
        end
    end
end

t = Test.new
t.setObject()
t.addGroup()
t.run()


