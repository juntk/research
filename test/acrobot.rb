# encoding: utf-8

require 'rubygems'
require 'pongo'
require 'pongo/renderer/tk_renderer'
require 'pongo/logger/standard_logger'
require 'acrobotEnvironment.rb'
require 'acrobotArm.rb'

include Pongo

class Acrobot < Pongo::Group
    attr_accessor :env, :arm1, :arm2, :group, :joint1, :joint2, :joint3, :link1, :link2, :armPositionByTop
    def initialize(windowSize = [640,480])
        super()
        """
        Acrobot
        """
        @windowWidth = windowSize[0]
        @windowHeight = windowSize[1]

        # 環境
        @env = AcrobotEnvironment.new

        # アーム
        @arm1 = AcrobotArm.new
        @arm2 = AcrobotArm.new

        """
        Pongo
        """
        self.collide_internal = true

        initializeBase()
        initializeArms()

        """
        オブジェクト追加
        """
        add_particle(@joint1)
        add_particle(@joint2)
        add_particle(@joint3)
        add_particle(@base)
        add_constraint(@link1)
        add_constraint(@link2)
        
    end
    def initializeArms
        """
        アーム
        """
        @armPositionByTop = 120
        @joint1 = CircleParticle.new(
            @windowWidth/2,
            @armPositionByTop,
            @arm1.mass,
            :fixed=>true,
            :line_color=>@arm1.line_color,
            :fill_color=>@arm1.fill_color,
            :fill_alpha=>0,
            :line_alpha=>0
        )
        @joint2 = CircleParticle.new(
            @windowWidth/2,
            @armPositionByTop + @arm1.length,
            @arm1.mass,
            :mass=>@arm1.mass,
            :fixed=>false,
            :line_color=>@arm1.line_color,
            :fill_color=>@arm1.fill_color,
            :fill_alpha=>0,
            :line_alpha=>0
        )
        @joint3 = CircleParticle.new(
            @windowWidth/2,
            @armPositionByTop + @arm1.length + @arm2.length,
            @arm1.mass,
            :elasticity=>1,
            :mass=>@arm2.mass,
            :line_color=>@arm2.line_color,
            :fill_color=>@arm2.fill_color,
            :fill_alpha=>0,
            :line_height=>1,
            :line_alpha=>0
        )

        @link1 = SpringConstraint.new(
            @joint1,
            @joint2,
            :stiffness=>@arm1.stiffness,
            :collidable=>true,
            :rect_height=>@arm1.height,
            :line_color=>@arm1.line_color,
            :fill_alpha=>0,
            :line_alpha=>0
        )
        @link2 = SpringConstraint.new(
            @joint2,
            @joint3,
            :stiffness=>@arm2.stiffness,
            :collidable=>true,
            :rect_height=>@arm2.height,
            :line_color=>@arm2.line_color,
            :fill_alpha=>0,
            :line_alpha=>0
        )

        # 初期速度
        @joint1.velocity = Pongo::Vector.new(0,0)
        @joint2.velocity = Pongo::Vector.new(0,0)
        @joint3.velocity = Pongo::Vector.new(0,0)

        # スタイル設定

    end
    def initializeBase
        """
        地面
        """
        @base = RectangleParticle.new(
            0,
            @windowHeight-60,
            @windowWidth*2,
            30,
            :fixed=>true
        )
    end
    def resetArms
        @joint1.curr = Pongo::Vector.new(
            @windowWidth/2,
            @armPositionByTop + @arm1.length
        )
        @joint2.curr = Pongo::Vector.new(
            @windowWidth/2,
            @armPositionByTop + @arm1.length
        )
        @joint3.curr = Pongo::Vector.new(
            @windowWidth/2,
            @armPositionByTop + @arm1.length + @arm2.length
        )
        # 初期速度
        @joint1.velocity = Pongo::Vector.new(0,0)
        @joint2.velocity = Pongo::Vector.new(0,0)
        @joint3.velocity = Pongo::Vector.new(0,0)
    end
    def getGlobalRadiusAtArms()
        """
        アームの角度
        """
        radius = []
        vector = getVector(@joint1.curr, @joint2.curr)
        quadrant = getQuadrant(@joint1.curr, @joint2.curr)
        radius << getTan(vector, quadrant)
        vector = getVector(@joint2.curr, @joint3.curr)
        quadrant = getQuadrant(@joint2.curr, @joint3.curr)
        radius << getTan(vector, quadrant)
        return radius
    end
    def getRadiusAtArms()
        """
        アームの角度
        """
        resultRadius = []
        radius = getGlobalRadiusAtArms()
        radius.each do |r|
            if r < 180 then
                resultRadius << 180 - r
            elsif r > 180 then
                resultRadius << r - 180
            else
                resultRadius << 0
            end
        end
        if resultRadius[0] < resultRadius[1] then
            resultRadius[1] = resultRadius[1] - resultRadius[0]
        else
            resultRadius[1] = resultRadius[0] - resultRadius[1]
        end
        return resultRadius
    end
    def getSpeedAtArms()
        return [getSpeed(@joint2.velocity), getSpeed(@joint3.velocity)]
    end
    def getSpeed(velocity)
        x = velocity.x
        y = velocity.y
        return Math.sqrt(x*x + y*y)
    end
    def getVectorSpeedAtArms()
        s = []
        s << getVectorSpeed(@joint2.prev, @joint1.prev, @joint2.curr, @joint1.curr)
        s << getVectorSpeed(@joint3.prev, @joint2.prev, @joint3.curr, @joint2.curr)
        return s
    end
    def getVectorSpeed(beforePoint, beforeCenterPoint, afterPoint, afterCenterPoint)
        s = (beforePoint.x - beforeCenterPoint.x) * (afterPoint.y - afterCenterPoint.y) - (beforePoint.y - beforeCenterPoint.y) * (afterPoint.x - afterCenterPoint.x)
        if s < 0 then
            s = -1
        elsif s > 0 then
            s = 1
        else
            s = 0
        end
        return s
    end
    def getAngularVelocityAtArms()
        speeds = getSpeedAtArms()
        vectorSpeeds = getVectorSpeedAtArms()
        rads = getRadiusAtArms()
        aV = []
        aV << getAngularVelocity(@arm1.length, speeds[0]*vectorSpeeds[0])
        aV << getAngularVelocity(@arm2.length, speeds[1]*vectorSpeeds[1])
        return aV
    end
    def getAngularVelocity(l, v)
        angularVelocity = v / l
        return angularVelocity
    end
    def getVector(aPoint1, aPoint2)
        """
        ベクトル
        """
        c = Pongo::Vector.new
        if aPoint2.x > aPoint1.x then
            c.x = aPoint2.x - aPoint1.x
        else
            c.x = aPoint1.x - aPoint2.x
        end
        if aPoint2.y > aPoint1.y then
            c.y = aPoint2.y - aPoint1.y
        else
            c.y = aPoint1.y - aPoint2.y
        end
        return c
    end
    def getQuadrant(aPoint1, aPoint2)
        """
        第N象限
        """
        if aPoint1.x > aPoint2.x then
            #left
            if aPoint1.y < aPoint2.y then
                #left-down
                return 3
            else
                #left-up
                return 2
            end
        else
            if aPoint1.y < aPoint2.y then
                #right-down
                return 4
            else
                #left-up
                return 1
            end
        end
        return nil
    end
    def getTan(aVector, aQuadrant)
        """
        角度
        """
        tan = aVector.y/aVector.x
        tan = Math.atan(tan)
        tan = tan * 180.0 / Math::PI
        if aQuadrant == 1 then
            tan = -1*(-90+tan) 
            tan =  tan 
        elsif aQuadrant == 2 then
            tan += 270
        elsif aQuadrant == 3 then
            tan = -1*(-90+tan)
            tan = tan 
            tan += 180
        elsif aQuadrant == 4 then
            tan += 90
        end
        return tan.to_i
    end
end
