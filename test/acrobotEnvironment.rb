
class AcrobotEnvironment
    attr_accessor :gravity, :velocity, :damping
    def initialize
        """
        Acrobot Environment
        """
        # 重力
        @gravity = 1
        # 減衰
        @damping = 1.0
    end
end
