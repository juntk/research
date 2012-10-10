#encoding: utf-8
require "./ReinforcementLearning/Point.rb"

class BasicQLearning
    attr_accessor :alpha, :gamma
    def initialize
        @alpha = 0.9
        @gamma = 0.9
    end
    def getNewQValue(aOldQValue, aReward, aNextQMax)
        newQValue = aOldQValue + @alpha * (aReward + @gamma * aNextQMax - aOldQValue)
        return newQValue
    end
end

