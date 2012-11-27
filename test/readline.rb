require 'readline'

def getEnv()
    lines = ENV['LINES']
    columns = ENV['COLUMNS']
    return lines, columns
end
def checkEnv()
    lines, columns = getEnv()
    print "ENV['LINES'] => ", lines
    puts
    print "ENV['COLUMNS'] => ", columns
    puts
end
def putLine()
    lines, columns = getEnv()
    columns.to_i.times do |t|
        print '-'
    end
    puts
end

checkEnv()
puts

Readline.readline('Readline>')
checkEnv()

putLine()
checkEnv()

