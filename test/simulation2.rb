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
    attr_accessor :enableTk
    def initialize
        """
        GUI
        """
        @enableTk = true
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
        @sdnnInterval = 2

        """
        Pongo
        """
        APEngine.setup
        if @enableTk then
            root = TkRoot.new { title 'Acrobot' }
            @canvas = TkCanvas.new(root, :width=>@windowWidth, :height=>@windowHeight)
            @canvas.pack
            @buf = []
            APEngine.renderer = Renderer::TkRenderer.new(@canvas)
        else
            APEngine.renderer = Renderer::Renderer.new()
        end
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
        @tkTimerInterval = 67
        @timeLimit = 5000
        @currStopwatch = nil
        @currInput = nil
        @prevInput = nil
        @prevQValue = nil
        @currQValue = nil
        @prevSdnn = nil
        @currSdnn = nil
        @currGlobalRads = []
        @prevGlobalRads = [180,180]
        @force = 9.8
        @episode = 0
        @episodeTime = []
        @randomSelectAction = 11
    end
    def initializeButton
        # stop
        buttonStop = TkButton.new(:text=> 'stopLearning')
        buttonStop.command {
            @isStopLearning = true
        }
        buttonStop.pack(:side=>'right')
        
        # power
        buttonPower = TkButton.new(:text=> 'powerR')
        buttonPower.command {
            addForce("R")
        }
        buttonPower.pack(:side=>'right')
        # power
        buttonPower = TkButton.new(:text=> 'powerL')
        buttonPower.command {
            addForce("L")
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
        path = 'logLearningCurvesOnly.txt'
        if File.exist?(path) then
            File.delete(path)
        end
        @currStopwatch = 1
        @randomSelectAction -= 1
    end
    def log()
        # Learning Curves
        strLC = ""
        str = ""
        if @currStopwatch == nil then
            strLC += "Date: " + Time.now.to_s + "\n"
        else
            str = @episode.to_s + "," + @currStopwatch.to_s + "\n"
            strLC += str
        end
        f = open('logLearningCurves.txt','a')
        f.write(strLC)
        f.close()
        path = 'logLearningCurvesOnly.txt'
        af = open(path,'a')
        af.write(str)
        af.close()
    end
    def logQValue()
        puts "logQValue()"
        numRad1 = ((180 / @sdnnInterval))
        numRad2 = ((180 / @sdnnInterval))
        angularVelocity = [22,50,77] # => [-180, 0, 180]
        input = []
        str = "Date: " + Time.now.to_s + "\n"
        f = open('logQValue.txt', 'a')
        af = open('logQValueOnly.txt', 'w')
        f.write(str)
        angularVelocity.each do |v|
            angularVelocity.each do |v2|
                numRad1.times do |r1|
                    numRad2.times do |r2|
                        input = [r1, r2, v, v2]
                        qValueRight = readSdnn(@sdnnRight,input, true)
                        qValueLeft = readSdnn(@sdnnLeft,input, true)
                        qValue = qValueRight + qValueLeft
                        str = ''
                        input.each_with_index do |x, i|
                            str += x.to_s
                            str += ','
                        end
                        str += qValue.to_s + "\n"
                        f.write(str)
                        af.write(str)
                    end
                end
            end
        end
        f.close()
        af.close()
    end
    def start(sleepSec)
        yield
        sleep sleepSec
    end
    def run()
        TkTimer.start(@tkTimerInterval) do |timer|
        #start(@tkTimerInterval/1000.0) do ||
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
                p @currInput
                # tk
                # @sdnnIntervalごとにチェック
                if (isGoal() or @currStopwatch.to_i != @prevStopwatch.to_i) and @isStopLearning != true then
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
                        elsif isBad(rads) then
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
                @currStopwatch += 0.01*@tkTimerInterval
                
                if @episode > 100 then
                    logQValue()
                    return 'end'
                end
            rescue
                puts($!)
            end
        end
        if @enableTk then
            Tk.mainloop
        else
            return 'loop'
        end
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
        newQValue = 0
        #newQValue = readSdnn(sdnn, input, true)
        return newQValue
    end
    def selectAction(input)
        direction = ""
        maxQValue = 0
        currSdnn = nil
        # 現在の行動価値を取得
        qValue = []
        qValue << Thread.new{['R',readSdnn(@sdnnRight, input, true)]}
        qValue << Thread.new{['L',readSdnn(@sdnnLeft, input, true)]}
        qValueRight = 0
        qValueLeft = 0
        qValue.each do |v|
            if v.value[0].to_s == "R" then
                qValueRight = v.value[1]
            elsif v.value[0].to_s == 'L' then
                qValueLeft = v.value[1]
            end
        end
        p [qValueRight, qValueLeft]
        # ランダム性
        isRandom = false
        percents = [@randomSelectAction, 100-@randomSelectAction]
        if calcGacha(percents) == @randomSelectAction then
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
        v /= 1
        v += 50
        # normalize
        # 0...50の範囲で表現できるように
        return v.to_i
    end
    def denormalizeAngularVelocity(v)
        tmp = 1000 / @tkTimerInterval
        v -= 50
        v *= 1
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
    def isBad(rads)
        if rads[0] < 1 then
            puts "BAD!!"
            return true
        else
            return false
        end
    end
    def isGoal()
        goal = @acrobot.joint1.curr.y - @acrobot.arm1.length
        if @acrobot.joint3.curr.y <= goal then
            return true
        else
            return false
        end
    end
    def calcGacha(percents)
        hit_per = 0
        max = 0

        # 初期確率合計
        percents.each do |per|
         max += per
        end

        for i in 0..(percents.size-1)
         choice_per = rand(max)
         if choice_per < percents[i] || i == percents.size-1
           hit_per = percents[i]
           break
         else
           max -= percents[i]
         end
        end

        hit_per
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
if simulation.enableTk then
simulation.run()
else
    status = 'start'
    while status != 'end' do
        simulation.run()
    end
end
simulation.logQValue()
