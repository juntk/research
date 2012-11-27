# encoding: utf-8

require 'readline'
require 'tk'
require 'rubygems'
require 'pongo'
require 'pongo/renderer/tk_renderer'
require 'pongo/logger/standard_logger'
require 'sdnn.rb'
require 'qLearning.rb'
require 'mySymbol.rb'
require 'acrobot.rb'

include Pongo

class Simulation
    def initialize
        """
        Acrobot
        """
        @windowSize = [640,480]
        @windowWidth = @windowSize[0]
        @windowHeight = @windowSize[1]

        @acrobot = Acrobot.new(@windowSize)
        
        
        """
        SDNN
        """
        @sdnn = Sdnn.new
        @symbol = MySymbol.new
        @qLearning = BasicQLearning.new
        @sdnnReward = 60
        @sdnnInterval = 10

        """
        Pongo
        """
        root = TkRoot.new { title 'Acrobot' }
        @canvas = TkCanvas.new(root, :width=>@windowWidth, :height=>@windowHeight)
        @canvas.pack
        @buf = []
        APEngine.setup
        APEngine.renderer = Renderer::TkRenderer.new(@canvas)
        APEngine.logger = Logger::StandardLogger.new
        APEngine.add_force(VectorForce.new(false,0 , @acrobot.env.gravity))
        APEngine.damping = @acrobot.env.damping
        APEngine.add_group(@acrobot)

        """
        Tk
        """
        initializeButton()

        """
        シミュレーション
        """
        @timeStart = nil
        @prevInput = nil
    end
    def initializeButton
        # start
        buttonStartLQ = TkButton.new(:text=> 'start(+Learn+Qvalue)')
        buttonStartLQ.command {
            @acrobot.initializeArms()
            @pongoIsAlive = true
            @learning = true
            @qvalue = true
        }
        buttonStartLQ.pack(:side=>'right')

        # restart (not learning)
        buttonStartQ = TkButton.new(:text=> 'start(-Learn+Qvalue)')
        buttonStartQ.command {
            @acrobot.initializeArms()
            @learning = false
            @qvalue = true
            @pongoIsAlive = true
        }
        buttonStartQ.pack(:side=>'right')

        # restart (not learning)
        buttonStart = TkButton.new(:text=> 'start(-Learn-Qvalue)')
        buttonStart.command {
            @acrobot.initializeArms()
            @learning = false
            @qvalue = false
            @pongoIsAlive = true
        }
        buttonStart.pack(:side=>'right')

        # stop
        buttonStop = TkButton.new(:text=> 'stop')
        buttonStop.command {
            @pongoIsAlive = false
        }
        buttonStop.pack(:side=>'right')
        
        # power
        buttonPower = TkButton.new(:text=> 'power')
        buttonPower.command {
            @acrobot.joint3.velocity = Pongo::Vector.new(1,1)
        }
        buttonPower.pack(:side=>'right')
    end
    def run()
        TkTimer.start(10) do |timer|
            begin
                APEngine.step
                APEngine.draw
            rescue
                APEngine.log("#{$!.message}\n#{$!.backtrace.join("\n")}")
            end
            begin
                if @timeStart == nil or Time.now.to_i - @timeStart >= 50 then
                    @timeStart = Time.now.to_i
                    puts 'call'
                    @acrobot.initializeArms()
                end
                # アクロボットのパラメータ表示
                globalRads = @acrobot.getGlobalRadiusAtArms()
                speeds = @acrobot.getSpeedAtArms()
                vectorSpeeds = @acrobot.getVectorSpeedAtArms()
                angularVelocitys = @acrobot.getAngularVelocityAtArms().map {|v|v=normalizationAngularVelocity(v)}

                """
                SDNN
                """
                # @sdnnIntervalごとにチェック
                #if globalRads[0] % @sdnnInterval == 0 or globalRads[1] % @sdnnInterval == 0 then 
                if globalRads[0] % @sdnnInterval == 0  then 
                    rads = globalRads.map {|v|v=normalizationGlobalRadians(v)}
                    dump(rads, speeds, vectorSpeeds, angularVelocitys)

                    input = [rads[0], rads[1], angularVelocitys[0], angularVelocitys[1]]
                    if @prevInput == nil or @prevInput != input then
                        @prevInput = input
                        # 現在の行動価値を取得
                        qValue = readSdnn(input, true)
                        # 次の行動を選択
                        nextRad, maxQValue = selectAction(input)
                        # トルクを与える
                        addForce(rads[1], nextRad)
                        if isGoal() then
                            learningSdnn(input, qValue, @sdnnReward, maxQValue)
                        elsif rads[0] > 17 and rads[0] < 19 then
                            learningSdnn(input, qValue, -100, maxQValue)
                        else
                            learningSdnn(input, qValue, 0, maxQValue)
                        end
                    end
                end
            rescue
                puts($!)
            end
        end
        Tk.mainloop
    end
    def readSdnn(input, dump=false)
        qValue = @sdnn.read(input)
        if dump then dumpSdnn(input, qValue) end
        return qValue
    end
    def learningSdnn(input, oldQValue, reward, maxQValue=nil)
        if maxQValue == nil then
            teacher = @qLearning.getNewQValue4Reward(oldQValue, reward)
        else
            teacher = @qLearning.getNewQValue(oldQValue, reward, maxQValue)
        end
        @sdnn.learning(input, teacher)
    end
    def selectAction(nowInput)
        inputA = []
        inputA += nowInput
        inputA[1] += @sdnnInterval
        qValueA = readSdnn(inputA, true)
        inputB = []
        inputB += nowInput
        if inputB[1] >= 10 then
            inputB[1] -= @sdnnInterval
        end
        qValueB = readSdnn(inputB, true)
        if qValueA < qValueB then
            return inputA[1], qValueB
        elsif qValueA > qValueB then
            return inputB[1], qValueA
        else
            return inputA[1], qValueA
        end
    end
    def isGoal()
        goal = @acrobot.joint1.curr.y
        if @acrobot.joint3.curr.y < goal then
            return true
        else
            return false
        end
    end
    def addForce(oldRad, newRad)
        oldRad = denormalizationGlobalRadians(oldRad)
        newRad = denormalizationGlobalRadians(newRad)
        vectorStr = ''
        vectorX = 0
        vectorY = 0
        if newRad < oldRad then
            vectorStr = "L"
        elsif newRad > oldRad then
            vectorStr = "R"
        else
            r = rand(2)
            if r == 1 then
                vectorStr = "L"
            else
                vectorStr = "R"
            end
        end
        x = Math.cos(oldRad)
        y = Math.sin(oldRad)
        if x < 0 then
            tmpX = -1
        elsif x > 0 then
            tmpX = 1
        end
        if y < 0 then
            tmpY = -1
        elsif y > 0 then
            tmpY = 1
        end
        if vectorStr == "L" then
            vectorX = tmpX * -1
            vectorY = tmpY
        elsif vectorStr == "R" then
            vectorX = tmpX
            vectorY = tmpY
        end
        @acrobot.joint3.velocity = Pongo::Vector.new(vectorX*2, vectorY*2)
        return 
    end
    def normalizationAngularVelocity(angularVelocity)
        """
        正規化
        """
        # バイアス
        bias = 50 / 2
        angularVelocity *= 1000
        angularVelocity += bias
        return angularVelocity.to_i
    end
    def normalizationGlobalRadians(globalRadians)
        """
        正規化
        """
        globalRadians /= 10
        return globalRadians.to_i
    end
    def denormalizationGlobalRadians(normalizedGlobalRadians)
        """
        正規化
        """
        normalizedGlobalRadians *= 10
        return normalizedGlobalRadians.to_i
    end
    def dumpSdnn(input, output)
        ENV['COLUMNS'].to_i.times do |t| print '=' end
        puts
        puts "[SDNN]"
        print "Input: "
        p input
        print "Output: "
        puts output
        puts
    end
    def dump(rads, speeds, vectorSpeeds, angularVelocitys)
        ENV['COLUMNS'].to_i.times do |t| print '-' end
        puts
        puts 'radius: 角度','speed: 速さ'
        puts 'speedVector: 速度方向'
        puts "\tv > 0: right(時計回り)","\tv < 0: left(逆時計回り)" 
        puts 'angularVelocity: 角速度'
        puts "\t正規化: new = old * 100 + (コード化により表現できる最大値/2)"
        puts
        print 'link1: '
        print ["radius=",rads[0],",	speed=",speeds[0].to_i,",	speedVector=",vectorSpeeds[0]]
        print [",	angularVelocity(正規化)=", angularVelocitys[0]]
        puts
        print 'link2: '
        print ["radius=",rads[1],",	speed=",speeds[1].to_i,",	speedVector=",vectorSpeeds[1]]
        print [",	angularVelocity(正規化)=", angularVelocitys[1]]
        puts
    end
end

Readline.readline('',true)
simulation = Simulation.new
simulation.run()
