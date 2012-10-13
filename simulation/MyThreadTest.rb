# encoding: utf-8
require "./MyThread.rb"

class MyThreadTest
    def initialize
        @thread = MyThread.new
        # スレッドの並列度（デフォルト1）
        @thread.threadConcurrency = 2
        # 待機状態からの復帰モード（1:先入先出/-1:後入先出/defalut:1）
        @thread.mode = -1
    end
    def main()
        begin
            point = [10,20]

            methodObject = self.method(:worker)
            # MyThread#addThreadにスレッドで行う処理をメソッドオブジェクトとして送る
            # 第一引数はメソッドオブジェクト、第二引数はスレッドからメソッドオブジェクトが呼ばれるときに渡されるオブジェクト
            @thread.addThread(methodObject, self)
            @thread.controlThread()

            @thread.dump()
            sleep 1
        end while true
    end
    def worker(aObject=nil)
        p aObject
        1000.times do |t|
            a = Math.sqrt(t) * Math.sqrt(t+1)
        end
    end
end

MyThreadTest.new.main()
