# One problem with MRI Ruby (which it shares with a lot of language runtimes)
#   is that after allocating memory, even if the memory is GC'd, it will not be
#   returned to the OS
# Reclaimed memory can be reused by the same Ruby process, but not given to other processes
# This is a problem if you have long-running Ruby processes (like Rails apps...)
#   which may occasionally allocate a lot of memory (perhaps generating a report...)
# Especially is it a problem if you run *several instances* of the same app

# This module can be included in a controller to log the server's memory usage
#   after each request
# This may help to identify actions which are allocating too much memory

module MemoryLogger
  def self.included(cls)
    cls.class_eval do
      after_action :log_memory_usage
    end
  end

  def log_memory_usage
    if logger
      logger.info("Memory usage: #{`ps -o rss= -p #{Process.pid}`.strip}KB | PID: #{Process.pid}")
    end
  end
end
