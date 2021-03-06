
class Network
    def initialize
        @currentPath = './sdnn'
        @symbolPath = @currentPath + '/Symbol.txt'

    end
    def initialize
        @currentPath = './sdnn'
        @symbolPath = @currentPath + '/Symbol.txt'
    end
    def encodeNumToSymbol(aNum)
        """ 数字をシンボル（±1）の羅列に変換 """
        """ 3 => [1,1,-1,...]に変換する。戻り値は配列 """
        """ 数字以外の文字などにも対応できるようにハッシュで """
        symbolRelation = Hash.new
        open(@symbolPath) do |file|
            file.each do |line|
                tmp = line.split("=>")
                num = tmp[0]
                symbol = tmp[1].delete("\r\n")
                symbolList = symbol.split(' ').map {|s|s.to_i}
                symbolRelation[num] = symbolList
            end
        end
        if symbolRelation.key?(aNum.to_s) then
            return symbolRelation[aNum.to_s]
        else
            return false
        end
    end

    def modify(aSymbol, aModifier)
        """ 修飾パターンの並び替え """
        aModifier = permutation(aModifier)

        """ 修飾パターンが-1のとき0に不感化 """
        result = []
        aSymbol.each_with_index do |word, index|
            if aModifier[index] == -1 then
                result << 0
            else
                result << word
            end
        end
        return result
    end
    def permutation(aModifier)
        """ 巡回置換 """
        cyclicPermutation = [1,8,12,5,13,2,10,0,4,11,15,6,3,14,7,9]
        (cyclicPermutation.length-1).times do |i|
            tmp = aModifier[cyclicPermutation[i]]
            aModifier[cyclicPermutation[i]] = aModifier[cyclicPermutation[i+1]]
            aModifier[cyclicPermutation[i+1]] = tmp
        end
        return aModifier
    end
    def makeNetwork(aIn, aMid, aOut)
        @in = Array.new(2)
        @mid = Array.
    end
end
