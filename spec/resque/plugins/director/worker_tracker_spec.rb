require 'spec_helper'

describe Resque::Plugins::Director::WorkerTracker do
  subject { Resque::Plugins::Director::WorkerTracker }
  
  before do
    Resque::Plugins::Director::Config.queue = "test"
    @worker = Resque::Worker.new(:test)
  end
  
  describe "#workers" do
    before do
      Resque::Plugins::Director::Config.queue = "worker_test"
    end
    
    it"should return the workers for the queue" do
      Resque::Worker.new(:other).register_worker
      expected_worker = Resque::Worker.new(:worker_test)
      expected_worker.register_worker
      
      subject.new.workers.should == [expected_worker]
    end
    
    it "should not return workers working on multiple queues" do
      Resque::Worker.new(:worker_test, :other).register_worker
      subject.new.workers.should be_empty
    end
  end
  
  describe "#total_to_remove" do
    it "should limit the workers to be removed to not go below minimum allowed workers" do
      Resque.should_receive(:workers).and_return [@worker, @worker]
      Resque::Plugins::Director::Config.setup :min_workers => 1
      subject.new.total_to_remove(2).should == 1
    end
  
    it "always keeps at least one worker" do
      Resque.should_receive(:workers).and_return [@worker, @worker, @worker]
      Resque::Plugins::Director::Config.setup :min_workers => 0
      subject.new.total_to_remove(2).should == 2
    end
    
    it "should return zero if there is only one worker working" do
      Resque.should_receive(:workers).and_return [@worker]
      Resque::Plugins::Director::Config.setup :min_workers => 0
      subject.new.total_to_remove(1).should == 0
    end
  end


  describe "#total_to_add" do
    before do
      Resque.should_receive(:workers).and_return [@worker, @worker]
    end
    
    it "should limit the workers to be removed to not go below minimum allowed workers" do
      Resque::Plugins::Director::Config.setup :max_workers => 3
      subject.new.total_to_add(2).should == 1
    end
  
    it "should allow the workers to be removed if it stays above the minimum" do
      Resque::Plugins::Director::Config.setup :max_workers => 4
      subject.new.total_to_add(2).should == 2
    end
  
    it "should not limit workers added if max_workers is zero" do
      Resque::Plugins::Director::Config.setup :max_workers => 0
      subject.new.total_to_add(200).should == 200
    end
  end

  describe "#total_for_requirements" do
    it "should return the number of workers needed to meet the minimum requirement" do
      Resque.should_receive(:workers).and_return [@worker, @worker]
      Resque::Plugins::Director::Config.setup :min_workers => 4
      subject.new.total_for_requirements.should == 2
    end
    
    it "should return the number of workers needed to meet the maximum requirement" do
      Resque.should_receive(:workers).and_return [@worker, @worker]
      Resque::Plugins::Director::Config.setup :max_workers => 1
      subject.new.total_for_requirements.should == -1
    end
    
    it "should return 1 no workers are running and the minimum is zero" do
      Resque.should_receive(:workers).and_return []
      Resque::Plugins::Director::Config.setup :min_workers => 0
      subject.new.total_for_requirements.should == 1
    end
    
    it "should return 0 if number of workers is within requirements" do
      Resque.should_receive(:workers).and_return [@worker, @worker]
      Resque::Plugins::Director::Config.setup :min_workers => 1, :max_workers => 3
      subject.new.total_for_requirements.should == 0
    end
  end
  
  describe "#total_to_go_to_minimum" do
    it "should return the number to scale down to go to the minimum" do
      Resque.should_receive(:workers).and_return [@worker, @worker, @worker]
      Resque::Plugins::Director::Config.setup :min_workers => 2
      subject.new.total_to_go_to_minimum.should == 1
    end
    
    it "should return zero if already at the minimum" do
      Resque.should_receive(:workers).and_return [@worker, @worker, @worker]
      Resque::Plugins::Director::Config.setup :min_workers => 3
      subject.new.total_to_go_to_minimum.should == 0
    end
    
    it "should return zero if below the minimum" do
      Resque.should_receive(:workers).and_return [@worker, @worker, @worker]
      Resque::Plugins::Director::Config.setup :min_workers => 4
      subject.new.total_to_go_to_minimum.should == 0
    end
  end
  
  describe "#initialize" do
    it "sets the workers from the queue" do
      Resque.should_receive(:workers).and_return [@worker, @worker, @worker]
      subject.new.workers.should == [@worker, @worker, @worker]
    end
    
    it "does not set workers from different queues" do
      other_worker = Resque::Worker.new(:other)
      Resque.should_receive(:workers).and_return [@worker, other_worker, @worker]
      subject.new.workers.should == [@worker, @worker]
    end
    
    it "does not set workers that are scheduled for shutdow" do
      shutdown_worker = Resque::Worker.new(:test)
      shutdown_worker.shutdown
      Resque.should_receive(:workers).and_return [shutdown_worker, @worker, @worker]
      subject.new.workers.should == [@worker, @worker]
    end
  end
end