require "./nn/basicNeuronModel/basicNeuronModelV2.rb"


class Network
    def initialize(aOutputElementNum)
        @currentPath = './sdnn'
        @symbolPath = @currentPath + '/Symbol.txt'
        @outputElementNum = aOutputElementNum
        @thresholdGradient = 1.0*@outputElementNum
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
        #500
        #cyclicPermutation = [198, 297, 418, 195, 76, 495, 115, 192, 90, 462, 491, 434, 205, 375, 84, 253, 365, 485, 190, 129, 125, 332, 339, 395, 470, 119, 331, 481, 371, 303, 172, 166, 279, 165, 26, 473, 211, 4, 423, 227, 466, 52, 78, 120, 179, 67, 123, 170, 256, 335, 258, 369, 10, 346, 265, 313, 285, 467, 358, 107, 420, 370, 308, 436, 70, 468, 19, 126, 108, 348, 387, 391, 53, 66, 401, 482, 424, 357, 49, 488, 277, 431, 372, 403, 469, 124, 0, 44, 3, 136, 316, 273, 73, 427, 267, 202, 492, 422, 409, 406, 24, 217, 244, 411, 210, 338, 298, 329, 206, 487, 171, 148, 200, 110, 193, 402, 384, 233, 347, 34, 28, 177, 168, 325, 430, 287, 69, 326, 46, 112, 373, 312, 281, 147, 323, 159, 444, 306, 151, 443, 140, 183, 56, 41, 282, 337, 57, 290, 82, 16, 22, 283, 377, 255, 241, 239, 23, 197, 288, 71, 494, 240, 243, 433, 58, 451, 102, 236, 101, 351, 158, 86, 408, 475, 81, 441, 397, 186, 415, 2, 439, 106, 92, 289, 221, 113, 117, 386, 486, 342, 13, 398, 89, 180, 169, 152, 39, 215, 38, 155, 257, 154, 352, 250, 20, 74, 446, 336, 45, 30, 176, 449, 80, 128, 363, 392, 9, 219, 135, 230, 114, 25, 383, 412, 307, 182, 116, 248, 237, 105, 8, 497, 407, 137, 191, 271, 18, 178, 374, 447, 478, 189, 327, 50, 284, 417, 389, 359, 188, 380, 21, 37, 295, 476, 55, 414, 68, 213, 399, 32, 445, 65, 149, 145, 162, 311, 266, 276, 322, 318, 173, 72, 400, 428, 455, 259, 304, 483, 249, 234, 437, 314, 231, 12, 254, 499, 292, 300, 345, 465, 43, 320, 122, 35, 435, 199, 360, 132, 121, 27, 310, 269, 390, 79, 361, 42, 141, 379, 223, 490, 153, 232, 6, 262, 75, 366, 463, 350, 163, 143, 150, 203, 40, 343, 294, 474, 222, 454, 224, 14, 472, 404, 60, 356, 456, 394, 355, 94, 263, 324, 293, 405, 185, 77, 291, 381, 103, 85, 413, 29, 161, 93, 261, 220, 458, 460, 341, 393, 498, 368, 480, 91, 464, 204, 118, 268, 410, 131, 96, 225, 315, 252, 142, 274, 448, 1, 275, 344, 349, 64, 396, 479, 33, 452, 330, 286, 419, 208, 477, 353, 17, 278, 212, 97, 251, 104, 442, 134, 416, 438, 429, 453, 247, 367, 207, 87, 319, 98, 187, 362, 457, 364, 100, 260, 264, 15, 229, 61, 216, 175, 127, 48, 174, 133, 235, 280, 157, 228, 218, 317, 31, 11, 160, 201, 5, 421, 378, 47, 144, 242, 333, 109, 302, 156, 270, 484, 95, 226, 425, 382, 299, 450, 301, 62, 354, 440, 54, 296, 305, 36, 7, 459, 489, 461, 88, 111, 194, 209, 181, 196, 184, 432, 139, 493, 471, 426, 214, 385, 130, 246, 164, 83, 63, 309, 334, 321, 138, 99, 376, 340, 59, 238, 272, 146, 51, 388, 245, 328, 167, 496]
        # 200
        cyclicPermutation = [55, 87, 115, 103, 109, 39, 131, 127, 194, 120, 93, 26, 82, 100, 30, 142, 3, 171, 54, 168, 113, 119, 163, 36, 47, 177, 122, 66, 94, 12, 175, 199, 91, 49, 83, 69, 64, 146, 99, 31, 1, 58, 141, 51, 9, 76, 150, 35, 110, 22, 190, 4, 41, 24, 149, 75, 88, 62, 126, 95, 89, 155, 38, 50, 96, 184, 70, 32, 104, 162, 46, 164, 188, 139, 121, 195, 154, 23, 193, 56, 145, 65, 170, 0, 183, 86, 196, 129, 33, 159, 6, 53, 18, 8, 187, 160, 185, 116, 19, 156, 148, 174, 34, 11, 123, 81, 165, 77, 153, 52, 57, 181, 68, 2, 13, 198, 133, 25, 117, 147, 5, 48, 166, 85, 17, 135, 29, 125, 137, 40, 45, 97, 90, 43, 59, 124, 102, 98, 44, 16, 73, 67, 61, 172, 173, 158, 118, 28, 71, 144, 84, 186, 72, 112, 114, 14, 138, 27, 79, 182, 191, 80, 78, 106, 134, 105, 152, 161, 111, 21, 15, 192, 179, 60, 107, 189, 151, 167, 63, 128, 37, 169, 42, 130, 140, 180, 7, 136, 178, 157, 101, 197, 132, 108, 176, 10, 92, 74, 20, 143]
        # 100
        #cyclicPermutation = [90, 38, 66, 6, 81, 12, 40, 3, 55, 39, 33, 34, 37, 5, 42, 4, 86, 82, 27, 85, 43, 11, 65, 94, 49, 29, 21, 25, 78, 61, 89, 47, 32, 18, 35, 50, 30, 60, 91, 52, 22, 95, 57, 69, 87, 98, 53, 31, 17, 83, 56, 19, 74, 23, 54, 92, 48, 58, 51, 24, 97, 59, 8, 63, 76, 41, 99, 9, 93, 88, 13, 44, 26, 68, 10, 15, 45, 0, 71, 67, 20, 77, 28, 80, 64, 16, 72, 62, 79, 96, 73, 14, 75, 7, 84, 70, 36, 2, 1, 46]
        #        16
        #cyclicPermutation = [3, 9, 11, 10, 2, 7, 15, 13, 0, 6, 5, 8, 14, 12, 1, 4]
        #   32
        #cyclicPermutation = [8, 30, 25, 13, 7, 2, 22, 17, 9, 19, 21, 20, 1, 24, 23, 4, 11, 14, 29, 16, 6, 12, 27, 3, 28, 10, 5, 31, 15, 18, 0, 26]
        # 48
        #cyclicPermutation = [46, 8, 35, 5, 28, 7, 37, 14, 44, 12, 27, 22, 47, 39, 13, 15, 43, 29, 32, 42, 40, 30, 3, 38, 23, 36, 24, 16, 34, 4, 33, 20, 6, 1, 45, 10, 41, 17, 19, 2, 26, 0, 9, 31, 11, 18, 21, 25]
        # 64
        #cyclicPermutation = [2, 54, 61, 29, 9, 16, 44, 48, 8, 10, 5, 41, 39, 34, 20, 57, 27, 14, 1, 49, 23, 58, 25, 28, 35, 42, 17, 0, 63, 11, 13, 4, 3, 52, 60, 18, 19, 45, 56, 50, 36, 53, 47, 55, 12, 33, 26, 7, 30, 59, 37, 21, 43, 38, 22, 15, 31, 46, 24, 40, 51, 62, 32, 6]
        (cyclicPermutation.length-1).times do |i|
            tmp = aModifier[cyclicPermutation[i]]
            aModifier[cyclicPermutation[i]] = aModifier[cyclicPermutation[i+1]]
            aModifier[cyclicPermutation[i+1]] = tmp
        end
        return aModifier
    end
    def makeMiddleLayer(aInputLayer)
        """ 中間層の出力を作る。あくまでも出力値のみ。"""
        """ 中間層のニューロンはmakeOutputLayerで作っています。"""
        """ 中間層の素子群の数は、入力変数の数×入力変数の数-1 """

        """ 入力変数をシンボルに変換 """
        aInputLayer = aInputLayer.map {|num|encodeNumToSymbol(num)}

        """ 出力値を設定したニューロンを持つリスト """
        middleLayer = []
        """ 出力値のみ持つリスト """
        middleLayerOutputValue = []
        aInputLayer.each_with_index do |value,index|
            aInputLayer.each_with_index do |value2, index2|
                if index != index2 then
                    tvalue = modify(value, value2)
                    tvalue.each_with_index do |atv, atv_index|
                        n = BasicNeuronModel.new
                        n.output = atv
                        middleLayer << n
                    end
                    middleLayerOutputValue << tvalue
                end
            end
        end
        return middleLayer
    end
    def makeOutputLayer(aMiddleLayer)
        """ 出力層を作る。 """

        """ ニューロンクラスのリスト """
        outputLayer = []
        @outputElementNum.times do |t|
            outputLayer << makeOutputNeuron(aMiddleLayer)
        end
        return outputLayer
    end
    def makeOutputNeuron(aMiddleLayer)
        """ 出力層の単体のニューロンのみ作る """
        output = BasicNeuronModel.new
        output.threshold = @thresholdGradient
        aMiddleLayer.each_with_index do |value, index|
            """ 出力層と中間層の繋がりと重み関係を把握するため """
            aMiddleLayer[index].afterNeuron << output
            output.beforeNeuron << aMiddleLayer[index]
            output.weight << 1
        end
        @thresholdGradient += 0.5
        return output
    end
    def checkFireAtOutputLayer(aOutputLayer, aMiddleLayer)
        result = []
        aOutputLayer.each_with_index do |value, index|
            result << checkFireAtOutputNeuron(value, aMiddleLayer)
        end
        return result;
    end
    def checkFireAtOutputNeuron(aNeuronAtOutput, aMiddleLayer)
        """ 単体のニューロンを渡してください。層ではないです。 """
        """ 中間層->出力層に入力を与え、実際に発火するかどうか検証 """

        """ 中間層の全ての素子を取得 """
        allMiddleLayer = []
        aMiddleLayer.each_with_index do |value, index|
            allMiddleLayer << value.output
        end
        """ 中間層の出力が出力層の入力になる """
        """ 入力値として与える """
        return aNeuronAtOutput.Neuron(allMiddleLayer)
    end
    def getAmountValueOfOutput(aOutputLayer)
        result = 0
        aOutputLayer.each do |v|
            #print v.output
            if v.output == 1 then
                result += v.output
            end
        end
        #puts
        return result
    end
    def rankEasiestElementForFixWeight(aOutLayer, aMidLayer)
        rank = []
        aOutLayer.each_with_index do |outElement, outIndex|
            tmpAmount = 0.0
            aMidLayer.each_with_index do |midElement, midIndex|
                tmpAmount += 1.0 * midElement.output * outElement.weight[midIndex]
            end
            outElement.threshold
            if outElement.threshold < 0 then
                if outElement.threshold > tmpAmount then
                    errorValue = -1.0 * tmpAmount + outElement.threshold
                else
                    errorValue = -1.0 * outElement.threshold + tmpAmount
                end
            elsif outElement.threshold > 0 then
                if outElement.threshold > tmpAmount then
                    errorValue = 1.0 * outElement.threshold - tmpAmount
                else
                    errorValue = 1.0 * tmpAmount - outElement.threshold
                end
            elsif outElement.threshold == 0 then
                if tmpAmount > 0 then
                    errorValue = tmpAmount
                elsif tmpAmount < 0 then
                    errorValue = -1 * tmpAmount
                elsif tmpAmount == 0 then
                    errorValue = 0
                end
            end
            if errorValue < 0 then
                print 'error'
                puts outElement.threshold, tmpAmount
            end
            rank << errorValue.to_i
        end
        return rank
    end
    def getFixElement(aRank)
        # 修正すべき素子を返す
        # aRank = rankEasiestElementForFixWeight(,) から取得
        min = nil
        minIndex = nil
        aRank.each_with_index do |r, index|
            if min == nil then
                min = r
                minIndex = index
            else
                if min > r then
                    min = r
                    minIndex = index
                end
            end
        end
        if aRank != nil and minIndex != nil then
            aRank.delete_at(minIndex)
            return [minIndex, aRank]
        else
            return false
        end
    end

    def fixWeight(aTeacher, aOutput, aLearningRate, aLayer, aMidLayer)
        """
        puts
        print 'teacher:' + aTeacher.to_s + ' output:' + aOutput.to_s
        """
        changeWeight = []
        if aTeacher > aOutput then
            """ 教師の方が大きければ-1を1に修正する"""
            before = -1
            after = 1
            #print '+'
            if aOutput < 0 then
                """ example) ( -1*(-60) + 30 )/2 = 45""" 
                defFixCount = (-1*aOutput + aTeacher)
            else
                defFixCount = (aTeacher - aOutput)
            end
        elsif aTeacher < aOutput then
            """ 出力値の方が大きければ1を-1に修正する"""
            before = 1
            after = -1
            #print '-'
            if aOutput < 0 then
                """ example) -30 - (-60) = 30 , 30/2 =15"""
                defFixCount = (aOutput - aTeacher)
            else
                """ example) 60 - 30 = 30 , 30/2 =15"""
                defFixCount = (aOutput - aTeacher)
            end
        else
            """ 教師と出力値が同じであれば修正の必要なし"""
            return aLayer
        end
        """
        print ' fixCount:' + defFixCount.to_s
        print ','
        """
        fixCount = 0
        count = 0.0
        aLayer.each do |v|
            if v.output == before then
                count += 1.0
            end
        end

        log = []
        rank = rankEasiestElementForFixWeight(aLayer, aMidLayer)
        begin
            #index = rand(aLayer.length)
            element = getFixElement(rank)
            if element == false then
                fixCount = defFixCount + 1
                rank = rankEasiestElementForFixWeight(aLayer, aMidLayer)
                redo
                p rank
                redo
            end
            index = element[0]
            rank = element[1]
            neuron = aLayer[index]
            if log.assoc(index) == nil then
                log << index
            else
                redo
            end
            """　出力層の素子チェック """
            """ before(-1) -> after(+1):
                    before(-1)をafter(+1)に変えるため、現在before(-1)の素子を取得
            """
            if neuron.output == before then
                neuron.weight.each_with_index do |weight, windex|
                    """ 中間->出力の重みリストで繰り返し """
                    changeWeight = aLearningRate * weight
                    if aMidLayer[windex].output == before
                        aLayer[index].weight[windex] -= changeWeight
                    elsif aMidLayer[windex].output == after
                        aLayer[index].weight[windex] += changeWeight
                    end
                end
                fixCount+=1
            end


        end while fixCount < defFixCount 
        return aLayer
    end

end

