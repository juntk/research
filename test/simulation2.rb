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
        @sdnnLeft = Sdnn.new
        @sdnnRight = Sdnn.new
        @symbol = MySymbol.new
        @qLearning = BasicQLearning.new
        @sdnnReward = 10
        @sdnnInterval = 4

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
        if @enableTk then
            initializeButton()
            initializeLabel()
        end

        """
        シミュレーション
        """
        @tkTimerInterval = 10
        @enableTk = false
        @timeLimit = 50
        @currStopwatch = nil
        @currInput = nil
        @prevInput = nil
        @prevQValue = nil
        @currQValue = nil
        @prevSdnn = nil
        @currSdnn = nil
        @currGlobalRads = []
        @prevGlobalRads = [180,180]
        @force =9.8
        @episode = 0
        @episodeTime = []
        @randomSelectAction = 10
    end
    def initializeButton
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
        font = TkFont.new(['Melno',14,['bold']])
        @labelEpisode = TkLabel.new(:text=> @episode.to_s)
        @labelEpisode.pack(:side=>'right')
        @labelStopwatch = TkLabel.new(:text=> @currStopwatch.to_s)
        @labelStopwatch.pack(:side=>'right')
        @labelCurrInput = TkLabel.new(:text=> '')
        @labelCurrInput.pack(:side=>'left')
        @labelCurrQValue = TkLabel.new(:text=> '', :font=>font)
        @labelCurrQValue.pack(:side=>'left')
        @labelCurrNewQValue = TkLabel.new(:text=> '',:font=>font)
        @labelCurrNewQValue.pack(:side=>'left')
        @labelCurrInputA = TkLabel.new(:text=> '')
        @labelCurrInputA.pack(:side=>'left')
        @labelCurrQValueA = TkLabel.new(:text=> '',:font=>font)
        @labelCurrQValueA.pack(:side=>'left')
        @labelCurrInputB = TkLabel.new(:text=> '')
        @labelCurrInputB.pack(:side=>'left')
        @labelCurrQValueB = TkLabel.new(:text=> '',:font=>font)
        @labelCurrQValueB.pack(:side=>'left')
        @labelDirection = TkLabel.new(:text=> '',:font=>font)
        @labelDirection.pack(:side=>'left')
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
        if @enableTk then
            @labelEpisode.text = 'Episode: ' + @episode.to_s
            @labelEpisode.pack()
        end
        @currStopwatch = 1
        @randomSelectAction += 1
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
    def start(sleepSec)
        yield
        sleep sleepSec
    end
    def run()
        start(@tkTimerInterval/1000.0) do ||
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
                if @enableTk then
                    @labelStopwatch.text = 'time: ' + @currStopwatch.to_s
                    @labelStopwatch.pack()
                end

                # アクロボットのパラメータ表示
                @currGlobalRads = @acrobot.getGlobalRadiusAtArms()
                @currRads = @acrobot.getRadiusAtArms()
                speeds = @acrobot.getSpeedAtArms()
                vectorSpeeds = @acrobot.getVectorSpeedAtArms()
                angularVelocitys = getAngularVelocity().map {|v|v=normalizeAngularVelocity(v)}

                """
                SDNN
                """
                rads = @currRads.map {|v|v=normalizationGlobalRadians(v)}
                @currInput = [rads[0], rads[1], angularVelocitys[0], angularVelocitys[1]]
                # tk
                # @sdnnIntervalごとにチェック
                if isGoal() or @currStopwatch % 20 == 0 then
                    # 次の行動を選択
                    direction, @currQValue, @currSdnn = selectAction(@currInput)
                    if @enableTk then
                        @labelCurrInput.text = "Input:" + @currInput.join(",") + ":"
                        @labelCurrQValue.text = "Curr:"+@currQValue.to_s
                    end
                    # トルクを与える
                    addForce(direction)
                    if @prevInput != nil then
                        reward = 0
                        if isGoal() then
                            reward = @sdnnReward
                        elsif isBad() then
                            reward = -5
                        end
                        newQValue = learningSdnn(@prevSdnn, @prevInput, @prevQValue, @currQValue, reward)
                        # tk
                        if @enableTk then
                            @labelCurrNewQValue.text = "New:"+newQValue.to_s
                        end
                    end
                    if isGoal()then
                        reset()
                    end
                    @prevInput = @currInput
                    @prevQValue = @currQValue
                    @prevSdnn = @currSdnn
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
        run()
    end
    def readSdnn(sdnn, input, dump=false)
        qValue = sdnn.read(input)
        if dump then dumpSdnn(input, qValue) end
        return qValue
    end
    def learningSdnn(sdnn, input, oldQValue, maxQValue, reward)
        teacher = @qLearning.getNewQValue(oldQValue, reward, maxQValue).to_i
        puts teacher
        sdnn.learning(input, teacher)
        newQValue = readSdnn(sdnn, input, true)
        return newQValue
    end
    def selectAction(input)
        direction = ""
        maxQValue = 0
        currSdnn = nil
        # 現在の行動価値を取得
        qValueRight = readSdnn(@sdnnRight, input, true)
        qValueLeft = readSdnn(@sdnnLeft, input, true)
        # ランダム性
        isRandom = false
        if rand(@randomSelectAction) == 0 then
            isRandom = true
        end
        p ['isRandom', isRandom]
        # 行動価値の比較
        if qValueRight > qValueLeft and isRandom == false then
            direction = "R"
            maxQValue = qValueRight
            currSdnn = @sdnnRight
        elsif qValueLeft > qValueRight and isRandom == false then
            direction = "L"
            maxQValue = qValueLeft
            currSdnn = @sdnnLeft
        elsif
            if rand(2) == 1 then
                direction = "R"
                maxQValue = qValueRight
                currSdnn = @sdnnRight
            else
                direction = "L"
                maxQValue = qValueLeft
                currSdnn = @sdnnLeft
            end
        end
        if @enableTk then
            @labelCurrQValueA.text = "R:" + qValueRight.to_s
            @labelCurrQValueB.text = "L:"+qValueLeft.to_s
            @labelDirection.text = "Direction:"+direction
        end
        return direction, maxQValue, currSdnn
    end
    def normalizeAngularVelocity(v)
        tmp = 1000 / @tkTimerInterval
        v /= tmp
        v /= 8
        v += 50
        # normalize
        # 0...50の範囲で表現できるように
        return v.to_i
    end
    def denormalizeAngularVelocity(v)
        tmp = 1000 / @tkTimerInterval
        v -= 50
        v *= 8
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
        if moveValue < 1 then
            puts "BAD!!"
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
    def addForce(direction)
        globalRad2 = @currGlobalRads[1]
        p ['globalRad2',globalRad2]
        vectorX = 0
        vectorY = 0
        if direction == "R" then
            if globalRad2 >= 0 and globalRad2 < 90 then
                vectorX = 1
                vectorY = 1
            elsif globalRad2 >= 90 and globalRad2 < 180 then
                vectorX = -1
                vectorY = 1
            elsif globalRad2 >= 180 and globalRad2 < 270 then
                vectorX = -1
                vectorY = -1
            elsif globalRad2 >= 270 and globalRad2 < 360 then
                vectorX = 1
                vectorY = -1
            end
        elsif direction == "L" then
            if globalRad2 == 0 then
                vectorX = -1
                vectorY = 1
            elsif globalRad2 > 0 and globalRad2 <= 90 then
                vectorX = -1
                vectorY = -1
            elsif globalRad2 > 90 and globalRad2 <= 180 then
                vectorX = 1
                vectorY = -1
            elsif globalRad2 > 180 and globalRad2 <= 270 then
                vectorX = 1
                vectorY = 1
            elsif globalRad2 > 270 and globalRad2 <= 360 then
                vectorX = -1
                vectorY = 1
            end
        end
        vector = Pongo::VectorForce.new(false,
                                        vectorX * @force,
                                        vectorY * @force)
        @acrobot.joint3.add_force(vector)
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
