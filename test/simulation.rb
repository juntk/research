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
        @sdnn = nil
        @sdnnLeft = Sdnn.new
        @sdnnRight = Sdnn.new
        @symbol = MySymbol.new
        @qLearning = BasicQLearning.new
        @sdnnReward = 25
        @sdnnInterval = 20

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
        @tkTimerInterval = 10
        @timeLimit = 50
        @currStopwatch = nil
        @prevInput = nil
        @currGlobalRads = []
        @prevGlobalRads = [180,180]
        @speedJoint3 = 9.8
        @episode = 0
        @episodeTime = []
    end
    def initializeButton
        """
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
        """

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


        @labelEpisode = TkLabel.new(:text=> @episode.to_s)
        @labelEpisode.pack(:side=>'right')
        @labelStopwatch = TkLabel.new(:text=> @currStopwatch.to_s)
        @labelStopwatch.pack(:side=>'right')
        @labelNewQValue = TkLabel.new(:text=> '')
        @labelNewQValue.pack(:side=>'right')
        @labelQValue = TkLabel.new(:text=> '')
        @labelQValue.pack(:side=>'right')


    end

    def resetArms()
        puts "resetArms"
        @acrobot.joint2.curr = Pongo::Vector.new(
            @windowWidth/2,
            @acrobot.armPositionByTop + @acrobot.arm1.length
        )
        @acrobot.joint3.curr = Pongo::Vector.new(
            @windowWidth/2,
            @acrobot.armPositionByTop + @acrobot.arm1.length + @acrobot.arm2.length
        )
        # 初期速度
        @acrobot.joint2.velocity = Pongo::Vector.new(0,0)
        @acrobot.joint3.velocity = Pongo::Vector.new(0,0)
    end
    def reset()
        puts "reset"
        log()
        resetArms()
        @episode += 1
        @labelEpisode.text = 'Episode: ' + @episode.to_s
        @labelEpisode.pack()
        @currStopwatch = 1
    end
    def log()
        # Learning Curves
        strLC = ""
        if @currStopwatch == nil then
            strLC += "Date: " + Time.now.to_s + "\n"
        else
            strLC += @episode.to_s + "," + @currStopwatch.to_s + "\n"
        end
        f = open('logLearningCurves.txt','a')
        f.write(strLC)
        f.close()
    end
    def logQValue()
        puts "logQValue()"
        numRad1 = 180 / @sdnnInterval
        numRad2 = 180 / @sdnnInterval
        angularVelocity = [9, 18, 27] # => [-180, 0, 180]
        input = []
        str = "Date: " + Time.now.to_s + "\n"
        f = open('logQValue.txt', 'a')
        f.write(str)
        angularVelocity.each do |v|
            angularVelocity.each do |v2|
                numRad1.times do |r1|
                    numRad2.times do |r2|
                        input = [r1, r2, v, v2]
                        qValue = readSdnn(input, true)
                        str = '['
                        input.each_with_index do |x, i|
                            str += x.to_s
                            if i == input.length - 1 then
                                str += ']'
                            else
                                str += ','
                            end
                        end
                        str += ':' + qValue.to_s + "\n"
                        f.write(str)
                    end
                end
            end
        end
        f.close()
    end
    def run()
        TkTimer.start(@tkTimerInterval) do |timer|
            begin
                APEngine.step
                APEngine.draw
            rescue
                APEngine.log("#{$!.message}\n#{$!.backtrace.join("\n")}")
            end
            begin
                # 実行時間
                if @currStopwatch == nil then
                    reset()
                elsif @currStopwatch >= @timeLimit*(1000/@tkTimerInterval) then
                    reset()
                end
                @labelStopwatch.text = 'time: ' + @currStopwatch.to_s
                @labelStopwatch.pack()

                # アクロボットのパラメータ表示
                @currGlobalRads = @acrobot.getGlobalRadiusAtArms()
                @currRads = @acrobot.getRadiusAtArms()
                speeds = @acrobot.getSpeedAtArms()
                vectorSpeeds = @acrobot.getVectorSpeedAtArms()
                angularVelocitys = getAngularVelocity().map {|v|v=normalizeAngularVelocity(v)}

                # 左画面右画面判定
                if @acrobot.joint2.curr.x < @windowWidth / 2 then
                    @sdnn = @sdnnLeft
                elsif @acrobot.joint2.curr.x > @windowWidth / 2 then
                    @sdnn = @sdnnRight
                else
                    if rand(2) == 1 then
                        @sdnn = @sdnnLeft
                    else
                        @sdnn = @sdnnRight
                    end
                end

                """
                SDNN
                """
                # @sdnnIntervalごとにチェック
                #if isGoal() or @currGlobalRads[0] % @sdnnInterval == 0 or @currGlobalRads[1] % @sdnnInterval == 0 then 
                #if isGoal()  or @currGlobalRads[1] % @sdnnInterval == 0 then 
                if isGoal() or @currStopwatch % 10 == 0 then
                    #rads = @currGlobalRads.map {|v|v=normalizationGlobalRadians(v)}
                    rads = @currRads.map {|v|v=normalizationGlobalRadians(v)}
                    dump(rads, speeds, vectorSpeeds, angularVelocitys)

                    input = [rads[0], rads[1], angularVelocitys[0], angularVelocitys[1]]
                    if @prevInput == nil or @prevInput != input then
                    #if true then
                        @prevInput = input
                        # 現在の行動価値を取得
                        qValue = readSdnn(input, true)
                        # 次の行動を選択
                        nextRad, maxQValue = selectAction(input)
                        # トルクを与える
                        addForce(@currGlobalRads[1], nextRad)
                        reward = 0
                        if isGoal() then
                            reward = @sdnnReward
                        elsif isBad() then
                            reward = -10
                        end
                        learningSdnn(input, qValue, reward, maxQValue)
                        if isGoal() then
                            reset()
                        end
                    end
                    @prevGlobalRads = @currGlobalRads
                end
                if @prevGlobalRads == [] then
                    @prevGlobalRads = @currGlobalRads
                end
                @prevStopwatch = @currStopwatch
                @currStopwatch += 1
                
                if @episode > 100 then
                    logQValue()
                    return
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
        teacher = @qLearning.getNewQValue(oldQValue, reward, maxQValue).to_i
        puts teacher
        @sdnn.learning(input, teacher)
        newQValue = readSdnn(input, true)
        @labelQValue.text = "Q: " + oldQValue.to_s
        @labelNewQValue.text = "newQ: " + newQValue.to_s
    end
    def selectAction(nowInput)
        inputA = []
        inputB = []
        inputA += nowInput
        inputB += nowInput
        resultA = @currGlobalRads[1]
        resultB = @currGlobalRads[1]
        if nowInput[0] == 0 and nowInput[0] then
            inputA[1] += 1
            inputB[1] += 1
            resultA += @sdnnInterval
            resultB += @sdnnInterval
            @sdnn = @sdnnRight
            qValueA = readSdnn(inputA, true)
            @sdnn = @sdnnLeft
            qValueB = readSdnn(inputB, true)
        else
            inputA[1] += 1
            resultA += @sdnnInterval
            qValueA = readSdnn(inputA, true)
            if inputB[1] >= 1 then
                inputB[1] -= 1
                resultB -= @sdnnInterval
            end
            qValueB = readSdnn(inputB, true)
        end
        if qValueA < qValueB then
            @sdnn = @sdnnLeft
            return resultB, qValueB
        elsif qValueA > qValueB then
            @sdnn = @sdnnRight
            return resultA, qValueA
        else
            if rand(2) == 1 then
                @sdnn = @sdnnRight
                return resultA, qValueA
            else
                @sdnn = @sdnnLeft
                return resultB, qValueB
            end
        end
    end
    def normalizeAngularVelocity(v)
        tmp = 1000 / @tkTimerInterval
        v /= tmp
        # normalize
        v += 360
        # 0...50の範囲で表現できるように
        v /= 20
        return v.to_i
    end
    def denormalizeAngularVelocity(v)
        tmp = 1000 / @tkTimerInterval
        v *= 20
        v -= 360
        v *= tmp
        return v
    end
    def getAngularVelocity()
        tmp = 1000 / @tkTimerInterval
        result = []
        [0,1].each do |i|
            moveValue = 0 
            if @currGlobalRads[i] <= @prevGlobalRads[i] then
                moveValue = @prevGlobalRads[i] - @currGlobalRads[i]
                moveValue *= -1
            elsif @currGlobalRads[i] >= @prevGlobalRads[i] then
                moveValue = @currGlobalRads[i] - @prevGlobalRads[i]
            end
            moveValue *= tmp
            result << moveValue
        end
        return result
    end
    def isBad()
        moveValue = 0 
        if @currGlobalRads[0] <= @prevGlobalRads[0] then
            moveValue = @prevGlobalRads[0] - @currGlobalRads[0]
        elsif @currGlobalRads[0] >= @prevGlobalRads[0] then
            moveValue = @currGlobalRads[0] - @prevGlobalRads[0]
        end
        if moveValue < 2 then
            return true
        else
            return false
        end
    end
    def isGoal()
        goal = @acrobot.joint1.curr.y - @acrobot.arm1.length
        if @acrobot.joint3.curr.y < goal then
            return true
        else
            return false
        end
    end
    def addForce(oldRad, newRad)
        p oldRad, newRad
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
        else
            tmpX = 0
        end
        if y < 0 then
            tmpY = -1
        elsif y > 0 then
            tmpY = 1
        else
            tmpY = 0
        end
        if vectorStr == "L" then
            vectorX = tmpX * -1
            vectorY = tmpY
        elsif vectorStr == "R" then
            vectorX = tmpX
            vectorY = tmpY
        end
        v = @acrobot.joint3.velocity
        v = Pongo::Vector.new(0,0)
        @acrobot.joint3.velocity = Pongo::Vector.new(v.x + vectorX * @speedJoint3,
                                                     v.y + vectorY * @speedJoint3 * 1.2)
        return 
    end
    def normalizationGlobalRadians(globalRadians)
        """
        正規化
        """
        globalRadians /= @sdnnInterval
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
simulation.logQValue()
