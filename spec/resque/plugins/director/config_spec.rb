require 'spec_helper'

describe Resque::Plugins::Director::Config do
  subject { Resque::Plugins::Director::Config }
  
  describe "#initialize" do  
    it "should set the variables to defaults if none are specified" do
      subject.min_workers.should == 1
      subject.wait_time.should == 60
    end
    
    it "should set the variables to the specified values" do
      subject.setup(:min_workers => 3, :wait_time => 30)
      subject.min_workers.should == 3
      subject.wait_time.should == 30
    end
    
    it "should handle bogus config options" do
      lambda { subject.setup(:bogus => 3) }.should_not raise_error
    end
    
    it "should set max_workers to default if less than min_workers" do
      subject.setup(:min_workers => 3, :max_workers => 2)
      subject.min_workers.should == 3
      subject.max_workers.should == 0
    end
  end
end