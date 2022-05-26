require 'listen'
require 'thread'

module Flair
  module Processes
    def cmd(command)
      output = send(:`, command)
      if $? != 0
        raise "Command failed: #{command}\nStatus: #{$?}\nOutput: #{output}"
      end
    end

    def pid(command, pidfile)
      raise "Pidfile #{pidfile} already exists" if File.exists?(pidfile)
      pid     = nil
      mutex   = Mutex.new
      cvar    = ConditionVariable.new
      timeout = 10 # seconds
      dir     = File.dirname(pidfile)
      Dir.mkdir(dir) unless File.directory?(dir)
      # Wait until the pidfile is written -- then we know the process has started
      listen  = Listen.to(dir) do |m, a, r|
        # On Alexis' Mac, specifying a path of '/tmp/pids/...' for pidfiles makes them actually
        #   land in '/private/tmp/pids/...'
        # Take this into account when checking the path which was written
        if m.any? { |fn| fn.include?(pidfile) } || a.any? { |fn| fn.include?(pidfile) }
          pid = File.read(pidfile)
          mutex.synchronize { cvar.broadcast } # wake up the main thread
        end
      end
      listen.start
      cmd(command)
      mutex.synchronize { cvar.wait(mutex, timeout) unless pid } # wait for pidfile to be written
      listen.stop
      raise "Process did not start in #{timeout}s: #{command}" if pid.nil?
      pid
    end

    def kill(pidfile)
      if File.exists?(pidfile)
        pid = File.read(pidfile).to_i
        Process.kill('SIGTERM', pid)
        while true
          Process.kill(0, pid) # will raise Errno::ESRCH when process is gone
          sleep(0.05) # we could also send SIGKILL if it takes too long to exit
        end
      end
    rescue Errno::ESRCH
    end
  end
end
