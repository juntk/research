#encoding: utf-8
require "point.rb"

class BasicQLearning
    attr_accessor :alpha, :gamma
    def initialize
        @alpha = 0.1
        @gamma = 0.1
    end
    def getNewQValue(aOldQValue, aReward, aNextQMax)
        newQValue = aOldQValue + @alpha * (aReward + @gamma * aNextQMax - aOldQValue)
	p ['newQValue',newQValue]
        return newQValue.to_i
    end
    def getNewQValue4Reward(aOldQValue, aReward)
        newQValue = aOldQValue + @alpha * (aReward)
	p ['RewardnewQValue',newQValue, aReward]
        return newQValue.to_i
    end
end

