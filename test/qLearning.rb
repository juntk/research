#encoding: utf-8
require "point.rb"

class BasicQLearning
    attr_accessor :alpha, :gamma
    def initialize
        @alpha = 0.5
        @gamma = 0.9
    end
    def getNewQValue(aOldQValue, aReward, aNextQMax)
        newQValue = (1-@alpha)*aOldQValue + @alpha * (aReward + @gamma * aNextQMax)
	p ['newQValue',newQValue]
        return newQValue.to_i
    end
    def getNewQValue4Reward(aOldQValue, aReward)
        newQValue = aOldQValue + @alpha * (aReward)
	p ['RewardnewQValue',newQValue, aReward]
        return newQValue.to_i
    end
end

