require 'java'

java_import java.util.concurrent.Executors
java_import java.lang.Runtime
java_import java.util.concurrent.Callable


class ExTask
  include Callable

  CALLABLE_CLASS = java.lang.Class.for_name("java.util.concurrent.Callable")

  def initialize(data, &block)
    @data = data
    @work = block
  end

  def call
    @work.call(@data)
  end

  def self.pools; @pools ||= {}; end

  def self.pool(pool_key = :default, parallel = Runtime.getRuntime.availableProcessors)
    queue = pools[pool_key]
    if queue.nil?
      Unsplitter.logger.info "Starting executors[#{pool_key}] with #{parallel} thread(s)"
      queue = Executors.newFixedThreadPool(parallel)
      @pools[pool_key] = queue
      at_exit {
        shutdown(pool_key)
      }
    end
    queue
  end

  def self.shutdown(pool_key = :default)
    queue = pools[pool_key]
    if queue
      queue.shutdown
      pools.delete(pool_key)
    end
  end

  def self.queue_task(data, pool_key = :default, &block)
    queue_ex_task(pool[pool_key], ExTask.new(data, &block))
  end

  def self.queue_ex_task(pool, task)
    pool.java_send :submit, [CALLABLE_CLASS], task
  end

end

