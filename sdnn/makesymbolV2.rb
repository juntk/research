symbolLength = 200

def makeSymbol(aLength, aBefore=[])
    tmp = []
    plusCount = 0
    minusCount = 0
    if aBefore.length == 0 then
        flug = aLength / 2
        aLength.times do |t|
            """
            if t < flug then
                tmp << '1'
            else
                tmp << '-1'
            end
            """
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
            p [ minusCount, plusCount]

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

symbols = {}
400.times do |t|
    begin
        if t == 0 then
            tmp = makeSymbol(symbolLength)
        else
            tmp = makeSymbol(symbolLength,symbols[(t-1).to_s])
        end
    end while existDuplex(symbols, tmp)
    symbols[t.to_s] = tmp
end

#p symbols

# save as a file
body = ''
symbols.length.times do |index|
    body += index.to_s + "=>" +symbols[index.to_s].join(' ') + "\r\n"
end

filePath = 'sdnn/Symbol.txt'
File.open(filePath,'w') do |file|
    file.write body 
end

puts
puts "Saved:" + filePath
