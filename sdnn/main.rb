require 'sdnn/network.rb'

class Main
    def initialize
        # 出力層の素子数 
        @outputElementNum = 46
        puts '出力層の素子数:' + @outputElementNum.to_s
        puts
        @n = Network.new(@outputElementNum)
        @inputLayer = [1,1]
        @middleLayer = @n.makeMiddleLayer(@inputLayer)
        @outputLayer = @n.makeOutputLayer(@middleLayer)
        @teacher = 0

        #body = [[9,8,0],[9,1,0],[9,12,0],[9,10,0],[9,4,0],[9,5,0],[9,16,10],[9,17,10]]
        @body = [[1,2,3],[3,4,7],[5,6,11],[7,8,15],[9,10,19],[1,3,4],[2,4,6],[5,7,12],[6,8,14],[9,1,10]]
    end

    def learn(inputLayer, outputLayer, teacher, result, learningRate, n)
        middleLayer = n.makeMiddleLayer(inputLayer)

        outputLayer = n.fixWeight(teacher, result, learningRate, outputLayer, middleLayer)
        return outputLayer
    end
    def check(inputLayer, outputLayer, n)
        middleLayer = n.makeMiddleLayer(inputLayer)
        n.checkFireAtOutputLayer(outputLayer, middleLayer)
        result = n.getAmountValueOfOutput(outputLayer)
        return result
    end
    def learnTest(inputLayer, outputLayer, teacher, result, learningRate, n)
        middleLayer = multiInputVarMode(inputLayer, n)
        outputLayer = n.fixWeight(teacher, result, learningRate, outputLayer, middleLayer)
        return outputLayer
    end
    def multiInputVarMode(inputLayer, n)
        count = 0
        middleLayer = []
        ((inputLayer.size)/2).times do |t|
            middleLayer += n.makeMiddleLayer([inputLayer[count],inputLayer[count+1]])
            count += 2
        end
        return middleLayer
    end
    def checkTest(inputLayer,outputLayer, n, flug = -1)
        middleLayer = multiInputVarMode(inputLayer, n)
        if flug == 0 then
            @outputLayer = n.makeOutputLayer(middleLayer)
            outputLayer = @outputLayer
        end
        n.checkFireAtOutputLayer(outputLayer, middleLayer)
        result = n.getAmountValueOfOutput(outputLayer)
        return result
    end
    def test()
        @body = [[1,2,3,4,10],[5,6,7,8,12],[9,10,11,12,13],[13,14,15,16,15],[17,18,19,20,17]]
        @body += [[25,26,27,28,19],[29,30,31,32,20],[33,34,35,36,21],[37,38,39,40,22],[41,42,43,44,23]]
        10000.times do |m|
            puts (m+1).to_s + '回目の学習'
            day1 = Time.now
            @body.each_with_index do |v,i|
                @inputLayer = [v[0],v[1],v[2],v[3]]
                @teacher = v[4]
                print '入力:[' + @inputLayer.join(',') + ']',",\t"
                
                y = checkTest(@inputLayer, @outputLayer, @n, m)
                print '教師値:' + @teacher.to_s,",\t"
                print '修正前:' + y.to_s,', '
                if y == @teacher then
                    print '***学習完了***',",\t"
                else
                    learningRate = 0.99 
                    @outputLayer = learnTest(@inputLayer, @outputLayer, @teacher, y, learningRate, @n)
                    y = checkTest(@inputLayer, @outputLayer, @n)
                    print '修正後:' + y.to_s,",\t"
                    print '学習係数:' + learningRate.to_s,",\t"
                end
                puts
            end
            day2 = Time.now
            days = (day2-day1).divmod(24*60*60)
            hours = days[1].divmod(60*60)
            mins = hours[1].divmod(60)
            secs = mins[1].divmod(60)
            print '学習時間:', secs[1],'秒'
            puts 'Ex)'
                @inputLayer = [21,22,23,24]
                @teacher = 18
                print '入力:[' + @inputLayer.join(',') + ']',",\t"

                y = checkTest(@inputLayer, @outputLayer, @n, m)
                print '教師値:' + @teacher.to_s,",\t"
                print '修正前:' + y.to_s,', '
            puts
            puts
        end
    end
    def start()
        10000.times do |m|
            puts (m+1).to_s + '回目の学習'
            day1 = Time.now
            @body.each do |v|
                @inputLayer = [v[0],v[1]]
                @teacher = v[2]
                print '入力:[' + @inputLayer.join(',') + ']',",\t"
                
                y = check(@inputLayer, @outputLayer, @n)
                print '教師値:' + @teacher.to_s,",\t"
                print '修正前:' + y.to_s,', '
                if y == @teacher then
                    print '***学習完了***',",\t"
                else
                    learningRate = 0.8
                    @outputLayer = learn(@inputLayer, @outputLayer, @teacher, y, learningRate, @n)
                    y = check(@inputLayer, @outputLayer, @n)
                    print '修正後:' + y.to_s,",\t"
                    print '学習係数:' + learningRate.to_s,",\t"
                end
                puts
            end
            day2 = Time.now
            days = (day2-day1).divmod(24*60*60)
            hours = days[1].divmod(60*60)
            mins = hours[1].divmod(60)
            secs = mins[1].divmod(60)
            print '学習時間:', secs[1],'秒'
            puts
            puts
        end
    end
end

main = Main.new()
main.test()
#main.start()
