require 'spec_helper'

describe Resque::Plugins::Director do
  before do
    TestJob.direct
  end
  
  it "should be a valid resque plugin" do
    Resque::Plugin.lint(Resque::Plugins::Director)
  end
  
  describe "#after_enqueue_scale_workers" do
    it "should scale the workers to within the requirments specified" do
      Resque::Worker.new(:test).register_worker
      Resque::Plugins::Director::Scaler.should_receive(:scale_within_requirements)
      Resque.enqueue(TestJob)
    end
    
    it "should set the queue" do
      Resque.enqueue(TestJob)
      Resque::Plugins::Director::Config.queue.should == "test"
    end
  end
  
  describe "#after_perform_direct_workers" do
    it "should scale down to the minumum workers if there are no jobs in the queue" do
      Resque::Plugins::Director::Scaler.should_receive(:scale_down_to_minimum)
      TestJob.after_perform_direct_workers
    end
    
    it "should not scale down if there are jobs in the queue" do
      Resque.enqueue(TestJob)
      Resque::Plugins::Director::Scaler.should_not_receive(:scale_down_to_minimum)
      TestJob.after_perform_direct_workers
    end
  end
  
  describe "#on_failure_direct_workers" do
    it "should scale down to the minumum workers if there are no jobs in the queue" do
      Resque::Plugins::Director::Scaler.should_receive(:scale_down_to_minimum)
      TestJob.on_failure_direct_workers
    end
    
    it "should not scale down if there are jobs in the queue" do
      Resque.enqueue(TestJob)
      Resque::Plugins::Director::Scaler.should_not_receive(:scale_down_to_minimum)
      TestJob.on_failure_direct_workers
    end
  end
  
  describe "#after_pop_direct_workers" do
    describe "with time" do
      before do
        @start_time = (Time.now - 10).utc
      end
      
      it "should set the queue if not set" do
        TestJob.direct :max_time => 20
        Resque::Plugins::Director::Config.queue = nil
        TestJob.after_pop_direct_workers(@start_time)
        Resque::Plugins::Director::Config.queue.should == "test"
      end
    
      it "should not start workers if max_time is not set" do
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        TestJob.after_pop_direct_workers(@start_time)
      end 
    
      it "should not start a worker if the time since it took is less than max_time" do
        TestJob.direct :max_time => 20
      
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        TestJob.after_pop_direct_workers(@start_time)
      end
    
      it "should add a worker if the time it takes the job to go through the queue is too long" do
        TestJob.direct :max_time => 5
        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
      
        TestJob.after_pop_direct_workers(@start_time)
      end
      
      it "should remove a worker if the queue time is below half the max" do
        TestJob.direct :max_time => 25
        
        Resque::Plugins::Director::Scaler.should_receive(:scale_down)
        TestJob.after_pop_direct_workers(@start_time)
      end
    end
    
    describe "with queue length" do
      it "should not start workers if max_queue is not set" do
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        TestJob.after_pop_direct_workers
      end
      
      it "should not start worker if the queue length is less than max_queue" do
        TestJob.direct :max_queue => 2
        Resque.enqueue(TestJob)
      
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        TestJob.after_pop_direct_workers
      end
      
      it "should start worker if the queue length is greater than max_queue" do
        TestJob.direct :max_queue => 1
        2.times { Resque.enqueue(TestJob) }
      
        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
        TestJob.after_pop_direct_workers
      end
      
      it "should remove a worker if the queue length is below half the max" do
        TestJob.direct :max_queue => 4
        1.times { Resque.enqueue(TestJob) }
        
        Resque::Plugins::Director::Scaler.should_receive(:scale_down)
        TestJob.after_pop_direct_workers
      end
    end
    
    describe "with length and time" do
      before do
        @start_time = (Time.now - 10).utc
      end
      
      it "should add worker if only time constraint fails" do
        TestJob.direct :max_time => 5, :max_queue => 2
        Resque.enqueue(TestJob)
        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
      
        TestJob.after_pop_direct_workers(@start_time)
      end
      
      it "should add worker if only queue length constraint fails" do
        TestJob.direct :max_time => 15, :max_queue => 1
        2.times { Resque.enqueue(TestJob) }
      
        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
        TestJob.after_pop_direct_workers
      end
      
      it "should not scale down if a worker is being scaled up due to time" do
        TestJob.direct :max_queue => 4, :max_time => 5
        1.times { Resque.enqueue(TestJob) }

        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_down)
        TestJob.after_pop_direct_workers(@start_time)
      end
      
      it "should not scale down if a worker is being scaled up due to queue" do
        TestJob.direct :max_queue => 1, :max_time => 30
        2.times { Resque.enqueue(TestJob) }

        Resque::Plugins::Director::Scaler.should_receive(:scale_up)
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_down)
        TestJob.after_pop_direct_workers
      end
      
      it "should not scale if only one limit is met" do
        TestJob.direct :max_queue => 3, :max_time => 15
        1.times { Resque.enqueue(TestJob) }

        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_down)
        TestJob.after_pop_direct_workers(@start_time)
      end
      
      it "should not scale if no configuration options are set" do
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
        Resque::Plugins::Director::Scaler.should_not_receive(:scale_down)
        TestJob.after_pop_direct_workers
      end
    end
  end
end
