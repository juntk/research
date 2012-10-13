# encoding: utf-8
# ruby -v => 1.8.7
require "thread"

class MyThread
    attr_accessor :threadConcurrency, :mode
    def initialize()
        # スレッド管理用
        @t = []
        # スレッドの並列度（同時実行数）
        @threadConcurrency = 1
        # 先入先出: @mode = 1
        # 後入先出: @mode = -1
        @mode = 1
    end
    def dump()
        p @t
    end
    def addThread(aWorkerObject = nil, aObject)
        # スレッド管理用の配列にスレッド入れる
        @t << Thread.new do
            # Thread#wakeupでスレッドを開始したいので、スレッドを止めとく
            # Thread#stopするとThread#statusは"sleep"になる
            Thread.stop
            # なんか重い処理
            aWorkerObject.call(aObject)
        end
    end
    def controlThread()
        # スレッドの並列実行数の調整と終了したスレッドの破棄
        begin
            # 実行中のスレッド数のチェック用
            runThreadNum = 0
            # 停止中のスレッドリスト
            stopThreadList = []
            @t.each_with_index do |v,i|
                # 終了したスレッドをスレッド管理用配列から破棄
                # Thread#statusがfalseのときスレッドが正常終了してる
                if v.status == false or v.status == "abort" or v.status == nil then
                    @t.delete_at(i)
                elsif v.status == "run" then
                    runThreadNum += 1
                elsif v.status == "sleep" then
                    # Thread#stop?は終了(dead)または停止(stop)のときにtrueを返す
                    #   -> これ、スレッドで行う処理の中にsleep 10とかあるとtrueが返ってきます。
                    stopThreadList << v
                else
                end
            end
            # 実行中のスレッド数と停止中のスレッドが分かったので
            # 並列実行度を元に停止状態(stop)のスレッドを実行可能状態(run)にする。
            (@threadConcurrency - runThreadNum).times do |t|
                # 雑というか無駄すぎる^^;
                if stopThreadList.size > 0 then
                    if @mode == 1 then
                        stopThreadList.shift.run
                    elsif @mode == -1
                        stopThreadList.pop.run
                    else
                        print 'WARNING: This mode is not defined.(',@mode,')'
                        stopThreadList.shift.run
                    end
                end
            end
        rescue error
            p error
        end
    end
end
