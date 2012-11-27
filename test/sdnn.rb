require 'mySymbol.rb'

class Sdnn
    attr_accessor :weightMiddle2End
    def initialize()
        """
        SDNN
        """
        # 扱う変数(引数)の数
        @numberOfArgument = 4

        # 素子の出力値
        @outputFirst = []
        @outputMiddle = []
        @outputEnd = []
        # 素子数
        @numberOfElementAtMiddle = nil
        # 素子数 出力値として表現できる自然数の範囲
        @numberOfElementAtEnd = 60

        # 重み
        @weightMiddle2End = []
        """ 重みにこう配をつける """
        @weightBegin = 0.00001
        @weightAdd = 0


        # しきい値
        @thresholdEnd = []
        """しきい値にこう配をつける"""
        # しきい値の開始値
        @thresholdBegin = -50
        # しきい値の増加値
        @thresholdAdd = 1

        """ 選択的不感化 """
        # 巡回置換に使う置換行列
        @permutatioin = []
        
        """
        MySymbol
        """
        @mySymbol = MySymbol.new

        """
        環境設定
        """
        @symbolPath = "Symbol.txt"

        """
        SDNN 初期設定
        """
        initializeSdnn()
    end
    def initializeSdnn()
        """
        中間層
        """
        # 素子数を設定(出力)
        @numberOfElementAtMiddle = @mySymbol.symbolLength * @numberOfArgument
        @numberOfElementAtMiddle.times do |t|
            @outputMiddle << 0
        end

        """
        出力層
        """
        # 素子数を設定(出力)
        @numberOfElementAtEnd.times do |t|
            @outputEnd << 0
        end
        # 素子のしきい値を設定
        threshold = @thresholdBegin
        @numberOfElementAtEnd.times do |t|
            @thresholdEnd << threshold
            threshold = rand(10) * @thresholdAdd
        end
        # 出力層の素子への入力×重みの合計値
        @inputEndAmounts = Array.new(@outputEnd.length)

        """
        中間層 => 出力層
        """
        # 重みを設定
        @weightMiddle2End = []
        @outputEnd.each_with_index do |endValue, endIndex|
            tmpWeightRelation = []
            tmpWeight = @weightBegin
            @outputMiddle.each_with_index do |middleValue, middleIndex|
                tmpWeightRelation << tmpWeight
                tmpWeight += @weightAdd
            end
            @weightMiddle2End << tmpWeightRelation
        end

        """
        選択的不感化
        """
        # 置換行列を作る
        @permutation = []
        @mySymbol.symbolLength.times do |t|
            @permutation << t
        end
        @permutation = @permutation.shuffle
    end
    def read(input)
        """
        SDNN 読み込み
        """
        elementGroups = []
        input.each do |v|
            elementGroups << @mySymbol.encode(v)
        end
        if elementGroups.length != @numberOfArgument then
            puts "Error: 入力変数の数が不正です。"
            print @numberOfArgument,"個必要なんだけど"
            print elementGroups.length,"個もらってる。"
            puts
            return
        end
        if elementGroups.length % 2 != 0 then
            puts "Error: 入力変数の数が不正です。"
            puts "入力変数は偶数個で渡してください。"
            return
        end

        """
        入力層 => 中間層
        """
        # 選択的不感化
        @outputMiddle = []
        elementGroups.each_with_index do |elementGroup, elementGroupIndex|
            if elementGroupIndex % 2 == 0 then
                @outputMiddle += nonSelectiveInfluence(
                    elementGroup,
                    elementGroups[elementGroupIndex+1]
                )
            else
                @outputMiddle += nonSelectiveInfluence(
                    elementGroup,
                    elementGroups[elementGroupIndex-1]
                )
            end
        end
        if @outputMiddle.length != @numberOfElementAtMiddle then
            puts "Error: 中間層の素子数が一致しません。"
            print "中間層の素子数: ", @outputMiddle.length
            puts
            print "正しい素子数: ", @numberOfElementAtMiddle
            puts
            return
        end

        """
        中間層 => 出力層
        """
        # 出力層の素子の出力
        outputValue = 0
        @outputEnd.each_with_index do |endValue, endIndex|
            weights = @weightMiddle2End[endIndex]
            amount = 0.0
            @outputMiddle.each_with_index do |middleValue, middleIndex|
                a = middleValue.prec_f * weights[middleIndex]
                amount += a
            end
            @inputEndAmounts[endIndex] = amount
            if @inputEndAmounts[endIndex] > @thresholdEnd[endIndex] then
                @outputEnd[endIndex] = 1
            else
                @outputEnd[endIndex] = 0
            end
            outputValue += @outputEnd[endIndex]
        end
        # 出力層の素子群の合計
        print "Input: "
        p input
        puts "Output: " + outputValue.to_s
        return outputValue
    end
    def sortByPermutation(elementGroup)
        """
        素子の並べ替え
        """
        if elementGroup.length != @permutation.length then
            puts "Error: 引数の素子数と置換行列の要素数が一致しません。"
            print "引数の素子数: ", elementGroup.length
            puts
            print "置換行列の要素数: ", @permutation.length
            puts
            return
        end
        sortedElementGroup = Array.new(elementGroup.length)
        @permutation.each_with_index do |value, index|
            sortedElementGroup[index] = elementGroup[value]
        end
        return sortedElementGroup
    end
    def nonSelectiveInfluence(elementGroup1, elementGroup2)
        """
        選択的不感化

        elementGroup1: 修飾される方
        elementGroup2: 修飾データとして使う方
        """
        # 修飾データ
        modificationData = sortByPermutation(elementGroup2)
        modificationData.each_with_index do |value, index|
            if value == 1 then
                elementGroup1[index] = 0
            end
        end
        return elementGroup1
    end
    def learning(input, teacher)
        answer = read(input)
        """
        罰を与える
        ここ検証、動作おかしかったら削除
        """
        p teacher
        if teacher < 0 then
            puts "BAD"
            badCount = 0
            @outputEnd.each_with_index do |endValue, endIndex|
                if endValue == 1 then
                    fixCount = 0
                    @outputMiddle.each_with_index do |value, index|
                        if value == -1 or value == 1 then
                            fixCount += 1
                        end
                    end
                    fixRate = -1.0*teacher / fixCount
                    p fixRate
                    @outputMiddle.each_with_index do |value, index|
                        if value == -1 then
                            @weightMiddle2End[endIndex][index] += fixRate
                        elsif value == 1 then
                            @weightMiddle2End[endIndex][index] -= fixRate
                        end
                    end
                    badCount += 1
                end
                if badCount >= -1*teacher then
                    return
                end
            end
            return
        end
        """
        学習
        """
        # 素子の重みを修正する回数＝教師値と回答の誤差
        fixCount,fixCountVector = getErrorValue(teacher, answer)
        # 発火しやすさ
        fireDegrees = Array.new(@thresholdEnd.length)
        fireDegreeVectors = Array.new(@thresholdEnd.length)
        @thresholdEnd.each_with_index do |threshold, index|
            amount = @inputEndAmounts[index]
            tmpDegree,tmpDegreeVector = getErrorValue(threshold,amount)
            if tmpDegreeVector == fixCountVector then
                fireDegrees[index] = tmpDegree
                fireDegreeVectors[index] = tmpDegreeVector
            end
        end
        """
        重みの修正
        """
        #p ['fixCount', fixCount]
        fixCount.times do |t|
            # 修正しやすい素子を選択
            # 修正コスト
            min = nil
            minIndex = nil
            fireDegrees.each_with_index do |value, index|
                if value != nil and (min == nil or value < min) then
                    min = value
                    minIndex = index
                end
            end
            # 修正しやすい素子の入力合計値としきい値の誤差
            fireDegree = fireDegrees[minIndex]
            fireDegrees[minIndex] = nil

            fireDegreeVector = fireDegreeVectors[minIndex]
            # 不感化された素子に繋がる重みは修正しない
            fixWeightCount = 0
            @outputMiddle.each do |value|
                if value != 0 then fixWeightCount += 1 end
            end
            # ある素子に繋がる重みの修正レート＝
            # 　＝誤差／修正できる重みの数
            # 誤差＝修正レート×修正できる重みの数
            fixRate = (fireDegree+0.1) / fixWeightCount
            @weightMiddle2End[minIndex].each_with_index do |weight, index|
                if @outputMiddle[index] == 1 then
                    if fireDegreeVector == 1 then
                        @weightMiddle2End[minIndex][index] += fixRate 
                    elsif fireDegreeVector == -1 then
                        @weightMiddle2End[minIndex][index] -= fixRate 
                    end
                elsif @outputMiddle[index] == -1 then
                    if fireDegreeVector == 1 then
                        @weightMiddle2End[minIndex][index] -= fixRate 
                    elsif fireDegreeVector == -1 then
                        @weightMiddle2End[minIndex][index] += fixRate 
                    end
                end
            end
        end
    end
    def getErrorValue(a, b)
        """
        aとbの誤差を返す
        """
        result = 0.0
        vector = 0
        if a <= 0 and b >= 0 then
            result = -1 * a + b 
            vector = -1
            # puts 'a'
        elsif a >= 0 and b <= 0 then
            result = a + -1 * b
            vector = 1
            # puts 'b'
        elsif a <= 0 and b <= 0 then
            if a >= b then
                result = b - a
                vector = 1
            else
                result = a - b
                vector = -1
            end
            # puts 'c'
        elsif a >= 0 and b >= 0 then
            if a >= b then
                result = a - b
                vector = 1
            else
                result = b - a
                vector = -1
            end
            # puts 'd'
        else
            if a >= b then
                result = a - b
                vector = 1
            else
                result = b - a
                vector = -1
            end
            # puts 'e'
        end
        #p [a,b,result,vector]
        return result, vector
    end
end

s = Sdnn.new()
s.read([17,18,20,36])
