# encoding: utf-8
require "./MyThread.rb"

class MyThreadTest
    def initialize
        @thread = MyThread.new
        # �X���b�h�̕���x�i�f�t�H���g1�j
        @thread.threadConcurrency = 2
        # �ҋ@��Ԃ���̕��A���[�h�i1:�����o/-1:�����o/defalut:1�j
        @thread.mode = -1
    end
    def main()
        begin
            point = [10,20]

            methodObject = self.method(:worker)
            # MyThread#addThread�ɃX���b�h�ōs�����������\�b�h�I�u�W�F�N�g�Ƃ��đ���
            # �������̓��\�b�h�I�u�W�F�N�g�A�������̓X���b�h���烁�\�b�h�I�u�W�F�N�g���Ă΂��Ƃ��ɓn�����I�u�W�F�N�g
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
