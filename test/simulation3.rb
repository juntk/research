#coding: utf-8
class Simulation
    def initialize
        @SEED = 1
        @T = 0.1
        @TL = 50.0
        @EPI = 1000
        @RAND_MAX = 32767
        
        @M1 = 1.0
        @M2 = 1.0
        @I1 = 1.0
        @I2 = 1.0
        @L1 = 1.0
        @L2 = 1.0
        @R1 = 0.5
        @R2 = 0.5
        @F = 1.0
        @G = 9.8

        @GRID = 21

        @kth1 = Array.new(4)
        @qth1 = Array.new(4)
        @kth2 = Array.new(4)
        @qth2 = Array.new(4)
        @f = 0
        @HGRID = (@GRID-1)/2
        @Degree = 0.0174532925
        @TH1limit = 180 * @Degree
        @THD1limit = 2*180*@Degree
        @TH2limit = 180 * @Degree
        @THD2limit = 4*180*@Degree

        @th1 = 0.0
        @th2 = 0.0
        @thd1 = 0.0
        @thd2 = 0.0
        @preth1 = 0.0
        @preth2 = 0.0
        @prethd1 = 0.0
        @prethd2 = 0.0
        @Goalflag = 0

        @Q = 0.0
        @nQ = 0.0

        @W_RIGHT = []
        @W_LEFT = []


    end
    def Runge_kutta()
        s11 = 0.0
        s12 = 0.0
        s21 = 0.0
        s22 = 0.0
        t1 = 0.0
        t2 = 0.0
        u1 = 0.0
        u2 = 0.0

        s11 = @M1*@R1*@R1 + @M2*@L1*@L1 + @M2*@R2*@R2 + 2*@M2*@L1*@R2*Math.cos(@th2) + @I1 + @I2
        s12 = @M2*@R2*@R2 + @M2*@L1*@R2*Math.cos(@th2) + @I2
        s21 = s12
        s22 = @M2*@R2*@R2 + @I2
        t1 = (-1)*@M2*@L1*@R2*(2*@thd1 + @thd2)*@thd2*Math.sin(@th2)
        t2 = @M2*@L1*@R2*@thd1*@thd1*Math.sin(@th2)
        u1 = (@M1*@R1 + @M2*@L1)*@G*Math.sin(@th1) + @M2*@R2*@G*Math.sin(@th1 + @th2)
        u2 = @M2*@R2*@G*Math.sin(@th1 + @th2)
        @kth1[0] = @T*@thd1
        @qth1[0] = @T*(s12*(@f - t2 - u2) + s22*(t1 + u1))/(s12*s21 - s11*s22)
        @kth2[0] = @T*@thd2
        @qth2[0] = @T*(s11*(t2 + u2 - @f) - s21*(t1 + u1))/(s12*s21 - s11*s22)
        s11 = @M1*@R1*@R1 + @M2*@L1*@L1 + @M2*@R2*@R2 + 2*@M2*@L1*@R2*Math.cos(@th2 + @kth2[0]/2.0) + @I1 + @I2
        s12 = @M2*@R2*@R2 + @M2*@L1*@R2*Math.cos(@th2 + @kth2[0]/2.0) + @I2
        s21 = s12
        s22 = @M2*@R2*@R2 + @I2
        t1 = (-1)*@M2*@L1*@R2*(2*(@thd1 + @qth1[0]/2.0) + (@thd2 + @qth2[0]/2.0))*(@thd2 + @qth2[0]/2.0)*Math.sin(@th2 + @kth2[0]/2.0)
        t2 = @M2*@L1*@R2*(@thd1 + @qth1[0]/2.0)*(@thd1 + @qth1[0]/2.0)*Math.sin(@th2 + @kth2[0]/2.0)
        u1 = (@M1*@R1 + @M2*@L1)*@G*Math.sin(@th1 + @kth1[0]/2.0) + @M2*@R2*@G*Math.sin((@th1 + @kth1[0]/2.0) + (@th2 + @kth2[0]/2.0))
        u2 = @M2*@R2*@G*Math.sin((@th1 + @kth1[0]/2.0) + (@th2 + @kth2[0]/2.0))
        @kth1[1] = @T*(@thd1+@qth1[0]/2.0)
        @qth1[1] = @T*(s12*(@f - t2 - u2) + s22*(t1 + u1))/(s12*s21 - s11*s22)
        @kth2[1] = @T*(@thd2+@qth2[0]/2.0)
        @qth2[1] = @T*(s11*(t2 + u2 - @f) - s21*(t1 + u1))/(s12*s21 - s11*s22)
        s11 = @M1*@R1*@R1 + @M2*@L1*@L1 + @M2*@R2*@R2 + 2*@M2*@L1*@R2*Math.cos(@th2 + @kth2[1]/2.0) + @I1 + @I2
        s12 = @M2*@R2*@R2 + @M2*@L1*@R2*Math.cos(@th2 + @kth2[1]/2.0) + @I2
        s21 = s12
        s22 = @M2*@R2*@R2 + @I2
        t1 = (-1)*@M2*@L1*@R2*(2*(@thd1 + @qth1[1]/2.0) + (@thd2 + @qth2[1]/2.0))*(@thd2 + @qth2[1]/2.0)*Math.sin(@th2 + @kth2[1]/2.0)
        t2 = @M2*@L1*@R2*(@thd1 + @qth1[1]/2.0)*(@thd1 + @qth1[1]/2.0)*Math.sin(@th2 + @kth2[1]/2.0)
        u1 = (@M1*@R1 + @M2*@L1)*@G*Math.sin(@th1 + @kth1[1]/2.0) + @M2*@R2*@G*Math.sin((@th1 + @kth1[1]/2.0) + (@th2 + @kth2[1]/2.0))
        u2 = @M2*@R2*@G*Math.sin((@th1 + @kth1[1]/2.0) + (@th2 + @kth2[1]/2.0))
        @kth1[2] = @T*(@thd1+@qth1[1]/2.0)
        @qth1[2] = @T*(s12*(@f - t2 - u2) + s22*(t1 + u1))/(s12*s21 - s11*s22)
        @kth2[2] = @T*(@thd2+@qth2[1]/2.0)
        @qth2[2] = @T*(s11*(t2 + u2 - @f) - s21*(t1 + u1))/(s12*s21 - s11*s22)
        s11 = @M1*@R1*@R1 + @M2*@L1*@L1 + @M2*@R2*@R2 + 2*@M2*@L1*@R2*Math.cos(@th2 + @kth2[2]) + @I1 + @I2
        s12 = @M2*@R2*@R2 + @M2*@L1*@R2*Math.cos(@th2 + @kth2[2]) + @I2
        s21 = s12
        s22 = @M2*@R2*@R2 + @I2
        t1 = (-1)*@M2*@L1*@R2*(2*(@thd1 + @qth1[2]) + (@thd2 + @qth2[2]))*(@thd2 + @qth2[2])*Math.sin(@th2 + @kth2[2])
        t2 = @M2*@L1*@R2*(@thd1 + @qth1[2])*(@thd1 + @qth1[2])*Math.sin(@th2 + @kth2[2])
        u1 = (@M1*@R1 + @M2*@L1)*@G*Math.sin(@th1 + @kth1[2]) + @M2*@R2*@G*Math.sin((@th1 + @kth1[2]) + (@th2 + @kth2[2]))
        u2 = @M2*@R2*@G*Math.sin((@th1 + @kth1[2]) + (@th2 + @kth2[2]))
        @kth1[3] = @T*(@thd1+@qth1[2])
        @qth1[3] = @T*(s12*(@f - t2 - u2) + s22*(t1 + u1))/(s12*s21 - s11*s22)
        @kth2[3] = @T*(@thd2+@qth2[2])
        @qth2[3] = @T*(s11*(t2 + u2 - @f) - s21*(t1 + u1))/(s12*s21 - s11*s22)
    end
    def action(act)
        if act == 0 then
            @f = -1 * @F
        else
            @f = @F
        end
        Runge_kutta()
        @th1 += (@kth1[0] + 2.0*@kth1[1] + 2.0*@kth1[2] + @kth1[3])/6.0
        @th2 += (@kth2[0] + 2.0*@kth2[1] + 2.0*@kth2[2] + @kth2[3])/6.0
        if @th1 <= @TH1limit then
            @th1 = @TH1limit + (@th1 + @TH1limit)
        elsif @th1 > @TH1limit then
            @th1 = -1 * @TH1limit + (@th1 - @TH1limit)
        end
        if @th2 <= @TH2limit then
            @th2 = @TH2limit + (@th2 + @TH2limit)
        elsif @th2 > @TH2limit then
            @th2 = -1 * @TH2limit + (@th2 - @TH2limit)
        end
        @thd1 += (@qth1[0] + 2.0*@qth1[1] + 2.0*@qth1[2] + @qth1[3])/6.0;
        @thd2 += (@qth2[0] + 2.0*@qth2[1] + 2.0*@qth2[2] + @qth2[3])/6.0;
        if @thd1 > @THD1limit then
            @thd1 = @THD1limit
        elsif @thd1 <= @THD1limit then
            @thd1 = -1 * @THD1limit
        end
        if @thd2 > @THD2limit then
            @thd2 = @THD2limit
        elsif @thd2 <= @THD2limit then
            @thd2 = -1 * @THD2limit
        end
    end

    def fset()
        @GRID.times do |i|
            tmpj = []
            @GRID.times do |j|
                tmpk = []
                @GRID.times do |k|
                    tmpl = []
                    @GRID.times do |l|
                        tmpl << 0.0
                    end
                    tmpk << tmpl
                end
                tmpj << tmpk
            end
            @W_RIGHT << tmpj
            @W_LEFT << tmpj
        end
    end
    def cut(a)
        if a >= 1.0 then
            return 0.99999999
        elsif a <= -1.0 then
            return -0.99999999
        end
        return a
    end
    def out(x1, x2, x3, x4, a)
        i=@HGRID+(cut(x1/@TH1limit)*@HGRID).to_i;
        j=@HGRID+(cut(x2/@THD1limit)*@HGRID).to_i;
        k=@HGRID+(cut(x3/@TH2limit)*@HGRID).to_i;
        l=@HGRID+(cut(x4/@THD2limit)*@HGRID).to_i;
        if a == 0 then
            return @W_LEFT[i][j][k][l]
        else
            return @W_RIGHT[i][j][k][l]
        end
    end
    def selectNA()
        ql = out(@th1,@thd1,@th2,@thd2,0)
        qr = out(@th1,@thd1,@th2,@thd2,1)
        if ql > qr then
            @nQ = ql
        else
            @nQ = qr
        end
    end
    def selectA()
        ql = out(@th1,@thd1,@th2,@thd2,0)
        qr = out(@th1,@thd1,@th2,@thd2,1)
        if ql == qr or rand()<@RAND_MAX*@e_greedy then
            if rand()*2 > @RAND_MAX then
                @Q = ql
                return 0
            else
                @Q = qr
                return 1
            end
        elsif ql > qr then
            @Q = ql
            return 0
        else
            @Q = qr
            return 1
        end
    end
    def main()
        i = 0
        j = 0
        act = 0
        counter = 0
        rew = 0.0

        fset()

        @EPI.times do |e|
            @th1 = 0.0
            @thd1 = 0.0
            @th2 = 0.0
            @thd2 = 0.0
            while @Goalflag == 0 do
                @preth1 = @th1
                @prethd1 = @thd1
                @preth2 = @th2
                @prethd2 = @thd2

                act = selectA()
                action(act)
                p ['act',act,'Q',@Q]
                p ['cut:',cut(@th1/@TH1limit),cut(@thd1/@THD1limit),cut(@th2/@TH2limit),cut(@thd2/@THD2limit)]
                nanika = -(Math.cos(@th1)*Math.cos(@th2)-Math.sin(@th1)*Math.sin(@th2)+Math.cos(@th1))
                p ['nanika', nanika]
                if counter*@T >= @TL then
                    break
                end
                counter += 1
            end
            puts "Episode: " + e.to_s + "Time: " + (counter*@T).to_s
            @Goalflag = 0
            counter = 0
        end
    end
end

s = Simulation.new
s.main()
