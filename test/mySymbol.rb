
class MySymbol
    attr_accessor :symbolLength, :symbolCapacity
    def initialize()
        @symbolPath = 'Symbol.txt'
        # コード長
        @symbolLength = 50
        # 表現可能な自然数 0 ... N
        @symbolCapacity = 100
    end
    def decode(symbol)
        symbolRelation = Hash.new
        open(@symbolPath) do |file|
            file.each do |line|
                tmp = line.split("=>")
                num = tmp[0]
                symbolStr = tmp[1].to_s
                symbolList = symbolStr.split(' ').map{|s|s.to_i}
                p symbol
                p symbolList
                if symbol == symbolList then
                    # 文字をコード化した場合を考えて
                    # あえて文字列で返す
                    return num
                end
            end
        end
    end
    def encode(aNum)
        """ 数字をシンボル（±1）の羅列に変換 """
        """ 3 => [1,1,-1,...]に変換する。戻り値は配列 """
        """ 数字以外の文字などにも対応できるようにハッシュで """
        symbolRelation = Hash.new
        open(@symbolPath) do |file|
            file.each do |line|
                tmp = line.split("=>")
                num = tmp[0]
                symbol = tmp[1].to_s
                symbolList = symbol.split(' ').map{|s|s.to_i}
                symbolRelation[num] = symbolList
            end
        end
        if symbolRelation.key?(aNum.to_s) then
            return symbolRelation[aNum.to_s]
        else
            return false
        end
    end
    def make()
        symbols = {}
        @symbolCapacity.times do |t|
            begin
                if t == 0 then
                    tmp = makeSymbol(@symbolLength)
                else
                    tmp = makeSymbol(@symbolLength,symbols[(t-1).to_s])
                end
            end while existDuplex(symbols, tmp)
            symbols[t.to_s] = tmp
        end

        # save as a file
        body = ''
        symbols.length.times do |index|
            body += index.to_s + "=>" +symbols[index.to_s].join(' ') + "\r\n"
        end

        File.open(@symbolPath,'w') do |file|
            file.write body 
        end

        p ["@symbolLength", @symbolLength]
        p ["@symbolCapacity", @symbolCapacity]
        puts
        puts "Saved:" + @symbolPath 
        return body
    end
    def makeSymbol(aLength, aBefore=[])
        tmp = []
        plusCount = 0
        minusCount = 0
        if aBefore.length == 0 then
            flug = aLength / 2
            aLength.times do |t|
                if (minusCount >= flug) then
                    t = 1
                elsif (plusCount >= flug) then
                    t = 0
                else
                    t = rand(2)
                end
                if t == 0 then
                    t = -1
                    minusCount += 1
                elsif t == 1 then
                    plusCount += 1
                end
                tmp << t

            end
        else
            tmp = [] + aBefore
            t = tmp.pop
            if t == -1 then
                tmp.unshift(1)
            else
                tmp.unshift(-1)
            end
        end
        return tmp
    end

    def existDuplex(aTarget, aPattern)
        pattern = aPattern.join("")
        aTarget.each do |k,v|
            if pattern == v.join("") then
                sleep 1
                return true
            end
        end
        return false
    end
end

