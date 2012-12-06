require 'tk'

class Graph4Var
    def initialize()
        @windowWidth = 640
        @windowHeight = 640

        root = TkRoot.new {title 'graph'}
        @canvas = TkCanvas.new(root, :width=>@windowWidth, :height=>@windowHeight)
        @canvas.pack()
    end
    def read(filePath)
        f = open(filePath,'r')
        lines = f.readlines()
        data = []
        lines.each_with_index do |line,index|
            columns = line.split(',')
            data << columns
        end
        return data
    end
    def plot(data,dataSize)
        graphIX = 0
        graphIY = 0
        graphPadding = 5
        graphWidth = (@windowWidth-graphPadding*dataSize[2])/dataSize[2]
        graphHeight = (@windowHeight-graphPadding*dataSize[3])/dataSize[3]
        colorFormat = ['#0000ff', '#0033cc', '#006666', '#00cc33', '#00ff00','#33cc00', '#666600', '#cc3300', '#ff0000']
        data.each_with_index do |d,i|
            if i == 0 then next end
            x2 = d[0].to_i
            y2 = d[1].to_i
            x = d[2].to_i
            y = d[3].to_i
            v = d[4].to_i
            if @prevX == nil or @prevY == nil or @prevX2 == nil or @prevY2 == nil then
                @prevX = x
                @prevY = y
                @prevX2 = x2
                @prevY2 = y2
            end
            if @prevX != x then
                graphIX = 0
                graphIY += 1
            elsif @prevY != y then
                graphIX += 1
            end
            p ["x",@prevX,x]
            p ["y",@prevY,y]
            p [graphIX, graphIY]

            # draw
            graphX1 = graphWidth * graphIX + graphPadding
            graphY1 = graphHeight * graphIY + graphPadding
                graphX1 += graphPadding * graphIX
                graphY1 += graphPadding * graphIY
            graphX2 = graphX1 + graphWidth
            graphY2 = graphY1 + graphHeight
            TkcRectangle.new(@canvas,graphX1,graphY1,graphX2,graphY2)

            plotPaddingX = graphWidth/dataSize[0]
            plotPaddingY = graphHeight/dataSize[0]
            plotX1 = graphX1 + plotPaddingX * x2
            plotY1 = graphY1 + plotPaddingY * y2
            plotX2 = plotX1 + plotPaddingX
            plotY2 = plotY1 + plotPaddingY
            color = '#ff0000'
            if v < 20 then
                color = colorFormat[0]
            elsif v < 30 then
                color = colorFormat[1]
            elsif v < 40 then
                color = colorFormat[2]
            elsif v < 50 then
                color = colorFormat[3]
            elsif v == 50 then
                color = colorFormat[4]
            elsif v == 51 then
                color = colorFormat[5]
            elsif v == 52 then
                color = colorFormat[6]
            elsif v == 53 then
                color = colorFormat[7]
            elsif v >= 54 then
                color = colorFormat[8]
            end
            TkcRectangle.new(@canvas,plotX1,plotY1,plotX2,plotY2,:fill=>color)


            @prevX = x
            @prevY = y
            @prevX2 = x2
            @prevY2 = y2
            @prevV = v
        end
        Tk.mainloop
    end
end

g = Graph4Var.new
path = 'qv.txt'
data = g.read(path)
g.plot(data,[9,9,10,10])
