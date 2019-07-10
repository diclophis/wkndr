#!/usr/bin/env ruby

ENV={}

class String
  def end_with?(chr)
    self[length-1] == chr
  end
end

class Thor
  module CoreExt #:nodoc:
    # A hash with indifferent access and magic predicates.
    #
    #   hash = Thor::CoreExt::HashWithIndifferentAccess.new 'foo' => 'bar', 'baz' => 'bee', 'force' => true
    #
    #   hash[:foo]  #=> 'bar'
    #   hash['foo'] #=> 'bar'
    #   hash.foo?   #=> true
    #
    class HashWithIndifferentAccess < ::Hash #:nodoc:
      def initialize(hash = {})
        super()
        hash.each do |key, value|
          self[convert_key(key)] = value
        end
      end

      def [](key)
        super(convert_key(key))
      end

      def []=(key, value)
        super(convert_key(key), value)
      end

      def delete(key)
        super(convert_key(key))
      end

      def fetch(key, *args)
        super(convert_key(key), *args)
      end

      def key?(key)
        super(convert_key(key))
      end

      def values_at(*indices)
        indices.map { |key| self[convert_key(key)] }
      end

      def merge(other)
        dup.merge!(other)
      end

      def merge!(other)
        other.each do |key, value|
          self[convert_key(key)] = value
        end
        self
      end

      def reverse_merge(other)
        self.class.new(other).merge(self)
      end

      def reverse_merge!(other_hash)
        replace(reverse_merge(other_hash))
      end

      def replace(other_hash)
        super(other_hash)
      end

      # Convert to a Hash with String keys.
      def to_hash
        Hash.new(default).merge!(self)
      end

    protected

      def convert_key(key)
        key.is_a?(Symbol) ? key.to_s : key
      end

      # Magic predicates. For instance:
      #
      #   options.force?                  # => !!options['force']
      #   options.shebang                 # => "/usr/lib/local/ruby"
      #   options.test_framework?(:rspec) # => options[:test_framework] == :rspec
      #
      def method_missing(method, *args)
        method = method.to_s
        #TODO
        if method =~ /^(\w+)\?$/
          if args.empty?
            !!self[$1]
          else
            self[$1] == args.first
          end
        else
          self[method]
        end
      end
    end
  end
end

class Thor
  module CoreExt
    class OrderedHash < ::Hash
      if RUBY_VERSION < "1.9"
        def initialize(*args, &block)
          super
          @keys = []
        end

        def initialize_copy(other)
          super
          # make a deep copy of keys
          @keys = other.keys
        end

        def []=(key, value)
          @keys << key unless key?(key)
          super
        end

        def delete(key)
          if key? key
            index = @keys.index(key)
            @keys.delete_at index
          end
          super
        end

        def delete_if
          super
          sync_keys!
          self
        end

        alias_method :reject!, :delete_if

        def reject(&block)
          dup.reject!(&block)
        end

        def keys
          @keys.dup
        end

        def values
          @keys.map { |key| self[key] }
        end

        def to_hash
          self
        end

        def to_a
          @keys.map { |key| [key, self[key]] }
        end

        def each_key
          return to_enum(:each_key) unless block_given?
          @keys.each { |key| yield(key) }
          self
        end

        def each_value
          return to_enum(:each_value) unless block_given?
          @keys.each { |key| yield(self[key]) }
          self
        end

        def each
          return to_enum(:each) unless block_given?
          @keys.each { |key| yield([key, self[key]]) }
          self
        end

        def each_pair
          return to_enum(:each_pair) unless block_given?
          @keys.each { |key| yield(key, self[key]) }
          self
        end

        alias_method :select, :find_all

        def clear
          super
          @keys.clear
          self
        end

        def shift
          k = @keys.first
          v = delete(k)
          [k, v]
        end

        def merge!(other_hash)
          if block_given?
            other_hash.each { |k, v| self[k] = key?(k) ? yield(k, self[k], v) : v }
          else
            other_hash.each { |k, v| self[k] = v }
          end
          self
        end

        alias_method :update, :merge!

        def merge(other_hash, &block)
          dup.merge!(other_hash, &block)
        end

        # When replacing with another hash, the initial order of our keys must come from the other hash -ordered or not.
        def replace(other)
          super
          @keys = other.keys
          self
        end

        def inspect
          "#<#{self.class} #{super}>"
        end

        private

        def sync_keys!
          @keys.delete_if { |k| !key?(k) }
        end
      end
    end
  end
end

class Thor
  # Thor::Error is raised when it's caused by wrong usage of thor classes. Those
  # errors have their backtrace suppressed and are nicely shown to the user.
  #
  # Errors that are caused by the developer, like declaring a method which
  # overwrites a thor keyword, SHOULD NOT raise a Thor::Error. This way, we
  # ensure that developer errors are shown with full backtrace.
  class Error < StandardError
  end

  # Raised when a command was not found.
  class UndefinedCommandError < Error
  end
  UndefinedTaskError = UndefinedCommandError

  class AmbiguousCommandError < Error
  end
  AmbiguousTaskError = AmbiguousCommandError

  # Raised when a command was found, but not invoked properly.
  class InvocationError < Error
  end

  class UnknownArgumentError < Error
  end

  class RequiredArgumentMissingError < InvocationError
  end

  class MalformattedArgumentError < InvocationError
  end
end

