

class Rbfn
    attr_reader :phi, :centerX
    def initialize(input)
        @input = input
        @mu = @input[@input.length-1]
        @sigma = 1
        @phi = []
        @phiBias = []
        # 中心パラメータ
        @centerX = 10
        @outputMiddle = []
        @outputOut = []
        # 出力層　素子数
        @numberOut = 1

        # 中間層　初期化
        makeOutputMiddle()
        # 出力層　初期化
        @numberOut.times do |t|
            @outputOut << 0
        end
        # 重み　初期化
        @weightMiddleToOut = []
        @outputOut.each_with_index do |outV, outI|
            weight = []
            @outputMiddle.each_with_index do |middleV, middleI|
                weight << 1
            end
            @weightMiddleToOut << weight
            # バイアス　初期化
            @phiBias << 0
        end
    end

    def makeOutputMiddle
        # mapke output middle
        @input.each do |x|
            norm = (x-@centerX).abs
            @phi << Math.exp(-1*((norm**2)/(2*(@sigma**2))))
        end
        @outputMiddle = @phi
    end

    def read()
        y = 0
        yArray = []
        @outputOut.each_with_index do |outV, outI|
            tmp = 0
            @outputMiddle.each_with_index do |middleV, middleI|
                tmp += @weightMiddleToOut[outI][middleI] * middleV + @phiBias[outI]
            end
            yArray << tmp
        end
        yArray.each do |v|
            y += v
        end
        return y
    end
end

f = open("rbfnGouse.csv","w")
a = 20
str = " " +","
a.times do |t|
   str += t.to_s + ","
end
str += "\n"
a.times do |t|
    str += t.to_s + ","
    a.times do |t2|
        r = Rbfn.new([t,t2])
        str += r.read().to_s + ","
    end
    str += "\n"
end
f.write(str)
f.close()
