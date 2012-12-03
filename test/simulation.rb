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
        @sdnnReward = 50
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
        initializeLabel()

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
    end
    def initializeLabel()
        @labelEpisode = TkLabel.new(:text=> @episode.to_s)
        @labelEpisode.pack(:side=>'right')
        @labelStopwatch = TkLabel.new(:text=> @currStopwatch.to_s)
        @labelStopwatch.pack(:side=>'right')
        @labelCurrInput = TkLabel.new(:text=> '')
        @labelCurrInput.pack(:side=>'left')
        @labelCurrQValue = TkLabel.new(:text=> '')
        @labelCurrQValue.pack(:side=>'left')
        @labelCurrNewQValue = TkLabel.new(:text=> '')
        @labelCurrNewQValue.pack(:side=>'left')
        @labelCurrInputA = TkLabel.new(:text=> '')
        @labelCurrInputA.pack(:side=>'left')
        @labelCurrQValueA = TkLabel.new(:text=> '')
        @labelCurrQValueA.pack(:side=>'left')
        @labelCurrInputB = TkLabel.new(:text=> '')
        @labelCurrInputB.pack(:side=>'left')
        @labelCurrQValueB = TkLabel.new(:text=> '')
        @labelCurrQValueB.pack(:side=>'left')
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
        angularVelocity = [0,20,30,40, 50, 60,70,80,90,99] # => [-180, 0, 180]
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
                        str = ''
                        input.each_with_index do |x, i|
                            str += x.to_s
                            str += ','
                        end
                        str += qValue.to_s + "\n"
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
                rads = @currRads.map {|v|v=normalizationGlobalRadians(v)}
                input = [rads[0], rads[1], angularVelocitys[0], angularVelocitys[1]]
                # tk
                @labelCurrInput.text = input.join(",") + ":"
                """
                if @nextRad == nil then
                    @nextRad, maxQValue = selectAction(input)
                end
                """
                # @sdnnIntervalごとにチェック
                #if isGoal()  or @currGlobalRads[1] % @sdnnInterval == 0 then 
                if isGoal() or @currStopwatch % 10 == 0 then
                #if isGoal() or (speeds[1] <= 1 or speeds[0] <= 1) then
                #if isGoal() or @currGlobalRads[0] % @sdnnInterval == 0 or @currGlobalRads[1] % @sdnnInterval == 0 then 
                #if isGoal() or @currStopwatch == 0 or @nextRad[1] == rads[1] then
                    #rads = @currGlobalRads.map {|v|v=normalizationGlobalRadians(v)}

                    if @prevInput == nil or @prevInput != input then
                    #if true then
                        @prevInput = input
                        # 現在の行動価値を取得
                        qValue = readSdnn(input, true)
                        @labelCurrQValue.text = qValue.to_s
                        # 次の行動を選択
                        @nextRad, maxQValue = selectAction(input)
                        # トルクを与える
                        addForce(@currGlobalRads[1], @nextRad)
                        reward = 0
                        if isGoal() then
                            reward = @sdnnReward
                        elsif isBad() then
                            reward = -5
                        end
                        newQValue = learningSdnn(input, qValue, reward, maxQValue)
                        # tk
                        @labelCurrNewQValue.text = newQValue.to_s
                        #if isGoal() and @currStopwatch >= @timeLimit*(1000/@tkTimerInterval) then
                        if isGoal()then
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
        return newQValue
    end
    def selectAction(nowInput)
        inputA = []
        inputB = []
        inputA += nowInput
        inputB += nowInput
        resultA = @currGlobalRads[1]
        resultB = @currGlobalRads[1]
        # 次の状態の行動価値を取得
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
        # tk
        @labelCurrInputA.text = inputA.join(",") + ":"
        @labelCurrQValueA.text = qValueA.to_s
        @labelCurrInputB.text = inputB.join(",") + ":"
        @labelCurrQValueB.text = qValueB.to_s
        # 行動価値が大きい方を選択
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
        v /= 50
        v += 50
        p ['av',v]
        # normalize
        # 0...50の範囲で表現できるように
        return v.to_i
    end
    def denormalizeAngularVelocity(v)
        tmp = 1000 / @tkTimerInterval
        v -= 50
        v *= 50
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
                moveValue *= -5
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
        if moveValue < 1 then
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
        p [oldRad, newRad]
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
        if vectorStr == "R" then
            if oldRad >= 0 and oldRad < 90 then
                vectorX = 1
                vectorY = 1
            elsif oldRad >= 90 and oldRad < 180 then
                vectorX = -1
                vectorY = 1
            elsif oldRad >= 180 and oldRad < 270 then
                vectorX = -1
                vectorY = -1
            elsif oldRad >= 270 and oldRad < 360 then
                vectorX = 1
                vectorY = -1
            end
        elsif vectorStr == "L" then
            if oldRad == 0 then
                vectorX = -1
                vectorY = 1
            elsif oldRad > 0 and oldRad <= 90 then
                vectorX = -1
                vectorY = -1
            elsif oldRad > 90 and oldRad <= 180 then
                vectorX = 1
                vectorY = -1
            elsif oldRad > 180 and oldRad <= 270 then
                vectorX = 1
                vectorY = 1
            elsif oldRad > 270 and oldRad <= 360 then
                vectorX = -1
                vectorY = 1
            end
        end
        p ['vectorStr', vectorStr]
        p ['vectorX', vectorX]
        p ['vectorY', vectorY]
        v = @acrobot.joint3.velocity
        v = Pongo::Vector.new(0,0)
        @acrobot.joint3.velocity = Pongo::Vector.new(v.x + vectorX * @speedJoint3,
                                                     v.y + vectorY * @speedJoint3)
        return 
    end
    def normalizationGlobalRadians(globalRadians)
        """
        正規化
        """
        globalRadians = globalRadians / @sdnnInterval
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
    def dump(currInput, currInputQValue, currInputNewQValue, currInputA, currInputQValueA,currInputB,currInputQValueB)
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
