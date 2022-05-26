require 'stringio'
require 'pry'
require 'parser/current'
require 'rouge'
require 'debug_inspector'
require 'selenium-webdriver'
require 'capybara/dsl'

# Opt in to most recent AST format from 'parser'
Parser::Builders::Default.emit_lambda   = true
Parser::Builders::Default.emit_procarg0 = true
Parser::Builders::Default.emit_encoding = true
Parser::Builders::Default.emit_index    = true

module Flair
  module Test
    module Utils
      # For syntax-highlighting Ruby code
      HILITER = Rouge::Formatters::Terminal256.new(Rouge::Themes::Monokai.new)
      LEXER   = Rouge::Lexers::Ruby.new

      def highlight_ruby(code, indent=0)
        code = reindent_lines(code, indent).join if code.is_a?(Array)
        HILITER.format(LEXER.lex(code))
      end

      def pp(object) # pretty print
        s = StringIO.new
        Pry::ColorPrinter.pp(object, s)
        s.string.chomp!
      end

      # When a test fails, we want to show the code for the failing assertion
      # To do this, we need to find the test code which called into this test framework
      # Return [Thread::Backtrace::Location, number of stack frames we had to go back]
      def framework_entry_location
        # go back on call stack to find caller which is NOT inside test framework
        frames = 2
        begin
          location = caller_locations(frames, 1)[0]
          frames += 1
        end while location.absolute_path.nil? || location.absolute_path == __FILE__ ||
                  location.absolute_path =~ /lib\/ruby\/gems\//
        [location, frames-1]
      end

      def framework_entry_source(line_from, line_to)
        location, = framework_entry_location
        source_lines(location, line_from, line_to)
      end

      def source_lines(location, line_from, line_to)
        # line 0 is the actual line of interest, -1 is just before that,
        #   1 is just after that, etc.
        line_from += location.lineno - 1
        line_to   += location.lineno - 1

        if File.exists?(location.absolute_path)
          lines = File.readlines(location.absolute_path)
          lines[[0, line_from].max..[line_to, lines.size-1].min]
        end
      end

      def reindent_lines(lines, indent)
        existing_indent = lines.reject { |line| line =~ /^\s*$/}.map { |line| line[/^[ ]*/].size }.min
        indent -= existing_indent
        if indent < 0
          lines.map { |line| line[-indent..-1] }
        else
          lines.map { |line| (' ' * indent) << line }
        end
      end
    end

    class DefaultFormatter
      include Utils
      include Pry::Helpers::Text

      def initialize
        @show_source = false
      end
      attr_accessor :show_source

      def starting_suite(name)
        puts name
      end

      def ending_suite
        puts
      end

      def starting_test(name)
        print "  \u2022 " # indent
        print name
      end

      def test_passed
        puts green(" \u2713")
      end

      def test_failed(message, location)
        puts red(" \u2717")
        puts
        print '    '
        puts message
        puts "    (at #{location.absolute_path}:#{location.lineno})"
        puts
        if @show_source && (lines = source_lines(location, -2, 2))
          lines.shift while lines[0]  && lines[0]  =~ /^\s*$/
          lines.pop   while lines[-1] && lines[-1] =~ /^\s*$/
          puts bold('    Test source:')
          puts
          puts highlight_ruby(lines, 4)
        end
      end

      def test_error(exception)
        puts red(" E")
        puts
        puts exception.full_message
        puts
      end
    end

    # Used to abort a test and move to the next one
    Failure = Class.new(StandardError)

    # Abstract superclass for any class which runs tests
    class Suite
      include Utils

      # Subclasses must define #run
      # It should start by calling #start_suite
      # Before starting each 'test' in the 'suite', #run should call #start_test
      # After each test successfully ends, #run should call #pass_test
      # If an unexpected exception occurs in test, #run should call #error
      # If a test fails, Failure exception will be raised
      # After all the tests, #run should call #end_suite

      # Subclasses must also define #n_tests

      def initialize
        @failed_assertions = @passed_assertions = @failed_tests = @passed_tests = @errored_tests = 0
        @formatter = DefaultFormatter.new
        @name      = self.class.name
      end
      attr_accessor :name, :failed_assertions, :passed_assertions, :failed_tests, :passed_tests, :errored_tests

      ON_FAILURE_WE_CAN = [:launch_repl].freeze
      def on_failure(what_to_do)
        raise ArgumentError unless what_to_do.nil? || ON_FAILURE_WE_CAN.include?(what_to_do)
        @on_failure = what_to_do
      end

      def start_suite
        @formatter.starting_suite(self.name)
        Thread.current[:test_suite] = self
      end
      def end_suite
        @formatter.ending_suite
      end
      def start_test(name)
        @formatter.starting_test(name)
      end
      def pass_test
        @formatter.test_passed
        @passed_tests += 1
      end
      def error(exception)
        # an unexpected exception occurred in test code
        @formatter.test_error(exception)
        launch_repl(*framework_entry_location) if @on_failure == :launch_repl
        @errored_tests += 1
      end

      def fail(message)
        location, frames = framework_entry_location
        @formatter.test_failed(message, location)
        launch_repl(location, frames) if @on_failure == :launch_repl
        @failed_assertions += 1
        @failed_tests += 1
        if $carry_on_bravely
          $carry_on_bravely = false
        else
          raise Failure
        end
      end

      def pass
        @passed_assertions += 1
      end

      def launch_repl(location, frames)
        RubyVM::DebugInspector.open { |dc| __binding__ = dc.frame_binding(frames+1) }
        if location.absolute_path
          __binding__.eval <<-CODE
            def edit!
              open_editor!(#{location.absolute_path.inspect}, #{location.lineno})
            end
          CODE
        else
          __binding__.eval 'def edit!; raise "Can\'t edit code eval\'d from a string"; end'
        end
        __binding__.eval <<-CODE
          def continue!
            # Normally the rest of a unit test, or the rest of a browser suite, would be
            #   skipped if an assertion fails
            # This tells the test framework to carry on despite the failed assertion
            $carry_on_bravely = true
          end
        CODE
        __binding__.pry
      end
    end

    # Use from test code as:
    #
    #   something.must == 'a value'
    #   something.must > 5
    #
    # ...and so on...
    class Expectation
      include Utils

      def initialize(target, reverse_sense=false)
        @target  = target
        @context = Thread.current[:test_suite]
        @reverse = reverse_sense
      end

      private

      # Utils
      def caller_ast
        @caller_ast ||= if caller_src = framework_entry_source(0, 1)
          Parser::CurrentRuby.parse(caller_src[0])
        end
      end

      def expectation_node
        @expectation_node ||= if caller_ast
          caller_ast.find do |node|
            node.type == :send && (node.children[1] == :must || node.children[1] == :must_not)
          end
        end
      end

      def assertion_node(assertion_method)
        @assertion_node ||= if caller_ast
          caller_ast.find do |node|
            node.type == :send && node.children[1] == assertion_method &&
              ((child = node.children[0]).is_a?(AST::Node)) && child.type == :send &&
              (child.children[1] == :must || child.children[1] == :must_not)
          end
        end
      end

      def show_receiver
        show_node(expectation_node && expectation_node.children[0], @target)
      end

      def show_argument(value, assertion_method)
        show_node((node = assertion_node(assertion_method)) && node.children[2], value)
      end

      def show_node(node, value)
        unless !node || node.literal?
          return "#{highlight_ruby(node.loc.expression.source)} \u27ea\u2192 #{pp(value)}\u27eb"
        end
        pp(value)
      end

      def test_binary_predicate(method, message, argument)
        unless @target.respond_to?(method) && (!!@target.send(method, argument) ^ @reverse)
          message = message.sub('must', 'must not') if @reverse
          @context.fail("#{show_receiver} #{message} #{show_argument(argument, method)}")
        end
        @context.pass
      end

      def self.def_binary_assertion(method, message)
        define_method(method) do |argument|
          test_binary_predicate(method, message, argument)
        end
      end

      def_binary_assertion :==, "must be equal to"
      def_binary_assertion :eq, "must be the same as"
      def_binary_assertion :>,  "must be greater than"
      def_binary_assertion :<,  "must be less than"
      def_binary_assertion :>=, "must be greater than or equal to"
      def_binary_assertion :<=, "must be less than or equal to"
      def_binary_assertion :=~, "must match"

      def test_unary_predicate(method, message)
        # If target does not respond to 'method', that is always a failure
        unless @target.respond_to?(method) && (!!@target.send(method) ^ @reverse)
          message = message.sub('must', 'must not') if @reverse
          @context.fail("#{show_receiver} #{message}")
        end
        @context.pass
      end

      def self.def_unary_assertion(assertion, predicate, message)
        define_method(assertion) { test_unary_predicate(predicate, message) }
      end

      # automatically define predicates like be_nil, be_empty, etc. on first use
      def method_missing(method_name, *args)
        if adjective = method_name[/^be_(\w+)$/, 1]
          self.class.def_unary_assertion(method_name, "#{adjective}?".to_sym, "must be #{adjective}")
          send(method_name, *args)
        else
          super
        end
      end

      public

      # For DOM nodes (Capybara::Node)
      # All these methods automatically wait for the assertion to become true, just
      #   like Capybara's #find waits for element to appear
      #
      # Usage:
      #   node.must.match_selector('p#foo')
      #   node.must_not.match_selector(:xpath, '//p[@id="foo"]')
      #
      def match_selector(*args)
        begin
          if @reverse
            @target.assert_not_matches_selector(*args)
          else
            @target.assert_matches_selector(*args)
          end
        rescue Capybara::ExpectationNotMet
          @context.fail("#{show_receiver} #{@reverse ? 'matched' : 'did not match'} selector: #{pp(args)}")
        end
        @context.pass
      end

      def be_visible
        begin
          @target.synchronize(Capybara.default_max_wait_time) do
            raise Capybara::ExpectationNotMet unless @target.visible? ^ @reverse
          end
        rescue Capybara::ExpectationNotMet
          @context.fail("#{show_receiver} #{@reverse ? 'must not' : 'must'} be visible")
        end
        @context.pass
      end

      def have_text(text)
        begin
          @target.synchronize(Capybara.default_max_wait_time) do
            raise Capybara::ExpectationNotMet unless (@target.text == text) ^ @reverse
          end
        rescue Capybara::ExpectationNotMet
          @context.fail("#{show_receiver} #{@reverse ? 'must not' : 'must'} have text: #{show_argument(text, :have_text)}")
        end
        @context.pass
      end

      def have_selector(*args)
        begin
          if @reverse
            @target.assert_no_selector(*args)
          else
            @target.assert_selector(*args)
          end
        rescue Capybara::ExpectationNotMet
          @context.fail("#{show_receiver} #{@reverse ? 'had' : 'did not have'} selector: #{pp(args)}")
        end
        @context.pass
      end
    end

    module Unit
      class Suite < ::Flair::Test::Suite
        # Like Test::Unit; methods which start with 'test_' are test cases
        def run
          start_suite
          methods.select { |m| m =~ /^test_/ }.each do |method_name|
            start_test(method_name.to_s)
            begin
              send(method_name)
              pass_test
            rescue Failure # proceed to next test case
            rescue => e
              error(e)
            end
          end
          end_suite
        end

        def n_tests
          methods.select { |m| m =~ /^test/ }.size
        end
      end
    end

    # tests in a Unit::Suite are independent
    # in contrast, tests in a SequentialSuite form a 'script' and must run in order
    class SequentialSuite < Suite
      class << self
        attr_reader :steps
      end

      def self.inherited(subclass)
        subclass.instance_variable_set(:@steps, [])
      end

      def self.start_by(description, &block)
        @steps.unshift([description, block])
      end

      # Can't use 'then' or 'next' because those are Ruby keywords. Grrr
      def self._then(description, &block)
        @steps.push([description, block])
      end

      def run
        start_suite
        begin
          self.class.steps.each do |description, block|
            start_test(description)
            instance_eval(&block)
            pass_test
          end
        rescue Failure # skip the rest of test suite
        rescue => e
          error(e)
        end
        end_suite
      end

      def n_tests
        self.class.steps.size
      end
    end

    module Browser
      class Suite < SequentialSuite
        def initialize(browser, open_db)
          super()
          @browser = browser # Capybara::Session
          @open_db = open_db # lambda
          @db      = nil     # Sequel::Database
        end

        attr_reader :browser, :db
        alias_method :page, :browser

        Capybara::Session::DSL_METHODS.each do |method|
          define_method(method) do |*args, &block|
            @browser.send(method, *args, &block)
          end
        end

        def run
          @db = @open_db.call
          super
          @db.disconnect
        end
      end
    end

    class Runner
      include Pry::Helpers::Text

      def initialize(suites)
        @suites = suites
      end

      def on_failure(what_to_do)
        @suites.each { |suite| suite.on_failure(what_to_do) }
      end

      def run
        total_tests = passed_tests = total_assertions = passed_assertions = 0
        @suites.each do |suite|
          suite.run
          total_tests  += suite.n_tests
          passed_tests += suite.passed_tests
          total_assertions  += suite.passed_assertions + suite.failed_assertions
          passed_assertions += suite.passed_assertions
        end
        puts '=' * 40
        if passed_tests == total_tests
          print green(bold("All passed!"))
          puts " (#{passed_tests} tests, #{passed_assertions} assertions)"
          0 # return process exit status
        else
          print red(bold("Failed"))
          puts " (#{passed_tests}/#{total_tests} tests OK, #{passed_assertions}/#{total_assertions} assertions OK)"
          1
        end
      end
    end
  end
end

class Object
  # Assertions must be available from anywhere in test code
  def must
    Flair::Test::Expectation.new(self)
  end

  def must_not
    Flair::Test::Expectation.new(self, true)
  end

  def try_assertion_repeatedly
    tries = 10
    loop do
      yield
      break
    rescue Flair::Test::Failure
      tries -= 1
      if tries < 0
        raise
      else
        sleep(0.05) # wait 50msec before trying again
      end
    end
  end

  # When an assertion fails and we drop into a REPL, developer can type 'edit!'
  #   to open the test code
  # Support code for this feature:

  def run_in_terminal!(cmd)
    if Gem::Platform.local.os ==~ /mac|darwin/
      cmd = "open -a Terminal '#{cmd}'"
    elsif !`which gnome-terminal`.empty?
      cmd = "gnome-terminal -x #{cmd}"
    else
      # add more terminals if necessary
      raise "Don't know which terminal to use"
    end
    system(cmd)
  end

  def open_editor!(file, lineno)
    editor = ENV['EDITOR']
    # if EDITOR is not set, check which editors are on the PATH...
    (editor = 'nano'; need_terminal = true) if !editor && !`which nano`.empty?
    (editor = 'vim';  need_terminal = true) if !editor && !`which vim`.empty?
    # add more editors if necessary

    cmd = "#{editor} +#{lineno} \"#{file}\""
    need_terminal ? run_in_terminal!(cmd) : system(cmd)
  end
end

# Support code for deciding when to print source for target of failing assertion

class AST::Node
  def literal?
    type == :true || type == :false || type == :nil || type == :int ||
      type == :float || type == :complex || type == :rational || type == :str ||
      type == :string || type == :sym || type == :regexp || compound_literal?
  end

  def compound_literal?
    (type == :array || type == :pair || type == :hash || type == :irange || type == :erange) &&
    children.all?(&:literal?)
  end

  def find(&block)
    if yield(self)
      self
    else
      children.find { |child| child.is_a?(AST::Node) && child.find(&block) }
    end
  end
end