class Thor
  class Command < Struct.new(:name, :description, :long_description, :usage, :options, :ancestor_name)
    #FILE_REGEXP = /^#{Regexp.escape(File.dirname(__FILE__))}/

    def initialize(name, description, long_description, usage, options = nil)
      super(name.to_s, description, long_description, usage, options || {})
    end

    def initialize_copy(other) #:nodoc:
      super(other)
      self.options = other.options.dup if other.options
    end

    def hidden?
      false
    end

    # By default, a command invokes a method in the thor class. You can change this
    # implementation to create custom commands.
    def run(instance, args = [])
      arity = nil
      #TODO
      if private_method?(instance)
        instance.class.handle_no_command_error(name)
      elsif public_method?(instance)
        #arity = instance.method(name).arity
        instance.__send__(name, *args)
      elsif local_method?(instance, :method_missing)
      raise "bar"
        instance.__send__(:method_missing, name.to_sym, *args)
      else
      raise "biz"
        instance.class.handle_no_command_error(name)
      end
    #rescue ArgumentError => e
    #  handle_argument_error?(instance, e, caller) ? instance.class.handle_argument_error(self, e, args, arity) : (raise e)
    #rescue NoMethodError => e
    #raise "asdasdasdasd"
    #  handle_no_method_error?(instance, e, caller) ? instance.class.handle_no_command_error(name) : (raise e)
    end

    # Returns the formatted usage by injecting given required arguments
    # and required options into the given usage.
    def formatted_usage(klass, namespace = true, subcommand = false)
      if ancestor_name
        formatted = "#{ancestor_name} ".dup # add space
      elsif namespace
        namespace = klass.namespace
        formatted = "#{namespace.gsub(/^(default)/, '')}:".dup
      end
      formatted ||= "#{klass.namespace.split(':').last} ".dup if subcommand

      formatted ||= "".dup

      # Add usage with required arguments
      formatted += if klass && !klass.arguments.empty?
                     usage.to_s.gsub(/^#{name}/) do |match|
                       match << " " << klass.arguments.map(&:usage).compact.join(" ")
                     end
                   else
                     usage.to_s
                   end

      # Add required options
      formatted += " #{required_options}"

      # Strip and go!
      #.strip
      formatted
    end

  protected

    def not_debugging?(instance)
      !(instance.class.respond_to?(:debugging) && instance.class.debugging)
    end

    def required_options
      #@required_options ||= 
      #TODO????????
      options.map { |_, o| o.usage if o.required? }.compact.sort.join(" ")
    end

    # Given a target, checks if this class name is a public method.
    def public_method?(instance) #:nodoc:
      #TODO
      #raise "#{instance.public_methods} i--------------i #{[name.to_s, name.to_sym]}"
      #!(instance.public_methods & [name.to_s, name.to_sym]).empty?
      true
    end

    def private_method?(instance)
      #!(instance.private_methods & [name.to_s, name.to_sym]).empty?
      false
    end

    def local_method?(instance, name)
      methods = instance.public_methods(false) + instance.private_methods(false) + instance.protected_methods(false)
      !(methods & [name.to_s, name.to_sym]).empty?
    end

    def sans_backtrace(backtrace, caller) #:nodoc:
      #TODO!!!! |frame| frame =~ FILE_REGEXP || (frame =~ /\.java:/ && RUBY_PLATFORM =~ /java/) || (frame =~ %r{^kernel/} && RUBY_ENGINE =~ /rbx/) }
      saned = backtrace.reject { }
      saned - caller
    end

    def handle_argument_error?(instance, error, caller)
      not_debugging?(instance) && (error.message =~ /wrong number of arguments/ || error.message =~ /given \d*, expected \d*/) && begin
        saned = sans_backtrace(error.backtrace, caller)
        # Ruby 1.9 always include the called method in the backtrace
        saned.empty? || (saned.size == 1 && RUBY_VERSION >= "1.9")
      end
    end

    def handle_no_method_error?(instance, error, caller)
      not_debugging?(instance) &&
        error.message =~ /^undefined method `#{name}' for #{(instance.to_s)}$/
    end
  end
  Task = Command

  # A command that is hidden in help messages but still invocable.
  class HiddenCommand < Command
    def hidden?
      true
    end
  end
  HiddenTask = HiddenCommand

  # A dynamic command that handles method missing scenarios.
  class DynamicCommand < Command
    def initialize(name, options = nil)
      super(name.to_s, "A dynamically-generated command", name.to_s, name.to_s, options)
    end

    def run(instance, args = [])
      #TODO?????
      if (instance.methods & [name.to_s, name.to_sym]).empty?
        instance.class.handle_no_command_error(name)
      else
      #raise "ASDASDASDASDASDASD #{instance.methods} #{name}"
        super
      end
    end
  end
  DynamicTask = DynamicCommand
end

class Thor
  module Invocation
    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      # This method is responsible for receiving a name and find the proper
      # class and command for it. The key is an optional parameter which is
      # available only in class methods invocations (i.e. in Thor::Group).
      def prepare_for_invocation(key, name) #:nodoc:
        case name
        when Symbol, String
          Thor::Util.find_class_and_command_by_namespace(name.to_s, !key)
        else
          name
        end
      end
    end

    # Make initializer aware of invocations and the initialization args.
    def initialize(args = [], options = {}, config = {}, &block) #:nodoc:
      @_invocations = config[:invocations] || Hash.new { |h, k| h[k] = [] }
      @_initializer = [args, options, config]
      super
    end

    # Make the current command chain accessible with in a Thor-(sub)command
    def current_command_chain
      @_invocations.values.flatten.map(&:to_sym)
    end

    # Receives a name and invokes it. The name can be a string (either "command" or
    # "namespace:command"), a Thor::Command, a Class or a Thor instance. If the
    # command cannot be guessed by name, it can also be supplied as second argument.
    #
    # You can also supply the arguments, options and configuration values for
    # the command to be invoked, if none is given, the same values used to
    # initialize the invoker are used to initialize the invoked.
    #
    # When no name is given, it will invoke the default command of the current class.
    #
    # ==== Examples
    #
    #   class A < Thor
    #     def foo
    #       invoke :bar
    #       invoke "b:hello", ["Erik"]
    #     end
    #
    #     def bar
    #       invoke "b:hello", ["Erik"]
    #     end
    #   end
    #
    #   class B < Thor
    #     def hello(name)
    #       puts "hello #{name}"
    #     end
    #   end
    #
    # You can notice that the method "foo" above invokes two commands: "bar",
    # which belongs to the same class and "hello" which belongs to the class B.
    #
    # By using an invocation system you ensure that a command is invoked only once.
    # In the example above, invoking "foo" will invoke "b:hello" just once, even
    # if it's invoked later by "bar" method.
    #
    # When class A invokes class B, all arguments used on A initialization are
    # supplied to B. This allows lazy parse of options. Let's suppose you have
    # some rspec commands:
    #
    #   class Rspec < Thor::Group
    #     class_option :mock_framework, :type => :string, :default => :rr
    #
    #     def invoke_mock_framework
    #       invoke "rspec:#{options[:mock_framework]}"
    #     end
    #   end
    #
    # As you noticed, it invokes the given mock framework, which might have its
    # own options:
    #
    #   class Rspec::RR < Thor::Group
    #     class_option :style, :type => :string, :default => :mock
    #   end
    #
    # Since it's not rspec concern to parse mock framework options, when RR
    # is invoked all options are parsed again, so RR can extract only the options
    # that it's going to use.
    #
    # If you want Rspec::RR to be initialized with its own set of options, you
    # have to do that explicitly:
    #
    #   invoke "rspec:rr", [], :style => :foo
    #
    # Besides giving an instance, you can also give a class to invoke:
    #
    #   invoke Rspec::RR, [], :style => :foo
    #
    def invoke(name = nil, *args)
      if name.nil?
        warn "[Thor] Calling invoke() without argument is deprecated. Please use invoke_all instead.\n#{caller.join("\n")}"
        return invoke_all
      end

      args.unshift(nil) if args.first.is_a?(Array) || args.first.nil?
      command, args, opts, config = args

      klass, command = _retrieve_class_and_command(name, command)
      raise "Missing Thor class for invoke #{name}" unless klass
      raise "Expected Thor class, got #{klass}" unless klass <= Thor::Base

      args, opts, config = _parse_initialization_options(args, opts, config)
      klass.__send__(:dispatch, command, args, opts, config) do |instance|
        instance.parent_options = options
      end
    end

    # Invoke the given command if the given args.
    def invoke_command(command, *args) #:nodoc:
      current = @_invocations[self.class]

      unless current.include?(command.name)
        current << command.name
        command.run(self, *args)
      end
    end
    alias_method :invoke_task, :invoke_command

    # Invoke all commands for the current instance.
    def invoke_all #:nodoc:
      self.class.all_commands.map { |_, command| invoke_command(command) }
    end

    # Invokes using shell padding.
    def invoke_with_padding(*args)
      with_padding { invoke(*args) }
    end

  protected

    # Configuration values that are shared between invocations.
    def _shared_configuration #:nodoc:
      {:invocations => @_invocations}
    end

    # This method simply retrieves the class and command to be invoked.
    # If the name is nil or the given name is a command in the current class,
    # use the given name and return self as class. Otherwise, call
    # prepare_for_invocation in the current class.
    def _retrieve_class_and_command(name, sent_command = nil) #:nodoc:
      if name.nil?
        [self.class, nil]
      elsif self.class.all_commands[name.to_s]
        [self.class, name.to_s]
      else
        klass, command = self.class.prepare_for_invocation(nil, name)
        [klass, command || sent_command]
      end
    end
    alias_method :_retrieve_class_and_task, :_retrieve_class_and_command

    # Initialize klass using values stored in the @_initializer.
    def _parse_initialization_options(args, opts, config) #:nodoc:
      stored_args, stored_opts, stored_config = @_initializer

      args ||= stored_args.dup
      opts ||= stored_opts.dup

      config ||= {}
      config = stored_config.merge(_shared_configuration).merge!(config)

      [args, opts, config]
    end
  end
end

class Thor
  class Argument #:nodoc:
    VALID_TYPES = [:numeric, :hash, :array, :string]

    attr_reader :name, :description, :enum, :required, :type, :default, :banner
    alias_method :human_name, :name

    def initialize(name, options = {})
      class_name = self.class.to_s.split("::").last

      type = options[:type]

      raise ArgumentError, "#{class_name} name can't be nil."                         if name.nil?
      raise ArgumentError, "Type :#{type} is not valid for #{class_name.downcase}s."  if type && !valid_type?(type)

      @name        = name.to_s
      @description = options[:desc]
      @required    = options.key?(:required) ? options[:required] : true
      @type        = (type || :string).to_sym
      @default     = options[:default]
      @banner      = options[:banner] || default_banner
      @enum        = options[:enum]

      validate! # Trigger specific validations
    end

    def usage
      required? ? banner : "[#{banner}]"
    end

    def required?
      required
    end

    def show_default?
      case default
      when Array, String, Hash
        !default.empty?
      else
        default
      end
    end

  protected

    def validate!
      raise ArgumentError, "An argument cannot be required and have default value." if required? && !default.nil?
      raise ArgumentError, "An argument cannot have an enum other than an array." if @enum && !@enum.is_a?(Array)
    end

    def valid_type?(type)
      self.class::VALID_TYPES.include?(type.to_sym)
    end

    def default_banner
      case type
      when :boolean
        nil
      when :string, :default
        human_name.upcase
      when :numeric
        "N"
      when :hash
        "key:value"
      when :array
        "one two three"
      end
    end
  end
end

class Thor
  class Arguments #:nodoc: # rubocop:disable ClassLength
    NUMERIC = /[-+]?(\d*\.\d+|\d+)/

    # Receives an array of args and returns two arrays, one with arguments
    # and one with switches.
    #
    def self.split(args)
      arguments = []

      args.each do |item|
        #break if item =~ /^-/
        arguments << item
      end

      [arguments, args[Range.new(arguments.size, -1)]]
    end

    def self.parse(*args)
      to_parse = args.pop
      new(*args).parse(to_parse)
    end

    # Takes an array of Thor::Argument objects.
    #
    def initialize(arguments = [])
      @assigns = {}
      @non_assigned_required = []
      @switches = arguments

      arguments.each do |argument|
        if !argument.default.nil?
          @assigns[argument.human_name] = argument.default
        elsif argument.required?
          @non_assigned_required << argument
        end
      end
    end

    def parse(args)
      @pile = args.dup

      @switches.each do |argument|
        break unless peek
        @non_assigned_required.delete(argument)
        @assigns[argument.human_name] = send(:"parse_#{argument.type}", argument.human_name)
      end

      check_requirement!
      @assigns
    end

    def remaining
      @pile
    end

  private

    def no_or_skip?(arg)
      arg =~ /^--(no|skip)-([-\w]+)$/
      $2
    end

    def last?
      @pile.empty?
    end

    def peek
      @pile.first
    end

    def shift
      @pile.shift
    end

    def unshift(arg)
      if arg.is_a?(Array)
        @pile = arg + @pile
      else
        @pile.unshift(arg)
      end
    end

    def current_is_value?
      peek && peek.to_s !~ /^-/
    end

    # Runs through the argument array getting strings that contains ":" and
    # mark it as a hash:
    #
    #   [ "name:string", "age:integer" ]
    #
    # Becomes:
    #
    #   { "name" => "string", "age" => "integer" }
    #
    def parse_hash(name)
      return shift if peek.is_a?(Hash)
      hash = {}

      while current_is_value? && peek.include?(":")
        key, value = shift.split(":", 2)
        raise MalformattedArgumentError, "You can't specify '#{key}' more than once in option '#{name}'; got #{key}:#{hash[key]} and #{key}:#{value}" if hash.include? key
        hash[key] = value
      end
      hash
    end

    # Runs through the argument array getting all strings until no string is
    # found or a switch is found.
    #
    #   ["a", "b", "c"]
    #
    # And returns it as an array:
    #
    #   ["a", "b", "c"]
    #
    def parse_array(name)
      return shift if peek.is_a?(Array)
      array = []
      array << shift while current_is_value?
      array
    end

    # Check if the peek is numeric format and return a Float or Integer.
    # Check if the peek is included in enum if enum is provided.
    # Otherwise raises an error.
    #
    def parse_numeric(name)
      return shift if peek.is_a?(Numeric)

      unless peek =~ NUMERIC && $& == peek
        raise MalformattedArgumentError, "Expected numeric value for '#{name}'; got #{peek.inspect}"
      end

      value = $&.index(".") ? shift.to_f : shift.to_i
      if @switches.is_a?(Hash) && switch = @switches[name]
        if switch.enum && !switch.enum.include?(value)
          raise MalformattedArgumentError, "Expected '#{name}' to be one of #{switch.enum.join(', ')}; got #{value}"
        end
      end
      value
    end

    # Parse string:
    # for --string-arg, just return the current value in the pile
    # for --no-string-arg, nil
    # Check if the peek is included in enum if enum is provided. Otherwise raises an error.
    #
    def parse_string(name)
      if no_or_skip?(name)
        nil
      else
        value = shift
        if @switches.is_a?(Hash) && switch = @switches[name]
          if switch.enum && !switch.enum.include?(value)
            raise MalformattedArgumentError, "Expected '#{name}' to be one of #{switch.enum.join(', ')}; got #{value}"
          end
        end
        value
      end
    end

    # Raises an error if @non_assigned_required array is not empty.
    #
    def check_requirement!
      return if @non_assigned_required.empty?
      names = @non_assigned_required.map do |o|
        o.respond_to?(:switch_name) ? o.switch_name : o.human_name
      end.join("', '")
      class_name = self.class.to_s.split("::").last.downcase
      raise RequiredArgumentMissingError, "No value provided for required #{class_name} '#{names}'"
    end
  end
end

class Thor
  module Sandbox #:nodoc:
  end

  # This module holds several utilities:
  #
  # 1) Methods to convert thor namespaces to constants and vice-versa.
  #
  #   Thor::Util.namespace_from_thor_class(Foo::Bar::Baz) #=> "foo:bar:baz"
  #
  # 2) Loading thor files and sandboxing:
  #
  #   Thor::Util.load_thorfile("~/.thor/foo")
  #
  module Util
    class << self
      # Receives a namespace and search for it in the Thor::Base subclasses.
      #
      # ==== Parameters
      # namespace<String>:: The namespace to search for.
      #
      def find_by_namespace(namespace)
        namespace = "default#{namespace}" if namespace.empty? || namespace =~ /^:/
        Thor::Base.subclasses.detect { |klass| klass.namespace == namespace }
      end

      # Receives a constant and converts it to a Thor namespace. Since Thor
      # commands can be added to a sandbox, this method is also responsible for
      # removing the sandbox namespace.
      #
      # This method should not be used in general because it's used to deal with
      # older versions of Thor. On current versions, if you need to get the
      # namespace from a class, just call namespace on it.
      #
      # ==== Parameters
      # constant<Object>:: The constant to be converted to the thor path.
      #
      # ==== Returns
      # String:: If we receive Foo::Bar::Baz it returns "foo:bar:baz"
      #
      def namespace_from_thor_class(constant)
        constant = constant.to_s.gsub(/^Thor::Sandbox::/, "")
        constant = snake_case(constant).squeeze(":")
        constant
      end

      # Given the contents, evaluate it inside the sandbox and returns the
      # namespaces defined in the sandbox.
      #
      # ==== Parameters
      # contents<String>
      #
      # ==== Returns
      # Array[Object]
      #
      def namespaces_in_content(contents, file = __FILE__)
        old_constants = Thor::Base.subclasses.dup
        Thor::Base.subclasses.clear

        load_thorfile(file, contents)

        new_constants = Thor::Base.subclasses.dup
        Thor::Base.subclasses.replace(old_constants)

        new_constants.map!(&:namespace)
        new_constants.compact!
        new_constants
      end

      # Returns the thor classes declared inside the given class.
      #
      def thor_classes_in(klass)
        stringfied_constants = klass.constants.map { |kc|
          #(&:to_s)
          kc.to_s
        }

        Thor::Base.subclasses.select do |subclass|
          #TODO!!!!!!!!!!!
          #raise "#{Thor::Base.subclasses}"
          #next unless subclass.name
          #stringfied_constants.include?(subclass.name.gsub("#{klass.name}::", ""))
          subclass
        end
      end

      # Receives a string and convert it to snake case. SnakeCase returns snake_case.
      #
      # ==== Parameters
      # String
      #
      # ==== Returns
      # String
      #
      def snake_case(str)
        return str.downcase if str =~ /^[A-Z_]+$/
        str.gsub(/\B[A-Z]/, '_\&').squeeze("_") =~ /_*(.*)/
        $+.downcase
      end

      # Receives a string and convert it to camel case. camel_case returns CamelCase.
      #
      # ==== Parameters
      # String
      #
      # ==== Returns
      # String
      #
      def camel_case(str)
        return str if str !~ /_/ && str =~ /[A-Z]+.*/
        str.split("_").map(&:capitalize).join
      end

      # Receives a namespace and tries to retrieve a Thor or Thor::Group class
      # from it. It first searches for a class using the all the given namespace,
      # if it's not found, removes the highest entry and searches for the class
      # again. If found, returns the highest entry as the class name.
      #
      # ==== Examples
      #
      #   class Foo::Bar < Thor
      #     def baz
      #     end
      #   end
      #
      #   class Baz::Foo < Thor::Group
      #   end
      #
      #   Thor::Util.namespace_to_thor_class("foo:bar")     #=> Foo::Bar, nil # will invoke default command
      #   Thor::Util.namespace_to_thor_class("baz:foo")     #=> Baz::Foo, nil
      #   Thor::Util.namespace_to_thor_class("foo:bar:baz") #=> Foo::Bar, "baz"
      #
      # ==== Parameters
      # namespace<String>
      #
      def find_class_and_command_by_namespace(namespace, fallback = true)
        if namespace.include?(":") # look for a namespaced command
          pieces  = namespace.split(":")
          command = pieces.pop
          klass   = Thor::Util.find_by_namespace(pieces.join(":"))
        end
        unless klass # look for a Thor::Group with the right name
          klass = Thor::Util.find_by_namespace(namespace)
          command = nil
        end
        if !klass && fallback # try a command in the default namespace
          command = namespace
          klass   = Thor::Util.find_by_namespace("")
        end
        [klass, command]
      end
      alias_method :find_class_and_task_by_namespace, :find_class_and_command_by_namespace

      # Receives a path and load the thor file in the path. The file is evaluated
      # inside the sandbox to avoid namespacing conflicts.
      #
      def load_thorfile(path, content = nil, debug = false)
        content ||= File.binread(path)

        begin
          Thor::Sandbox.class_eval(content, path)
        rescue StandardError => e
          $stderr.puts("WARNING: unable to load thorfile #{path.inspect}: #{e.message}")
          if debug
            $stderr.puts(*e.backtrace)
          else
            $stderr.puts(e.backtrace.first)
          end
        end
      end

      def user_home
        @@user_home ||= if ENV["HOME"]
          ENV["HOME"]
        elsif ENV["USERPROFILE"]
          ENV["USERPROFILE"]
        elsif ENV["HOMEDRIVE"] && ENV["HOMEPATH"]
          File.join(ENV["HOMEDRIVE"], ENV["HOMEPATH"])
        elsif ENV["APPDATA"]
          ENV["APPDATA"]
        else
          begin
            File.expand_path("~")
          rescue
            if File::ALT_SEPARATOR
              "C:/"
            else
              "/"
            end
          end
        end
      end

      # Returns the root where thor files are located, depending on the OS.
      #
      def thor_root
        File.join(user_home, ".thor").tr('\\', "/")
      end

      # Returns the files in the thor root. On Windows thor_root will be something
      # like this:
      #
      #   C:\Documents and Settings\james\.thor
      #
      # If we don't #gsub the \ character, Dir.glob will fail.
      #
      def thor_root_glob
        files = Dir["#{escape_globs(thor_root)}/*"]

        files.map! do |file|
          File.directory?(file) ? File.join(file, "main.thor") : file
        end
      end

      # Where to look for Thor files.
      #
      def globs_for(path)
        path = escape_globs(path)
        ["#{path}/Thorfile", "#{path}/*.thor", "#{path}/tasks/*.thor", "#{path}/lib/tasks/*.thor"]
      end

      # Return the path to the ruby interpreter taking into account multiple
      # installations and windows extensions.
      #
      def ruby_command
        @ruby_command ||= begin
          "ruby"
          #ruby_name = "ruby" #RbConfig::CONFIG["ruby_install_name"]
          #ruby = File.join(RbConfig::CONFIG["bindir"], ruby_name)
          #ruby << RbConfig::CONFIG["EXEEXT"]

          ## avoid using different name than ruby (on platforms supporting links)
          #if ruby_name != "ruby" && File.respond_to?(:readlink)
          #  begin
          #    alternate_ruby = File.join(RbConfig::CONFIG["bindir"], "ruby")
          #    alternate_ruby << RbConfig::CONFIG["EXEEXT"]

          #    # ruby is a symlink
          #    if File.symlink? alternate_ruby
          #      linked_ruby = File.readlink alternate_ruby

          #      # symlink points to 'ruby_install_name'
          #      ruby = alternate_ruby if linked_ruby == ruby_name || linked_ruby == ruby
          #    end
          #  rescue NotImplementedError # rubocop:disable HandleExceptions
          #    # just ignore on windows
          #  end
          #end

          ## escape string in case path to ruby executable contain spaces.
          #ruby.sub!(/.*\s.*/m, '"\&"')
          #ruby
        end
      end

      # Returns a string that has had any glob characters escaped.
      # The glob characters are `* ? { } [ ]`.
      #
      # ==== Examples
      #
      #   Thor::Util.escape_globs('[apps]')   # => '\[apps\]'
      #
      # ==== Parameters
      # String
      #
      # ==== Returns
      # String
      #
      def escape_globs(path)
        path.to_s.gsub(/[*?{}\[\]]/, '\\\\\\&')
      end
    end
  end
end

class Thor
  module Shell
    class Basic
      DEFAULT_TERMINAL_WIDTH = 80

      attr_accessor :base
      attr_reader   :padding

      # Initialize base, mute and padding to nil.
      #
      def initialize #:nodoc:
        @base = nil
        @mute = false
        @padding = 0
        @always_force = false
      end

      # Mute everything that's inside given block
      #
      def mute
        @mute = true
        yield
      ensure
        @mute = false
      end

      # Check if base is muted
      #
      def mute?
        @mute
      end

      # Sets the output padding, not allowing less than zero values.
      #
      def padding=(value)
        @padding = [0, value].max
      end

      # Sets the output padding while executing a block and resets it.
      #
      def indent(count = 1)
        orig_padding = padding
        self.padding = padding + count
        yield
        self.padding = orig_padding
      end

      # Asks something to the user and receives a response.
      #
      # If a default value is specified it will be presented to the user
      # and allows them to select that value with an empty response. This
      # option is ignored when limited answers are supplied.
      #
      # If asked to limit the correct responses, you can pass in an
      # array of acceptable answers.  If one of those is not supplied,
      # they will be shown a message stating that one of those answers
      # must be given and re-asked the question.
      #
      # If asking for sensitive information, the :echo option can be set
      # to false to mask user input from $stdin.
      #
      # If the required input is a path, then set the path option to
      # true. This will enable tab completion for file paths relative
      # to the current working directory on systems that support
      # Readline.
      #
      # ==== Example
      # ask("What is your name?")
      #
      # ask("What is the planet furthest from the sun?", :default => "Pluto")
      #
      # ask("What is your favorite Neopolitan flavor?", :limited_to => ["strawberry", "chocolate", "vanilla"])
      #
      # ask("What is your password?", :echo => false)
      #
      # ask("Where should the file be saved?", :path => true)
      #
      def ask(statement, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        color = args.first

        if options[:limited_to]
          ask_filtered(statement, color, options)
        else
          ask_simply(statement, color, options)
        end
      end

      # Say (print) something to the user. If the sentence ends with a whitespace
      # or tab character, a new line is not appended (print + flush). Otherwise
      # are passed straight to puts (behavior got from Highline).
      #
      # ==== Example
      # say("I know you knew that.")
      #
      def say(message = "", color = nil, force_new_line = (message.to_s !~ /( |\t)\Z/))
        buffer = prepare_message(message, *color)
        buffer += "\n" if force_new_line && !message.to_s.end_with?("\n")

        stdout.print(buffer)
        stdout.flush
      end

      # Say a status with the given color and appends the message. Since this
      # method is used frequently by actions, it allows nil or false to be given
      # in log_status, avoiding the message from being shown. If a Symbol is
      # given in log_status, it's used as the color.
      #
      def say_status(status, message, log_status = true)
        return if quiet? || log_status == false
        spaces = "  " * (padding + 1)
        color  = log_status.is_a?(Symbol) ? log_status : :green

        status = status.to_s.rjust(12)
        status = set_color status, color, true if color

        buffer = "#{status}#{spaces}#{message}"
        buffer = "#{buffer}\n" unless buffer.end_with?("\n")

        stdout.print(buffer)
        stdout.flush
      end

      # Make a question the to user and returns true if the user replies "y" or
      # "yes".
      #
      def yes?(statement, color = nil)
        !!(ask(statement, color, :add_to_history => false) =~ is?(:yes))
      end

      # Make a question the to user and returns true if the user replies "n" or
      # "no".
      #
      def no?(statement, color = nil)
        !!(ask(statement, color, :add_to_history => false) =~ is?(:no))
      end

      # Prints values in columns
      #
      # ==== Parameters
      # Array[String, String, ...]
      #
      def print_in_columns(array)
        return if array.empty?
        colwidth = (array.map { |el| el.to_s.size }.max || 0) + 2
        array.each_with_index do |value, index|
          # Don't output trailing spaces when printing the last column
          if ((((index + 1) % (terminal_width / colwidth))).zero? && !index.zero?) || index + 1 == array.length
            stdout.puts value
          else
            stdout.printf("%-#{colwidth}s", value)
          end
        end
      end

      # Prints a table.
      #
      # ==== Parameters
      # Array[Array[String, String, ...]]
      #
      # ==== Options
      # indent<Integer>:: Indent the first column by indent value.
      # colwidth<Integer>:: Force the first column to colwidth spaces wide.
      #
      def print_table(array, options = {}) # rubocop:disable MethodLength
        return if array.empty?

        formats = []
        indent = options[:indent].to_i
        colwidth = options[:colwidth]
        options[:truncate] = terminal_width if options[:truncate] == true

        formats << "%-#{colwidth + 2}s".dup if colwidth
        start = colwidth ? 1 : 0

        colcount = array.max { |a, b| a.size <=> b.size }.size

        maximas = []

        start.upto(colcount - 1) do |index|
          maxima = array.map { |row| row[index] ? row[index].to_s.size : 0 }.max
          maximas << maxima
          formats << if index == colcount - 1
                       # Don't output 2 trailing spaces when printing the last column
                       "%-s".dup
                     else
                       "%-#{maxima + 2}s".dup
                     end
        end

        formats[0] = formats[0].insert(0, " " * indent)
        formats << "%s"

        array.each do |row|
          sentence = "".dup

          row.each_with_index do |column, index|
            maxima = maximas[index]

            f = if column.is_a?(Numeric)
              if index == row.size - 1
                # Don't output 2 trailing spaces when printing the last column
                "%#{maxima}s"
              else
                "%#{maxima}s  "
              end
            else
              formats[index]
            end
            sentence << f % column.to_s
          end

          sentence = truncate(sentence, options[:truncate]) if options[:truncate]
          stdout.puts sentence
        end
      end

      # Prints a long string, word-wrapping the text to the current width of the
      # terminal display. Ideal for printing heredocs.
      #
      # ==== Parameters
      # String
      #
      # ==== Options
      # indent<Integer>:: Indent each line of the printed paragraph by indent value.
      #
      def print_wrapped(message, options = {})
        indent = options[:indent] || 0
        width = terminal_width - indent
        paras = message.split("\n\n")

        paras.map! do |unwrapped|
          unwrapped.strip.tr("\n", " ").squeeze(" ").gsub(/.{1,#{width}}(?:\s|\Z)/) { ($& + 5.chr).gsub(/\n\005/, "\n").gsub(/\005/, "\n") }
        end

        paras.each do |para|
          para.split("\n").each do |line|
            stdout.puts line.insert(0, " " * indent)
          end
          stdout.puts unless para == paras.last
        end
      end

      # Deals with file collision and returns true if the file should be
      # overwritten and false otherwise. If a block is given, it uses the block
      # response as the content for the diff.
      #
      # ==== Parameters
      # destination<String>:: the destination file to solve conflicts
      # block<Proc>:: an optional block that returns the value to be used in diff and merge
      #
      def file_collision(destination)
        return true if @always_force
        options = block_given? ? "[Ynaqdhm]" : "[Ynaqh]"

        loop do
          answer = ask(
            %[Overwrite #{destination}? (enter "h" for help) #{options}],
            :add_to_history => false
          )

          case answer
          when nil
            say ""
            return true
          when is?(:yes), is?(:force), ""
            return true
          when is?(:no), is?(:skip)
            return false
          when is?(:always)
            return @always_force = true
          when is?(:quit)
            say "Aborting..."
            raise SystemExit
          when is?(:diff)
            show_diff(destination, yield) if block_given?
            say "Retrying..."
          when is?(:merge)
            if block_given? && !merge_tool.empty?
              merge(destination, yield)
              return nil
            end

            say "Please specify merge tool to `THOR_MERGE` env."
          else
            say file_collision_help
          end
        end
      end

      # This code was copied from Rake, available under MIT-LICENSE
      # Copyright (c) 2003, 2004 Jim Weirich
      def terminal_width
        result = if ENV["THOR_COLUMNS"]
          ENV["THOR_COLUMNS"].to_i
        else
          unix? ? dynamic_width : DEFAULT_TERMINAL_WIDTH
        end
        result < 10 ? DEFAULT_TERMINAL_WIDTH : result
      rescue
        DEFAULT_TERMINAL_WIDTH
      end

      # Called if something goes wrong during the execution. This is used by Thor
      # internally and should not be used inside your scripts. If something went
      # wrong, you can always raise an exception. If you raise a Thor::Error, it
      # will be rescued and wrapped in the method below.
      #
      def error(statement)
        stderr.puts statement
      end

      # Apply color to the given string with optional bold. Disabled in the
      # Thor::Shell::Basic class.
      #
      def set_color(string, *) #:nodoc:
        string
      end

    protected

      def prepare_message(message, *color)
        spaces = "  " * padding
        spaces + set_color(message.to_s, *color)
      end

      def can_display_colors?
        false
      end

      def lookup_color(color)
        return color unless color.is_a?(Symbol)
        self.class.const_get(color.to_s.upcase)
      end

      def stdout
        $stdout
      end

      def stderr
        $stderr
      end

      def is?(value) #:nodoc:
        value = value.to_s

        if value.size == 1
          /\A#{value}\z/i
        else
          /\A(#{value}|#{value[0, 1]})\z/i
        end
      end

      def file_collision_help #:nodoc:
        <<-HELP
        Y - yes, overwrite
        n - no, do not overwrite
        a - all, overwrite this and all others
        q - quit, abort
        d - diff, show the differences between the old and the new
        h - help, show this help
        m - merge, run merge tool
        HELP
      end

      def show_diff(destination, content) #:nodoc:
        diff_cmd = ENV["THOR_DIFF"] || ENV["RAILS_DIFF"] || "diff -u"

        require "tempfile"
        Tempfile.open(File.basename(destination), File.dirname(destination)) do |temp|
          temp.write content
          temp.rewind
          system %(#{diff_cmd} "#{destination}" "#{temp.path}")
        end
      end

      def quiet? #:nodoc:
        mute? || (base && base.options[:quiet])
      end

      # Calculate the dynamic width of the terminal
      def dynamic_width
        @dynamic_width ||= (dynamic_width_stty.nonzero? || dynamic_width_tput)
      end

      def dynamic_width_stty
        `stty size 2>/dev/null`.split[1].to_i
      end

      def dynamic_width_tput
        `tput cols 2>/dev/null`.to_i
      end

      def unix?
        RUBY_PLATFORM =~ /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
      end

      def truncate(string, width)
        as_unicode do
          chars = string.chars.to_a
          if chars.length <= width
            chars.join
          else
            chars[0, width - 3].join + "..."
          end
        end
      end

      if "".respond_to?(:encode)
        def as_unicode
          yield
        end
      else
        def as_unicode
          old = $KCODE
          $KCODE = "U"
          yield
        ensure
          $KCODE = old
        end
      end

      def ask_simply(statement, color, options)
        default = options[:default]
        message = [statement, ("(#{default})" if default), nil].uniq.join(" ")
        message = prepare_message(message, *color)
        result = Thor::LineEditor.readline(message, options)

        return unless result

        result = result.strip

        if default && result == ""
          default
        else
          result
        end
      end

      def ask_filtered(statement, color, options)
        answer_set = options[:limited_to]
        correct_answer = nil
        until correct_answer
          answers = answer_set.join(", ")
          answer = ask_simply("#{statement} [#{answers}]", color, options)
          correct_answer = answer_set.include?(answer) ? answer : nil
          say("Your response must be one of: [#{answers}]. Please try again.") unless correct_answer
        end
        correct_answer
      end

      def merge(destination, content) #:nodoc:
        require "tempfile"
        Tempfile.open([File.basename(destination), File.extname(destination)], File.dirname(destination)) do |temp|
          temp.write content
          temp.rewind
          system %(#{merge_tool} "#{temp.path}" "#{destination}")
        end
      end

      def merge_tool #:nodoc:
        @merge_tool ||= ENV["THOR_MERGE"] || git_merge_tool
      end

      def git_merge_tool #:nodoc:
        `git config merge.tool`.rstrip rescue ""
      end
    end
  end
end

class Thor
  module Base
    class << self
      attr_writer :shell

      # Returns the shell used in all Thor classes. If you are in a Unix platform
      # it will use a colored log, otherwise it will use a basic one without color.
      #
      def shell
        #@shell ||= if ENV["THOR_SHELL"] && !ENV["THOR_SHELL"].empty?
        #  Thor::Shell.const_get(ENV["THOR_SHELL"])
        #elsif RbConfig::CONFIG["host_os"] =~ /mswin|mingw/ && !ENV["ANSICON"]
          Thor::Shell::Basic
        #else
        #  Thor::Shell::Color
        #end
      end
    end
  end

  module Shell
    SHELL_DELEGATED_METHODS = [:ask, :error, :set_color, :yes?, :no?, :say, :say_status, :print_in_columns, :print_table, :print_wrapped, :file_collision, :terminal_width]
    attr_writer :shell

    #autoload :Basic, "thor/shell/basic"
    #autoload :Color, "thor/shell/color"
    #autoload :HTML,  "thor/shell/html"

    # Add shell to initialize config values.
    #
    # ==== Configuration
    # shell<Object>:: An instance of the shell to be used.
    #
    # ==== Examples
    #
    #   class MyScript < Thor
    #     argument :first, :type => :numeric
    #   end
    #
    #   MyScript.new [1.0], { :foo => :bar }, :shell => Thor::Shell::Basic.new
    #
    def initialize(args = [], options = {}, config = {})
      super
      self.shell = config[:shell]
      shell.base ||= self if shell.respond_to?(:base)
    end

    # Holds the shell for the given Thor instance. If no shell is given,
    # it gets a default shell from Thor::Base.shell.
    def shell
      @shell ||= Thor::Base.shell.new
    end

    # Common methods that are delegated to the shell.
    SHELL_DELEGATED_METHODS.each do |method|
      #TODO
      #, __FILE__, __LINE__
        #def #{method}(*args,&block)
        #  shell.#{method}(*args,&block)
        #end
      #module_eval <<-METHOD
      #METHOD
    end

    # Yields the given block with padding.
    def with_padding
      shell.padding += 1
      yield
    ensure
      shell.padding -= 1
    end

  protected

    # Allow shell to be shared between invocations.
    #
    def _shared_configuration #:nodoc:
      #super.merge!(:shell => shell)
      foo = super
      foo[:shell] = shell
      foo
    end
  end
end


class Thor
  class Option < Argument #:nodoc:
    attr_reader :aliases, :group, :lazy_default, :hide

    VALID_TYPES = [:boolean, :numeric, :hash, :array, :string]

    def initialize(name, options = {})
      @check_default_type = options[:check_default_type]
      options[:required] = false unless options.key?(:required)
      super
      @lazy_default = options[:lazy_default]
      @group        = options[:group].to_s.capitalize if options[:group]
      @aliases      = nil #TODO: Array.new(options[:aliases])
      @hide         = options[:hide]
    end

    # This parse quick options given as method_options. It makes several
    # assumptions, but you can be more specific using the option method.
    #
    #   parse :foo => "bar"
    #   #=> Option foo with default value bar
    #
    #   parse [:foo, :baz] => "bar"
    #   #=> Option foo with default value bar and alias :baz
    #
    #   parse :foo => :required
    #   #=> Required option foo without default value
    #
    #   parse :foo => 2
    #   #=> Option foo with default value 2 and type numeric
    #
    #   parse :foo => :numeric
    #   #=> Option foo without default value and type numeric
    #
    #   parse :foo => true
    #   #=> Option foo with default value true and type boolean
    #
    # The valid types are :boolean, :numeric, :hash, :array and :string. If none
    # is given a default type is assumed. This default type accepts arguments as
    # string (--foo=value) or booleans (just --foo).
    #
    # By default all options are optional, unless :required is given.
    #
    def self.parse(key, value)
      if key.is_a?(Array)
        name, *aliases = key
      else
        name = key
        aliases = []
      end

      name    = name.to_s
      default = value

      type = case value
      when Symbol
        default = nil
        if VALID_TYPES.include?(value)
          value
        elsif required = (value == :required) # rubocop:disable AssignmentInCondition
          :string
        end
      when TrueClass, FalseClass
        :boolean
      when Numeric
        :numeric
      when Hash, Array, String
        value.class.to_s.downcase.to_sym
      end

      new(name.to_s, :required => required, :type => type, :default => default, :aliases => aliases)
    end

    def switch_name
      @switch_name ||= dasherized? ? name : dasherize(name)
    end

    def human_name
      @human_name ||= dasherized? ? undasherize(name) : name
    end

    def usage(padding = 0)
      sample = if banner && !banner.to_s.empty?
        "#{switch_name}=#{banner}".dup
      else
        switch_name
      end

      sample = "[#{sample}]".dup unless required?

      #TODO
      #if boolean?
      #  sample << ", [#{dasherize('no-' + human_name)}]" unless (name == "force") || name.start_with?("no-")
      #end

      if aliases.empty?
        (" " * padding) << sample
      else
        "#{aliases.join(', ')}, #{sample}"
      end
    end

    VALID_TYPES.each do |type|
      #, __FILE__, __LINE__ + 1
      #class_eval <<-RUBY
      #  def #{type}?
      #    self.type == #{type.inspect}
      #  end
      #RUBY
    end

  protected

    def validate!
      #raise ArgumentError, "An option cannot be boolean and required." if boolean? && required?
      validate_default_type! if @check_default_type
    end

    def validate_default_type!
      default_type = case @default
      when nil
        return
      when TrueClass, FalseClass
        required? ? :string : :boolean
      when Numeric
        :numeric
      when Symbol
        :string
      when Hash, Array, String
        @default.class.to_s.downcase.to_sym
      end

      raise ArgumentError, "Expected #{@type} default value for '#{switch_name}'; got #{@default.inspect} (#{default_type})" unless default_type == @type
    end

    def dasherized?
      name.index("-") == 0
    end

    def undasherize(str)
      str.sub(/^-{1,2}/, "")
    end

    def dasherize(str)
      (str.length > 1 ? "--" : "-") + str.tr("_", "-")
    end
  end
end

class Thor
  class Options < Arguments #:nodoc: # rubocop:disable ClassLength
    LONG_RE     = /^(--\w+(?:-\w+)*)$/
    SHORT_RE    = /^(-[a-z])$/i
    EQ_RE       = /^(--\w+(?:-\w+)*|-[a-z])=(.*)$/i
    SHORT_SQ_RE = /^-([a-z]{2,})$/i # Allow either -x -v or -xv style for single char args
    SHORT_NUM   = /^(-[a-z])#{NUMERIC}$/i
    OPTS_END    = "--".freeze

    # Receives a hash and makes it switches.
    def self.to_switches(options)
      options.map do |key, value|
        case value
        when true
          "--#{key}"
        when Array
          "--#{key} #{value.map(&:inspect).join(' ')}"
        when Hash
          "--#{key} #{value.map { |k, v| "#{k}:#{v}" }.join(' ')}"
        when nil, false
          nil
        else
          "--#{key} #{value.inspect}"
        end
      end.compact.join(" ")
    end

    # Takes a hash of Thor::Option and a hash with defaults.
    #
    # If +stop_on_unknown+ is true, #parse will stop as soon as it encounters
    # an unknown option or a regular argument.
    def initialize(hash_options = {}, defaults = {}, stop_on_unknown = false, disable_required_check = false)
      @stop_on_unknown = stop_on_unknown
      @disable_required_check = disable_required_check
      options = hash_options.values
      super(options)

      # Add defaults
      defaults.each do |key, value|
        @assigns[key.to_s] = value
        @non_assigned_required.delete(hash_options[key])
      end

      @shorts = {}
      @switches = {}
      @extra = []

      options.each do |option|
        @switches[option.switch_name] = option

        option.aliases.each do |short|
          name = short.to_s.sub(/^(?!\-)/, "-")
          @shorts[name] ||= option.switch_name
        end
      end
    end

    def remaining
      @extra
    end

    def peek
      return super unless @parsing_options

      result = super
      if result == OPTS_END
        shift
        @parsing_options = false
        super
      else
        result
      end
    end

    def parse(args) # rubocop:disable MethodLength
      @pile = args.dup
      @parsing_options = true

      while peek
        if parsing_options?
          match, is_switch = current_is_switch?
          shifted = shift

          if is_switch
            case shifted
            when SHORT_SQ_RE
              unshift($1.split("").map { |f| "-#{f}" })
              next
            when EQ_RE, SHORT_NUM
              unshift($2)
              switch = $1
            when LONG_RE, SHORT_RE
              switch = $1
            end

            switch = normalize_switch(switch)
            option = switch_option(switch)
            @assigns[option.human_name] = parse_peek(switch, option)
          elsif @stop_on_unknown
            @parsing_options = false
            @extra << shifted
            @extra << shift while peek
            break
          elsif match
            @extra << shifted
            @extra << shift while peek && peek !~ /^-/
          else
            @extra << shifted
          end
        else
          @extra << shift
        end
      end

      check_requirement! unless @disable_required_check

      assigns = Thor::CoreExt::HashWithIndifferentAccess.new(@assigns)
      assigns.freeze
      assigns
    end

    def check_unknown!
      # an unknown option starts with - or -- and has no more --'s afterward.
      unknown = [] #TODO @extra.select { |str| str =~ /^--?(?:(?!--).)*$/ }
      raise UnknownArgumentError, "Unknown switches '#{unknown.join(', ')}'" unless unknown.empty?
    end

  protected

    # Check if the current value in peek is a registered switch.
    #
    # Two booleans are returned.  The first is true if the current value
    # starts with a hyphen; the second is true if it is a registered switch.
    def current_is_switch?
      case peek
      when LONG_RE, SHORT_RE, EQ_RE, SHORT_NUM
        [true, switch?($1)]
      when SHORT_SQ_RE
        [true, $1.split("").any? { |f| switch?("-#{f}") }]
      else
        [false, false]
      end
    end

    def current_is_switch_formatted?
      case peek
      when LONG_RE, SHORT_RE, EQ_RE, SHORT_NUM, SHORT_SQ_RE
        true
      else
        false
      end
    end

    def current_is_value?
      peek && (!parsing_options? || super)
    end

    def switch?(arg)
      switch_option(normalize_switch(arg))
    end

    def switch_option(arg)
      if match = no_or_skip?(arg) # rubocop:disable AssignmentInCondition
        @switches[arg] || @switches["--#{match}"]
      else
        @switches[arg]
      end
    end

    # Check if the given argument is actually a shortcut.
    #
    def normalize_switch(arg)
      (@shorts[arg] || arg).tr("_", "-")
    end

    def parsing_options?
      peek
      @parsing_options
    end

    # Parse boolean values which can be given as --foo=true, --foo or --no-foo.
    #
    def parse_boolean(switch)
      if current_is_value?
        if ["true", "TRUE", "t", "T", true].include?(peek)
          shift
          true
        elsif ["false", "FALSE", "f", "F", false].include?(peek)
          shift
          false
        else
          !no_or_skip?(switch)
        end
      else
        @switches.key?(switch) || !no_or_skip?(switch)
      end
    end

    # Parse the value at the peek analyzing if it requires an input or not.
    #
    def parse_peek(switch, option)
      if parsing_options? && (current_is_switch_formatted? || last?)
        if option.boolean?
          # No problem for boolean types
        elsif no_or_skip?(switch)
          return nil # User set value to nil
        elsif option.string? && !option.required?
          # Return the default if there is one, else the human name
          return option.lazy_default || option.default || option.human_name
        elsif option.lazy_default
          return option.lazy_default
        else
          raise MalformattedArgumentError, "No value provided for option '#{switch}'"
        end
      end

      @non_assigned_required.delete(option)
      send(:"parse_#{option.type}", switch)
    end
  end
end

class Thor
  #autoload :Actions,    "thor/actions"
  #autoload :RakeCompat, "thor/rake_compat"
  #autoload :Group,      "thor/group"

  # Shortcuts for help.
  HELP_MAPPINGS       = %w(-h -? --help -D)

  # Thor methods that should not be overwritten by the user.
  THOR_RESERVED_WORDS = %w(invoke shell options behavior root destination_root relative_root
                           action add_file create_file in_root inside run run_ruby_script)

  TEMPLATE_EXTNAME = ".tt"

  module Base
    attr_accessor :options, :parent_options, :args

    # It receives arguments in an Array and two hashes, one for options and
    # other for configuration.
    #
    # Notice that it does not check if all required arguments were supplied.
    # It should be done by the parser.
    #
    # ==== Parameters
    # args<Array[Object]>:: An array of objects. The objects are applied to their
    #                       respective accessors declared with <tt>argument</tt>.
    #
    # options<Hash>:: An options hash that will be available as self.options.
    #                 The hash given is converted to a hash with indifferent
    #                 access, magic predicates (options.skip?) and then frozen.
    #
    # config<Hash>:: Configuration for this Thor class.
    #
    def initialize(args = [], local_options = {}, config = {})
      parse_options = self.class.class_options

      # The start method splits inbound arguments at the first argument
      # that looks like an option (starts with - or --). It then calls
      # new, passing in the two halves of the arguments Array as the
      # first two parameters.

      command_options = config.delete(:command_options) # hook for start
      parse_options = parse_options.merge(command_options) if command_options
      if local_options.is_a?(Array)
        array_options = local_options
        hash_options = {}
      else
        # Handle the case where the class was explicitly instantiated
        # with pre-parsed options.
        array_options = []
        hash_options = local_options
      end

      # Let Thor::Options parse the options first, so it can remove
      # declared options from the array. This will leave us with
      # a list of arguments that weren't declared.
      stop_on_unknown = self.class.stop_on_unknown_option? config[:current_command]
      disable_required_check = self.class.disable_required_check? config[:current_command]
      opts = Thor::Options.new(parse_options, hash_options, stop_on_unknown, disable_required_check)
      self.options = opts.parse(array_options)
      self.options = config[:class_options].merge(options) if config[:class_options]

      # If unknown options are disallowed, make sure that none of the
      # remaining arguments looks like an option.
      opts.check_unknown! if self.class.check_unknown_options?(config)

      # Add the remaining arguments from the options parser to the
      # arguments passed in to initialize. Then remove any positional
      # arguments declared using #argument (this is primarily used
      # by Thor::Group). Tis will leave us with the remaining
      # positional arguments.
      to_parse  = args
      to_parse += opts.remaining unless self.class.strict_args_position?(config)

      thor_args = Thor::Arguments.new(self.class.arguments)
      thor_args.parse(to_parse).each { |k, v| __send__("#{k}=", v) }
      @args = thor_args.remaining
    end

    class << self
      def included(base) #:nodoc:
        base.extend ClassMethods
        base.__send__ :include, Invocation
        base.__send__ :include, Shell
      end

      # Returns the classes that inherits from Thor or Thor::Group.
      #
      # ==== Returns
      # Array[Class]
      #
      def subclasses
        @subclasses ||= []
      end

      # Returns the files where the subclasses are kept.
      #
      # ==== Returns
      # Hash[path<String> => Class]
      #
      def subclass_files
        @subclass_files ||= Hash.new { |h, k| h[k] = [] }
      end

      # Whenever a class inherits from Thor or Thor::Group, we should track the
      # class and the file on Thor::Base. This is the method responsible for it.
      #
      def register_klass_file(klass) #:nodoc:
        #TODO
        file = "Wkndrfile" #caller[1].match(/(.*):\d+/)[1]
        Thor::Base.subclasses << klass unless Thor::Base.subclasses.include?(klass)

        file_subclasses = Thor::Base.subclass_files[file] #File.expand_path(file)]
        file_subclasses << klass unless file_subclasses.include?(klass)
      end
    end

    module ClassMethods
      def attr_reader(*) #:nodoc:
        no_commands { super }
      end

      def attr_writer(*) #:nodoc:
        no_commands { super }
      end

      def attr_accessor(*) #:nodoc:
        no_commands { super }
      end

      # If you want to raise an error for unknown options, call check_unknown_options!
      # This is disabled by default to allow dynamic invocations.
      def check_unknown_options!
        @check_unknown_options = true
      end

      def check_unknown_options #:nodoc:
        @check_unknown_options ||= from_superclass(:check_unknown_options, false)
      end

      def check_unknown_options?(config) #:nodoc:
        !!check_unknown_options
      end

      # If you want to raise an error when the default value of an option does not match
      # the type call check_default_type!
      # This is disabled by default for compatibility.
      def check_default_type!
        @check_default_type = true
      end

      def check_default_type #:nodoc:
        @check_default_type ||= from_superclass(:check_default_type, false)
      end

      def check_default_type? #:nodoc:
        !!check_default_type
      end

      # If true, option parsing is suspended as soon as an unknown option or a
      # regular argument is encountered.  All remaining arguments are passed to
      # the command as regular arguments.
      def stop_on_unknown_option?(command_name) #:nodoc:
        false
      end

      # If true, option set will not suspend the execution of the command when
      # a required option is not provided.
      def disable_required_check?(command_name) #:nodoc:
        false
      end

      # If you want only strict string args (useful when cascading thor classes),
      # call strict_args_position! This is disabled by default to allow dynamic
      # invocations.
      def strict_args_position!
        @strict_args_position = true
      end

      def strict_args_position #:nodoc:
        @strict_args_position ||= from_superclass(:strict_args_position, false)
      end

      def strict_args_position?(config) #:nodoc:
        !!strict_args_position
      end

      # Adds an argument to the class and creates an attr_accessor for it.
      #
      # Arguments are different from options in several aspects. The first one
      # is how they are parsed from the command line, arguments are retrieved
      # from position:
      #
      #   thor command NAME
      #
      # Instead of:
      #
      #   thor command --name=NAME
      #
      # Besides, arguments are used inside your code as an accessor (self.argument),
      # while options are all kept in a hash (self.options).
      #
      # Finally, arguments cannot have type :default or :boolean but can be
      # optional (supplying :optional => :true or :required => false), although
      # you cannot have a required argument after a non-required argument. If you
      # try it, an error is raised.
      #
      # ==== Parameters
      # name<Symbol>:: The name of the argument.
      # options<Hash>:: Described below.
      #
      # ==== Options
      # :desc     - Description for the argument.
      # :required - If the argument is required or not.
      # :optional - If the argument is optional or not.
      # :type     - The type of the argument, can be :string, :hash, :array, :numeric.
      # :default  - Default value for this argument. It cannot be required and have default values.
      # :banner   - String to show on usage notes.
      #
      # ==== Errors
      # ArgumentError:: Raised if you supply a required argument after a non required one.
      #
      def argument(name, options = {})
        is_thor_reserved_word?(name, :argument)
        no_commands { attr_accessor name }

        required = if options.key?(:optional)
          !options[:optional]
        elsif options.key?(:required)
          options[:required]
        else
          options[:default].nil?
        end

        remove_argument name

        if required
          arguments.each do |argument|
            next if argument.required?
            raise ArgumentError, "You cannot have #{name.to_s.inspect} as required argument after " +
                                "the non-required argument #{argument.human_name.inspect}."
          end
        end

        options[:required] = required

        arguments << Thor::Argument.new(name, options)
      end

      # Returns this class arguments, looking up in the ancestors chain.
      #
      # ==== Returns
      # Array[Thor::Argument]
      #
      def arguments
        @arguments ||= from_superclass(:arguments, [])
      end

      # Adds a bunch of options to the set of class options.
      #
      #   class_options :foo => false, :bar => :required, :baz => :string
      #
      # If you prefer more detailed declaration, check class_option.
      #
      # ==== Parameters
      # Hash[Symbol => Object]
      #
      def class_options(options = nil)
        @class_options ||= from_superclass(:class_options, {})
        build_options(options, @class_options) if options
        @class_options
      end

      # Adds an option to the set of class options
      #
      # ==== Parameters
      # name<Symbol>:: The name of the argument.
      # options<Hash>:: Described below.
      #
      # ==== Options
      # :desc::     -- Description for the argument.
      # :required:: -- If the argument is required or not.
      # :default::  -- Default value for this argument.
      # :group::    -- The group for this options. Use by class options to output options in different levels.
      # :aliases::  -- Aliases for this option. <b>Note:</b> Thor follows a convention of one-dash-one-letter options. Thus aliases like "-something" wouldn't be parsed; use either "\--something" or "-s" instead.
      # :type::     -- The type of the argument, can be :string, :hash, :array, :numeric or :boolean.
      # :banner::   -- String to show on usage notes.
      # :hide::     -- If you want to hide this option from the help.
      #
      def class_option(name, options = {})
        build_option(name, options, class_options)
      end

      # Removes a previous defined argument. If :undefine is given, undefine
      # accessors as well.
      #
      # ==== Parameters
      # names<Array>:: Arguments to be removed
      #
      # ==== Examples
      #
      #   remove_argument :foo
      #   remove_argument :foo, :bar, :baz, :undefine => true
      #
      def remove_argument(*names)
        options = names.last.is_a?(Hash) ? names.pop : {}

        names.each do |name|
          arguments.delete_if { |a| a.name == name.to_s }
          undef_method name, "#{name}=" if options[:undefine]
        end
      end

      # Removes a previous defined class option.
      #
      # ==== Parameters
      # names<Array>:: Class options to be removed
      #
      # ==== Examples
      #
      #   remove_class_option :foo
      #   remove_class_option :foo, :bar, :baz
      #
      def remove_class_option(*names)
        names.each do |name|
          class_options.delete(name)
        end
      end

      # Defines the group. This is used when thor list is invoked so you can specify
      # that only commands from a pre-defined group will be shown. Defaults to standard.
      #
      # ==== Parameters
      # name<String|Symbol>
      #
      def group(name = nil)
        if name
          @group = name.to_s
        else
          @group ||= from_superclass(:group, "standard")
        end
      end

      # Returns the commands for this Thor class.
      #
      # ==== Returns
      # OrderedHash:: An ordered hash with commands names as keys and Thor::Command
      #               objects as values.
      #
      def commands
      #TODO
        @commands ||= Thor::CoreExt::OrderedHash.new
      end
      alias_method :tasks, :commands

      # Returns the commands for this Thor class and all subclasses.
      #
      # ==== Returns
      # OrderedHash:: An ordered hash with commands names as keys and Thor::Command
      #               objects as values.
      #
      def all_commands
        @all_commands ||= from_superclass(:all_commands, Thor::CoreExt::OrderedHash.new)
        #@all_commands.merge!(commands)
        commands.each do |k, v|
          @all_commands[k] = v
        end
      end
      alias_method :all_tasks, :all_commands

      # Removes a given command from this Thor class. This is usually done if you
      # are inheriting from another class and don't want it to be available
      # anymore.
      #
      # By default it only remove the mapping to the command. But you can supply
      # :undefine => true to undefine the method from the class as well.
      #
      # ==== Parameters
      # name<Symbol|String>:: The name of the command to be removed
      # options<Hash>:: You can give :undefine => true if you want commands the method
      #                 to be undefined from the class as well.
      #
      def remove_command(*names)
        options = names.last.is_a?(Hash) ? names.pop : {}

        names.each do |name|
          commands.delete(name.to_s)
          all_commands.delete(name.to_s)
          undef_method name if options[:undefine]
        end
      end
      alias_method :remove_task, :remove_command

      # All methods defined inside the given block are not added as commands.
      #
      # So you can do:
      #
      #   class MyScript < Thor
      #     no_commands do
      #       def this_is_not_a_command
      #       end
      #     end
      #   end
      #
      # You can also add the method and remove it from the command list:
      #
      #   class MyScript < Thor
      #     def this_is_not_a_command
      #     end
      #     remove_command :this_is_not_a_command
      #   end
      #
      def no_commands
        @no_commands = true
        yield
      ensure
        @no_commands = false
      end
      alias_method :no_tasks, :no_commands

      # Sets the namespace for the Thor or Thor::Group class. By default the
      # namespace is retrieved from the class name. If your Thor class is named
      # Scripts::MyScript, the help method, for example, will be called as:
      #
      #   thor scripts:my_script -h
      #
      # If you change the namespace:
      #
      #   namespace :my_scripts
      #
      # You change how your commands are invoked:
      #
      #   thor my_scripts -h
      #
      # Finally, if you change your namespace to default:
      #
      #   namespace :default
      #
      # Your commands can be invoked with a shortcut. Instead of:
      #
      #   thor :my_command
      #
      def namespace(name = nil)
        if name
          @namespace = name.to_s
        else
          @namespace ||= Thor::Util.namespace_from_thor_class(self)
        end
      end

      # Parses the command and options from the given args, instantiate the class
      # and invoke the command. This method is used when the arguments must be parsed
      # from an array. If you are inside Ruby and want to use a Thor class, you
      # can simply initialize it:
      #
      #   script = MyScript.new(args, options, config)
      #   script.invoke(:command, first_arg, second_arg, third_arg)
      #
      def start(given_args = ARGV, config = {})
        #TODO
        log!(:start_wtf, given_args, config)

        config[:shell] ||= Thor::Base.shell.new
        dispatch(nil, given_args.dup, nil, config)
      rescue Thor::Error => e
        config[:debug] || ENV["THOR_DEBUG"] == "1" ? (raise e) : config[:shell].error(e.message)
        exit(false) if exit_on_failure?
      #rescue Errno::EPIPE
      #  # This happens if a thor command is piped to something like `head`,
      #  # which closes the pipe when it's done reading. This will also
      #  # mean that if the pipe is closed, further unnecessary
      #  # computation will not occur.
      #  exit(true)
      end

      # Allows to use private methods from parent in child classes as commands.
      #
      # ==== Parameters
      #   names<Array>:: Method names to be used as commands
      #
      # ==== Examples
      #
      #   public_command :foo
      #   public_command :foo, :bar, :baz
      #
      def public_command(*names)
        names.each do |name|
          class_eval "def #{name}(*); super end"
        end
      end
      alias_method :public_task, :public_command

      def handle_no_command_error(command, has_namespace = $thor_runner) #:nodoc:
        raise UndefinedCommandError, "Could not find command #{command.inspect} in #{namespace.inspect} namespace." if has_namespace
        raise UndefinedCommandError, "Could not find command #{command.inspect}."
      end
      alias_method :handle_no_task_error, :handle_no_command_error

      def handle_argument_error(command, error, args, arity) #:nodoc:
        name = [command.ancestor_name, command.name].compact.join(" ")
        msg = "ERROR: \"#{basename} #{name}\" was called with ".dup
        msg << "no arguments"               if     args.empty?
        msg << "arguments " << args.inspect unless args.empty?
        msg << "\nUsage: #{banner(command).inspect}"
        raise InvocationError, msg
      end

    protected

      # Prints the class options per group. If an option does not belong to
      # any group, it's printed as Class option.
      #
      def class_options_help(shell, groups = {}) #:nodoc:
        # Group options by group
        class_options.each do |_, value|
          groups[value.group] ||= []
          groups[value.group] << value
        end

        # Deal with default group
        global_options = groups.delete(nil) || []
        print_options(shell, global_options)

        # Print all others
        groups.each do |group_name, options|
          print_options(shell, options, group_name)
        end
      end

      # Receives a set of options and print them.
      def print_options(shell, options, group_name = nil)
        return if options.empty?

        list = []
        padding = options.map { |o| o.aliases.size }.max.to_i * 4

        options.each do |option|
          next if option.hide
          item = [option.usage(padding)]
          item.push(option.description ? "# #{option.description}" : "")

          list << item
          list << ["", "# Default: #{option.default}"] if option.show_default?
          list << ["", "# Possible values: #{option.enum.join(', ')}"] if option.enum
        end

        shell.say(group_name ? "#{group_name} options:" : "Options:")
        shell.print_table(list, :indent => 2)
        shell.say ""
      end

      # Raises an error if the word given is a Thor reserved word.
      def is_thor_reserved_word?(word, type) #:nodoc:
        return false unless THOR_RESERVED_WORDS.include?(word.to_s)
        raise "#{word.inspect} is a Thor reserved word and cannot be defined as #{type}"
      end

      # Build an option and adds it to the given scope.
      #
      # ==== Parameters
      # name<Symbol>:: The name of the argument.
      # options<Hash>:: Described in both class_option and method_option.
      # scope<Hash>:: Options hash that is being built up
      def build_option(name, options, scope) #:nodoc:
        scope[name] = Thor::Option.new(name, options.merge(:check_default_type => check_default_type?))
      end

      # Receives a hash of options, parse them and add to the scope. This is a
      # fast way to set a bunch of options:
      #
      #   build_options :foo => true, :bar => :required, :baz => :string
      #
      # ==== Parameters
      # Hash[Symbol => Object]
      def build_options(options, scope) #:nodoc:
        options.each do |key, value|
          scope[key] = Thor::Option.parse(key, value)
        end
      end

      # Finds a command with the given name. If the command belongs to the current
      # class, just return it, otherwise dup it and add the fresh copy to the
      # current command hash.
      def find_and_refresh_command(name) #:nodoc:
        if commands[name.to_s]
          commands[name.to_s]
        elsif command = all_commands[name.to_s] # rubocop:disable AssignmentInCondition
          commands[name.to_s] = command.clone
        else
          raise ArgumentError, "You supplied :for => #{name.inspect}, but the command #{name.inspect} could not be found."
        end
      end
      alias_method :find_and_refresh_task, :find_and_refresh_command

      # Everytime someone inherits from a Thor class, register the klass
      # and file into baseclass.
      def inherited(klass)
        Thor::Base.register_klass_file(klass)
        klass.instance_variable_set(:@no_commands, false)
      end

      # Fire this callback whenever a method is added. Added methods are
      # tracked as commands by invoking the create_command method.
      def method_added(meth)
      #raise "fsdsd"
        meth = meth.to_s

        if meth == "initialize"
          initialize_added
          return
        end

        #TODO??????
        # Return if it's not a public instance method
        #return unless public_method_defined?(meth.to_sym)

        @no_commands ||= false
        return if @no_commands || !create_command(meth)

        is_thor_reserved_word?(meth, :command)
        Thor::Base.register_klass_file(self)
      end

      # Retrieves a value from superclass. If it reaches the baseclass,
      # returns default.
      def from_superclass(method, default = nil)
      #TODO
      #raise "fooooooo"
        if self == baseclass || !superclass.respond_to?(method, true)
          default
        else
          value = superclass.__send__(method)

          # Ruby implements `dup` on Object, but raises a `TypeError`
          # if the method is called on immediates. As a result, we
          # don't have a good way to check whether dup will succeed
          # without calling it and rescuing the TypeError.
          begin
            value.dup
          rescue TypeError
            value
          end

        end
      end

      # A flag that makes the process exit with status 1 if any error happens.
      def exit_on_failure?
        false
      end

      #
      # The basename of the program invoking the thor class.
      #
      def basename
        #TODO???????????????
        File.basename("Wkndrfile").split(" ").first
      end

      # SIGNATURE: Sets the baseclass. This is where the superclass lookup
      # finishes.
      def baseclass #:nodoc:
      end

      # SIGNATURE: Creates a new command if valid_command? is true. This method is
      # called when a new method is added to the class.
      def create_command(meth) #:nodoc:
      end
      alias_method :create_task, :create_command

      # SIGNATURE: Defines behavior when the initialize method is added to the
      # class.
      def initialize_added #:nodoc:
      end

      # SIGNATURE: The hook invoked by start.
      def dispatch(command, given_args, given_opts, config) #:nodoc:
        raise NotImplementedError
      end
    end
  end
end






class Thor
  class << self
    # Allows for custom "Command" package naming.
    #
    # === Parameters
    # name<String>
    # options<Hash>
    #
    def package_name(name, _ = {})
      @package_name = name.nil? || name == "" ? nil : name
    end

    # Sets the default command when thor is executed without an explicit command to be called.
    #
    # ==== Parameters
    # meth<Symbol>:: name of the default command
    #
    def default_command(meth = nil)
      if meth
        @default_command = meth == :none ? "help" : meth.to_s
      else
        @default_command ||= from_superclass(:default_command, "help")
      end
    end
    alias_method :default_task, :default_command

    # Registers another Thor subclass as a command.
    #
    # ==== Parameters
    # klass<Class>:: Thor subclass to register
    # command<String>:: Subcommand name to use
    # usage<String>:: Short usage for the subcommand
    # description<String>:: Description for the subcommand
    def register(klass, subcommand_name, usage, description, options = {})
      if klass <= Thor::Group
        desc usage, description, options
        define_method(subcommand_name) { |*args| invoke(klass, args) }
      else
        desc usage, description, options
        subcommand subcommand_name, klass
      end
    end

    # Defines the usage and the description of the next command.
    #
    # ==== Parameters
    # usage<String>
    # description<String>
    # options<String>
    #
    def desc(usage, description, options = {})
      if options[:for]
        command = find_and_refresh_command(options[:for])
        command.usage = usage             if usage
        command.description = description if description
      else
        @usage = usage
        @desc = description
        @hide = options[:hide] || false
      end
    end

    # Defines the long description of the next command.
    #
    # ==== Parameters
    # long description<String>
    #
    def long_desc(long_description, options = {})
      if options[:for]
        command = find_and_refresh_command(options[:for])
        command.long_description = long_description if long_description
      else
        @long_desc = long_description
      end
    end

    # Maps an input to a command. If you define:
    #
    #   map "-T" => "list"
    #
    # Running:
    #
    #   thor -T
    #
    # Will invoke the list command.
    #
    # ==== Parameters
    # Hash[String|Array => Symbol]:: Maps the string or the strings in the array to the given command.
    #
    def map(mappings = nil)
      @map ||= from_superclass(:map, {})

      if mappings
        mappings.each do |key, value|
          if key.respond_to?(:each)
            key.each { |subkey| @map[subkey] = value }
          else
            @map[key] = value
          end
        end
      end

      @map
    end

    # Declares the options for the next command to be declared.
    #
    # ==== Parameters
    # Hash[Symbol => Object]:: The hash key is the name of the option and the value
    # is the type of the option. Can be :string, :array, :hash, :boolean, :numeric
    # or :required (string). If you give a value, the type of the value is used.
    #
    def method_options(options = nil)
      @method_options ||= {}
      build_options(options, @method_options) if options
      @method_options
    end

    alias_method :options, :method_options

    # Adds an option to the set of method options. If :for is given as option,
    # it allows you to change the options from a previous defined command.
    #
    #   def previous_command
    #     # magic
    #   end
    #
    #   method_option :foo => :bar, :for => :previous_command
    #
    #   def next_command
    #     # magic
    #   end
    #
    # ==== Parameters
    # name<Symbol>:: The name of the argument.
    # options<Hash>:: Described below.
    #
    # ==== Options
    # :desc     - Description for the argument.
    # :required - If the argument is required or not.
    # :default  - Default value for this argument. It cannot be required and have default values.
    # :aliases  - Aliases for this option.
    # :type     - The type of the argument, can be :string, :hash, :array, :numeric or :boolean.
    # :banner   - String to show on usage notes.
    # :hide     - If you want to hide this option from the help.
    #
    def method_option(name, options = {})
      scope = if options[:for]
        find_and_refresh_command(options[:for]).options
      else
        method_options
      end

      build_option(name, options, scope)
    end
    alias_method :option, :method_option

    # Prints help information for the given command.
    #
    # ==== Parameters
    # shell<Thor::Shell>
    # command_name<String>
    #
    def command_help(shell, command_name)
      meth = normalize_command_name(command_name)
      command = all_commands[meth]
      handle_no_command_error(meth) unless command

      shell.say "Usage:"
      shell.say "  #{banner(command)}"
      shell.say
      class_options_help(shell, nil => command.options.values)
      if command.long_description
        shell.say "Description:"
        shell.print_wrapped(command.long_description, :indent => 2)
      else
        shell.say command.description
      end
    end
    alias_method :task_help, :command_help

    # Prints help information for this class.
    #
    # ==== Parameters
    # shell<Thor::Shell>
    #
    def help(shell, subcommand = false)
      list = printable_commands(true, subcommand)
      Thor::Util.thor_classes_in(self).each do |klass|
        list += klass.printable_commands(false)
      end
      list.sort! { |a, b| a[0] <=> b[0] }

      #TODO
      #if defined?(@package_name) && @package_name
      #  shell.say "#{@package_name} commands:"
      #else
        shell.say "Commands:"
      #end

      shell.print_table(list, :indent => 2, :truncate => true)
      shell.say
      class_options_help(shell)
    end

    # Returns commands ready to be printed.
    def printable_commands(all = true, subcommand = false)
      #raise "#{all_commands}"
      #TODO
      (all ? all_commands : commands).map do |_, command|
        next if command.hidden?
        item = []
        item << banner(command, false, subcommand)
        item << (command.description ? "# #{command.description.gsub(/\s+/m, ' ')}" : "")
        item
      end.compact
    end
    alias_method :printable_tasks, :printable_commands

    def subcommands
      @subcommands ||= from_superclass(:subcommands, [])
    end
    alias_method :subtasks, :subcommands

    def subcommand_classes
      @subcommand_classes ||= {}
    end

    def subcommand(subcommand, subcommand_class)
      subcommands << subcommand.to_s
      subcommand_class.subcommand_help subcommand
      subcommand_classes[subcommand.to_s] = subcommand_class

      define_method(subcommand) do |*args|
        args, opts = Thor::Arguments.split(args)
        invoke_args = [args, opts, {:invoked_via_subcommand => true, :class_options => options}]
        invoke_args.unshift "help" if opts.delete("--help") || opts.delete("-h")
        invoke subcommand_class, *invoke_args
      end
      subcommand_class.commands.each do |_meth, command|
        command.ancestor_name = subcommand
      end
    end
    alias_method :subtask, :subcommand

    # Extend check unknown options to accept a hash of conditions.
    #
    # === Parameters
    # options<Hash>: A hash containing :only and/or :except keys
    def check_unknown_options!(options = {})
      @check_unknown_options ||= {}
      options.each do |key, value|
        if value
          @check_unknown_options[key] = Array.new(value) #TODO: Array(value)
        else
          @check_unknown_options.delete(key)
        end
      end
      @check_unknown_options
    end

    # Overwrite check_unknown_options? to take subcommands and options into account.
    def check_unknown_options?(config) #:nodoc:
      options = check_unknown_options
      return false unless options

      command = config[:current_command]
      return true unless command

      name = command.name

      if subcommands.include?(name)
        false
      elsif options[:except]
        !options[:except].include?(name.to_sym)
      elsif options[:only]
        options[:only].include?(name.to_sym)
      else
        true
      end
    end

    # Stop parsing of options as soon as an unknown option or a regular
    # argument is encountered.  All remaining arguments are passed to the command.
    # This is useful if you have a command that can receive arbitrary additional
    # options, and where those additional options should not be handled by
    # Thor.
    #
    # ==== Example
    #
    # To better understand how this is useful, let's consider a command that calls
    # an external command.  A user may want to pass arbitrary options and
    # arguments to that command.  The command itself also accepts some options,
    # which should be handled by Thor.
    #
    #   class_option "verbose",  :type => :boolean
    #   stop_on_unknown_option! :exec
    #   check_unknown_options!  :except => :exec
    #
    #   desc "exec", "Run a shell command"
    #   def exec(*args)
    #     puts "diagnostic output" if options[:verbose]
    #     Kernel.exec(*args)
    #   end
    #
    # Here +exec+ can be called with +--verbose+ to get diagnostic output,
    # e.g.:
    #
    #   $ thor exec --verbose echo foo
    #   diagnostic output
    #   foo
    #
    # But if +--verbose+ is given after +echo+, it is passed to +echo+ instead:
    #
    #   $ thor exec echo --verbose foo
    #   --verbose foo
    #
    # ==== Parameters
    # Symbol ...:: A list of commands that should be affected.
    def stop_on_unknown_option!(*command_names)
      stop_on_unknown_option.merge(command_names)
    end

    def stop_on_unknown_option?(command) #:nodoc:
      command && stop_on_unknown_option.include?(command.name.to_sym)
    end

    # Disable the check for required options for the given commands.
    # This is useful if you have a command that does not need the required options
    # to work, like help.
    #
    # ==== Parameters
    # Symbol ...:: A list of commands that should be affected.
    def disable_required_check!(*command_names)
      disable_required_check.merge(command_names)
    end

    def disable_required_check?(command) #:nodoc:
      command && disable_required_check.include?(command.name.to_sym)
    end

  protected

    def stop_on_unknown_option #:nodoc:
      @stop_on_unknown_option ||= Set.new
    end

    # help command has the required check disabled by default.
    def disable_required_check #:nodoc:
      @disable_required_check ||= Set.new([:help])
    end

    # The method responsible for dispatching given the args.
    def dispatch(meth, given_args, given_opts, config) #:nodoc: # rubocop:disable MethodLength
      #TODO

      meth ||= retrieve_command_name(given_args)
      #log!(:all_commands, given_args, meth, retrieve_command_name(given_args), normalize_command_name(meth))
      command = all_commands[normalize_command_name(meth)]

      log!(:dispatch, meth, given_args, given_opts, command)

      if !command && config[:invoked_via_subcommand]
        # We're a subcommand and our first argument didn't match any of our
        # commands. So we put it back and call our default command.
        given_args.unshift(meth)
        command = all_commands[normalize_command_name(default_command)]
      end

      if command
        args, opts = Thor::Options.split(given_args)
        if stop_on_unknown_option?(command) && !args.empty?
          # given_args starts with a non-option, so we treat everything as
          # ordinary arguments
          args.concat opts
          opts.clear
        end
      else
        args = given_args
        opts = nil
        command = dynamic_command_class.new(meth)
      end

      opts = given_opts || opts || []
      config[:current_command] = command
      config[:command_options] = command.options

      instance = new(args, opts, config)
      yield instance if block_given?
      args = instance.args
      trailing = args[Range.new(arguments.size, -1)]
      instance.invoke_command(command, trailing || [])
    end

    # The banner for this class. You can customize it if you are invoking the
    # thor class by another ways which is not the Thor::Runner. It receives
    # the command that is going to be invoked and a boolean which indicates if
    # the namespace should be displayed as arguments.
    #
    def banner(command, namespace = nil, subcommand = false)
      "#{basename} #{command.formatted_usage(self, $thor_runner, subcommand)}"
    end

    def baseclass #:nodoc:
      Thor
    end

    def dynamic_command_class #:nodoc:
      Thor::DynamicCommand
    end

    def create_command(meth) #:nodoc:
      @usage ||= nil
      @desc ||= nil
      @long_desc ||= nil
      @hide ||= nil

      if @usage && @desc
        base_class = @hide ? Thor::HiddenCommand : Thor::Command
        commands[meth] = base_class.new(meth, @desc, @long_desc, @usage, method_options)
        @usage, @desc, @long_desc, @method_options, @hide = nil
        true
      elsif all_commands[meth] || meth == "method_missing"
        true
      else
        puts "[WARNING] Attempted to create command #{meth.inspect} without usage or description. " +
             "Call desc if you want this method to be available as command or declare it inside a " +
             "no_commands{} block. Invoked from #{caller[1].inspect}."
        false
      end
    end
    alias_method :create_task, :create_command

    def initialize_added #:nodoc:
      class_options.merge!(method_options)
      @method_options = nil
    end

    # Retrieve the command name from given args.
    def retrieve_command_name(args) #:nodoc:
      #meth = args.first.to_s unless args.empty?
      #args.shift if meth && (map[meth]) #TODO:  || !(meth ~= /^\-/))
      unless args.empty?
        meth = args.first
        #args.shift if meth && map[meth] || meth
        args.shift if meth && (map[meth] || !meth.include?("--"))
        meth
      end
    end
    alias_method :retrieve_task_name, :retrieve_command_name

    # receives a (possibly nil) command name and returns a name that is in
    # the commands hash. In addition to normalizing aliases, this logic
    # will determine if a shortened command is an unambiguous substring of
    # a command or alias.
    #
    # +normalize_command_name+ also converts names like +animal-prison+
    # into +animal_prison+.
    def normalize_command_name(meth) #:nodoc:
      return default_command.to_s.gsub("-", "_") unless meth

      possibilities = find_command_possibilities(meth)
      raise AmbiguousTaskError, "Ambiguous command #{meth} matches [#{possibilities.join(', ')}]" if possibilities.size > 1

      if possibilities.empty?
        meth ||= default_command
      elsif map[meth]
        meth = map[meth]
      else
        meth = possibilities.first
      end

      meth.to_s.gsub("-", "_") # treat foo-bar as foo_bar
    end
    alias_method :normalize_task_name, :normalize_command_name

    # this is the logic that takes the command name passed in by the user
    # and determines whether it is an unambiguous substrings of a command or
    # alias name.
    def find_command_possibilities(meth)
      len = meth.to_s.length
      possibilities = all_commands.merge(map).keys.select { |n| meth == n[0, len] }.sort
      unique_possibilities = possibilities.map { |k| map[k] || k }.uniq

      if possibilities.include?(meth)
        [meth]
      elsif unique_possibilities.size == 1
        unique_possibilities
      else
        possibilities
      end
    end
    alias_method :find_task_possibilities, :find_command_possibilities

    def subcommand_help(cmd)
      desc "help [COMMAND]", "Describe subcommands or one specific subcommand"
      class_eval "
        def help(command = nil, subcommand = true); super; end
"
    end
    alias_method :subtask_help, :subcommand_help
  end

  include Thor::Base
  ####

  #TODO!!!!!!!!!!!!
  #map HELP_MAPPINGS => :help

  desc "help [COMMAND]", "Describe available commands or one specific command"
  def help(command = nil, subcommand = false)
    if command
      if self.class.subcommands.include? command
        self.class.subcommand_classes[command].help(shell, true)
      else
        self.class.command_help(shell, command)
      end
    else
      self.class.help(shell, subcommand)
    end
  end
end

class Thor::Group
  class << self
    # The description for this Thor::Group. If none is provided, but a source root
    # exists, tries to find the USAGE one folder above it, otherwise searches
    # in the superclass.
    #
    # ==== Parameters
    # description<String>:: The description for this Thor::Group.
    #
    def desc(description = nil)
      if description
        @desc = description
      else
        @desc ||= from_superclass(:desc, nil)
      end
    end

    # Prints help information.
    #
    # ==== Options
    # short:: When true, shows only usage.
    #
    def help(shell)
      shell.say "Usage:"
      shell.say "  #{banner}\n"
      shell.say
      class_options_help(shell)
      shell.say desc if desc
    end

    # Stores invocations for this class merging with superclass values.
    #
    def invocations #:nodoc:
      @invocations ||= from_superclass(:invocations, {})
    end

    # Stores invocation blocks used on invoke_from_option.
    #
    def invocation_blocks #:nodoc:
      @invocation_blocks ||= from_superclass(:invocation_blocks, {})
    end

    # Invoke the given namespace or class given. It adds an instance
    # method that will invoke the klass and command. You can give a block to
    # configure how it will be invoked.
    #
    # The namespace/class given will have its options showed on the help
    # usage. Check invoke_from_option for more information.
    #
    def invoke(*names, &block)
      options = names.last.is_a?(Hash) ? names.pop : {}
      verbose = options.fetch(:verbose, true)

      names.each do |name|
        invocations[name] = false
        invocation_blocks[name] = block if block_given?

        class_eval <<-METHOD, __FILE__, __LINE__
          def _invoke_#{name.to_s.gsub(/\W/, '_')}
            klass, command = self.class.prepare_for_invocation(nil, #{name.inspect})
            if klass
              say_status :invoke, #{name.inspect}, #{verbose.inspect}
              block = self.class.invocation_blocks[#{name.inspect}]
              _invoke_for_class_method klass, command, &block
            else
              say_status :error, %(#{name.inspect} [not found]), :red
            end
          end
        METHOD
      end
    end

    # Invoke a thor class based on the value supplied by the user to the
    # given option named "name". A class option must be created before this
    # method is invoked for each name given.
    #
    # ==== Examples
    #
    #   class GemGenerator < Thor::Group
    #     class_option :test_framework, :type => :string
    #     invoke_from_option :test_framework
    #   end
    #
    # ==== Boolean options
    #
    # In some cases, you want to invoke a thor class if some option is true or
    # false. This is automatically handled by invoke_from_option. Then the
    # option name is used to invoke the generator.
    #
    # ==== Preparing for invocation
    #
    # In some cases you want to customize how a specified hook is going to be
    # invoked. You can do that by overwriting the class method
    # prepare_for_invocation. The class method must necessarily return a klass
    # and an optional command.
    #
    # ==== Custom invocations
    #
    # You can also supply a block to customize how the option is going to be
    # invoked. The block receives two parameters, an instance of the current
    # class and the klass to be invoked.
    #
    def invoke_from_option(*names, &block)
      options = names.last.is_a?(Hash) ? names.pop : {}
      verbose = options.fetch(:verbose, :white)

      names.each do |name|
        unless class_options.key?(name)
          raise ArgumentError, "You have to define the option #{name.inspect} " +
                              "before setting invoke_from_option."
        end

        invocations[name] = true
        invocation_blocks[name] = block if block_given?

        class_eval <<-METHOD, __FILE__, __LINE__
          def _invoke_from_option_#{name.to_s.gsub(/\W/, '_')}
            return unless options[#{name.inspect}]
            value = options[#{name.inspect}]
            value = #{name.inspect} if TrueClass === value
            klass, command = self.class.prepare_for_invocation(#{name.inspect}, value)
            if klass
              say_status :invoke, value, #{verbose.inspect}
              block = self.class.invocation_blocks[#{name.inspect}]
              _invoke_for_class_method klass, command, &block
            else
              say_status :error, %(\#{value} [not found]), :red
            end
          end
        METHOD
      end
    end

    # Remove a previously added invocation.
    #
    # ==== Examples
    #
    #   remove_invocation :test_framework
    #
    def remove_invocation(*names)
      names.each do |name|
        remove_command(name)
        remove_class_option(name)
        invocations.delete(name)
        invocation_blocks.delete(name)
      end
    end

    # Overwrite class options help to allow invoked generators options to be
    # shown recursively when invoking a generator.
    #
    def class_options_help(shell, groups = {}) #:nodoc:
      get_options_from_invocations(groups, class_options) do |klass|
        klass.__send__(:get_options_from_invocations, groups, class_options)
      end
      super(shell, groups)
    end

    # Get invocations array and merge options from invocations. Those
    # options are added to group_options hash. Options that already exists
    # in base_options are not added twice.
    #
    def get_options_from_invocations(group_options, base_options) #:nodoc: # rubocop:disable MethodLength
      invocations.each do |name, from_option|
        value = if from_option
          option = class_options[name]
          option.type == :boolean ? name : option.default
        else
          name
        end
        next unless value

        klass, _ = prepare_for_invocation(name, value)
        next unless klass && klass.respond_to?(:class_options)

        value = value.to_s
        human_name = value.respond_to?(:classify) ? value.classify : value

        group_options[human_name] ||= []
        group_options[human_name] += klass.class_options.values.select do |class_option|
          base_options[class_option.name.to_sym].nil? && class_option.group.nil? &&
            !group_options.values.flatten.any? { |i| i.name == class_option.name }
        end

        yield klass if block_given?
      end
    end

    # Returns commands ready to be printed.
    def printable_commands(*)
      item = []
      item << banner
      item << (desc ? "# #{desc.gsub(/\s+/m, ' ')}" : "")
      [item]
    end
    alias_method :printable_tasks, :printable_commands

    def handle_argument_error(command, error, _args, arity) #:nodoc:
      msg = "#{basename} #{command.name} takes #{arity} argument".dup
      msg << "s" if arity > 1
      msg << ", but it should not."
      raise error, msg
    end

  protected

    # The method responsible for dispatching given the args.
    def dispatch(command, given_args, given_opts, config) #:nodoc:
      if Thor::HELP_MAPPINGS.include?(given_args.first)
        help(config[:shell])
        return
      end

      args, opts = Thor::Options.split(given_args)
      opts = given_opts || opts

      instance = new(args, opts, config)
      yield instance if block_given?

      if command
        instance.invoke_command(all_commands[command])
      else
        instance.invoke_all
      end
    end

    # The banner for this class. You can customize it if you are invoking the
    # thor class by another ways which is not the Thor::Runner.
    def banner
      "#{basename} #{self_command.formatted_usage(self, false)}"
    end

    # Represents the whole class as a command.
    def self_command #:nodoc:
      Thor::DynamicCommand.new(namespace, class_options)
    end
    alias_method :self_task, :self_command

    def baseclass #:nodoc:
      Thor::Group
    end

    def create_command(meth) #:nodoc:
      commands[meth.to_s] = Thor::Command.new(meth, nil, nil, nil, nil)
      true
    end
    alias_method :create_task, :create_command
  end

  include Thor::Base

protected

  # Shortcut to invoke with padding and block handling. Use internally by
  # invoke and invoke_from_option class methods.
  def _invoke_for_class_method(klass, command = nil, *args, &block) #:nodoc:
    with_padding do
      if block
        case block.arity
        when 3
          yield(self, klass, command)
        when 2
          yield(self, klass)
        when 1
          instance_exec(klass, &block)
        end
      else
        invoke klass, command, *args
      end
    end
  end
end
