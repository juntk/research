#encoding:utf-8
require 'tk'
require 'pongo'
require 'pongo/renderer/tk_renderer'
require 'pongo/logger/standard_logger'
require './sdnn/main.rb'
require "./ReinforcementLearning/basicQLearning4.rb"
require './simulation/MyThread.rb'

include Pongo

class Test
	attr_accessor :width, :height

	def initialize
        @thread = MyThread.new
        @thread.threadConcurrency = 1
        @thread.mode = 1
        @checker = ''
        @qValuePot = {}
        @throwSet = [-1,-1]
        @sdnn = Sdnn.new
        @radRate = 15
        @r1Raw = @r2Raw = @r1Fix = @r2Fix = 0
        @nowLearning = false
        @bql = BasicQLearning.new
        @bql.alpha = 0.5
        @bql.gamma = 0.5
        @reward = 60 # housyuu
		@width = 640
		@height = 480
		@gravity = 9.8
		@lineWidth = 150
        @addVelocity = 15
        @enableLearning = true
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
            @enableLearning = true
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
            @enableLearning = false
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
            @enableLearning = false
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
        return tan
    end
    def learnAndSelect(obj)
        r1Fix = obj[0]
        r2Fix = obj[1]
        r1Raw = obj[2]
        r2Raw = obj[3]
        radRate = obj[4]
        qvalue = obj[5]
        lineLength = obj[6]
        line2Length = obj[7]
        ax = obj[8]
        bx = obj[9]
        by = obj[10]
        cx = obj[11]
        cy = obj[12]
        reward = obj[13]
        addVelocity = obj[14]

        p obj
        # sdnn

        """
        if @qvalue == true and @b.curr.x <= 320 and @c.curr.x <= 320 and r1Fix.to_i % @radRate == 0 then
        """
        if qvalue == true and (r1Raw.to_i % radRate == 0 or r2Raw.to_i % radRate == 0) then

            inputLayer = [lineLength.to_i/radRate, line2Length.to_i/radRate,r1Fix.to_i,  r2Fix.to_i]
            if @tmpIL2 == inputLayer then
                return
            else
                @tmpIL2 = inputLayer
            end
            if cy <= 60 or by <= 60 and @tmpILA != inputLayer and @enableLearning == true then
                qValue = @sdnn.learning(inputLayer,reward)
                @qValuePot[inputLayer.to_s] = qValue
                @tmpILA = inputLayer
                puts qValue
            else
                #test
                @radRate2 = 1
                pattern = []
                pattern << [r1Fix+@radRate2, r2Fix, -1*addVelocity, 0]
                pattern << [r1Fix+@radRate2, r2Fix+@radRate2, -1*addVelocity,-1*addVelocity]
                pattern << [r1Fix, r2Fix+@radRate2, 0, -1*addVelocity]
                pattern << [r1Fix-@radRate2, r2Fix, addVelocity, 0]
                pattern << [r1Fix-@radRate2, r2Fix-@radRate2,addVelocity,addVelocity]
                pattern << [r1Fix, r2Fix-@radRate2, 0, addVelocity]
                max = 0
                maxi = nil
                print 'check sentaku'
                pattern.shuffle.each_with_index do |v,i|
                    if v[0] < 0 then
                        v[0] = 0
                    end
                    if v[1] < 0 then
                        v[1] = 0
                    end
                    tmpInputLayer = [lineLength.to_i/radRate, line2Length.to_i/radRate,v[0].to_i,  v[1].to_i]
                    p tmpInputLayer

                    p @qValuePot
                    reward = @qValuePot[tmpInputLayer.to_s]
                    print '!', reward
                    puts
                    if reward > max then
                        max = reward
                        maxi = i
                    end
                end
            end
                if maxi != nil and @tmpIL != inputLayer then
                    if @enableLearning == true then
                        oldQValue = @qValuePot[tmpInputLayer.to_s]
                        print 'old',oldQValue
                        puts
                        newQValue = @bql.getNewQValue(oldQValue, 0, max).to_i
                        print 'new', newQValue
                        puts
                        qValue = @sdnn.learning(inputLayer,newQValue)
                        @qValuePot[inputLayer.to_s] = qValue
                    end
                end
        end
        
        """
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
        """
    end

    def selectNext(r1Fix, r2Fix)
        if @qvalue == true and (@r1Raw.to_i % @radRate == 0 or @r2Raw.to_i % @radRate == 0) then
            @radRate2 = 1
            pattern = []
            pattern << [r1Fix+@radRate2, r2Fix, -1*@addVelocity, 0]
            pattern << [r1Fix+@radRate2, r2Fix+@radRate2, -1*@addVelocity,-1*@addVelocity]
            pattern << [r1Fix, r2Fix+@radRate2, 0, -1*@addVelocity]
            pattern << [r1Fix-@radRate2, r2Fix, @addVelocity, 0]
            pattern << [r1Fix-@radRate2, r2Fix-@radRate2,@addVelocity,@addVelocity]
            pattern << [r1Fix, r2Fix-@radRate2, 0, @addVelocity]
            max = 0
            maxi = nil
            pattern.shuffle.each_with_index do |v,i|
                if v[0] < 0 then
                    v[0] = 0
                end
                if v[1] < 0 then
                    v[1] = 0
                end
                tmpInputLayer = [@lineLength.to_i/@radRate, @line2Length.to_i/@radRate,v[0].to_i,  v[1].to_i]
                p tmpInputLayer

                reward = @qValuePot[tmpInputLayer.to_s]

                if reward != nil then
                    puts
                    if reward > max then
                        max = reward
                        maxi = i
                    end
                end
            if maxi != nil then

                nextP = pattern[maxi]
                @c.velocity = (Pongo::Vector.new(nextP[2], nextP[2]))
                @b.velocity = (Pongo::Vector.new(nextP[3], nextP[3]))
                @tmpIL = @inputLayer
                #addForce()
            else
                if @count < 5 then
                    @c.velocity = Pongo::Vector.new(@c.velocity.x+10,@c.velocity.y)
                    @b.velocity = Pongo::Vector.new(@b.velocity.x+5,@b.velocity.y)
                end
            end
            end
        end
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
                @r1Raw = getTan(lineVector1, quadrant1)
                @r2Raw = getTan(lineVector2, quadrant1)
                

                r1Fix = @r1Raw / @radRate
                r2Fix = @r2Raw / @radRate
                r1Fix = r1Fix.to_i
                r2Fix = r2Fix.to_i

                obj = [r1Fix, r2Fix, @r1Raw, @r2Raw, @radRate, @qvalue,@lineLength, @line2Length, @a.curr.x, @b.curr.x, @b.curr.y, @c.curr.x, @c.curr.y, @reward, @addVelocity]
                methodObject = self.method(:learnAndSelect)
                if @qvalue == true and (@r1Raw.to_i % @radRate == 0 or @r2Raw.to_i % @radRate == 0) then
                    p @checker
                    if @checker.to_s != [r1Fix, r2Fix].to_s then
                        @thread.addThread(methodObject, obj)
                        p @qValuePot
                    end
                end
                    if @checker.to_s != [r1Fix, r2Fix].to_s then
                        selectNext(r1Fix, r2Fix)
                    end
                @thread.controlThread()
                        @checker = [r1Fix, r2Fix]
                """
                if r1Fix != @throwSet[0] and r2Fix != @throwSet[1] then
                    selectNext(r1Fix, r2Fix)
                end
                """

                # renderer
                # change color when learning
                if @nowLearning then
                    @a.user_data[:shape].fill = '#FF0000'
                    @b.user_data[:shape].fill = '#FF0000'
                    @c.user_data[:shape].fill = '#FF0000'
                    @line.p1.user_data[:shape].fill = '#FF0000'
                    @line2.p1.user_data[:shape].fill = '#FF0000'
                else
                    @a.user_data[:shape].fill = '#000000'
                    @b.user_data[:shape].fill = '#000000'
                    @c.user_data[:shape].fill = '#000000'
                    @line.p1.user_data[:shape].fill = '#000000'
                    @line2.p1.user_data[:shape].fill = '#000000'
                end

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
                                    :text=>@r1Raw.to_i.to_s)
                @buf << TkcText.new(@canvas, textPosBX, b.y+80,
                                    :text=>@r2Raw.to_i.to_s)
                @buf << TkcLine.new(@canvas, 0, @a.curr.y ,@width, @a.curr.y,:fill=> "#999999")
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


