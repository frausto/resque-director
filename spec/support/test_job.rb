class TestJob
  extend Resque::Plugins::Director
  @queue = :test

  def self.perform
  end
end