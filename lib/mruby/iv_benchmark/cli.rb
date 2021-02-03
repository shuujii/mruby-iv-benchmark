# frozen_string_literal: true

require 'optparse'
require_relative 'util'

module MRuby::IvBenchmark
  class Cli
    include Util

    class << self
      def banner(banner)
        @option_parser.banner = banner
      end

      def option(name, short_name=nil,
                 argument: nil, required: false, default: nil, desc:)
        @required_options << name if required
        @options[name] = default unless default == nil
        arg_desc = " #{(name.size < 9 ? name.to_s : name[0]).upcase}" if argument
        desc += " [#{argument * ','}]" if Array === argument
        parser_args = []
        parser_args << "-#{short_name}" if short_name
        parser_args << "--#{name}#{arg_desc}"
        parser_args << argument if argument
        parser_args << desc
        @option_parser.on(*parser_args) {|v| @options[name] = v}
      end

      def option_implementation
        option :impl, ?i, argument: IMPLEMENTATIONS, required: true,
          desc: "Target implementation."
      end

      def option_build_mode
        option :mode, ?m, argument: BUILD_MODES, required: true,
          desc: "Target build mode."
      end

      def inherited(klass)
        klass.instance_eval do
          @options = {}
          @required_options = []
          @option_parser = OptionParser.new(nil, 22, "  ")
          @option_parser.on_tail("-h", "--help", "Show this message.") do
            puts @option_parser
            exit true
          end
        end

        at_exit do
          klass.instance_eval do
            @option_parser.order!
            @required_options.each do |name|
              next if @options.include?(name)
              e = OptionParser::ParseError.new
              e.set_option("--#{name}", true).reason = "missing option"
              raise e
            end
          rescue OptionParser::ParseError => e
            puts e
            exit false
          end
          Dir.chdir Util.root
          klass.new.run
        end
      end
    end

    def options
      self.class.instance_variable_get(:@options)
    end

    re = /[1-9]\d*/
    OptionParser.accept(:PositiveInteger, /\A#{re}\z/o) do |s,|
      s.to_i
    end
    OptionParser.accept(:PositiveIntegers, /\A#{re}(?:,#{re})*\z/o) do |s,|
      s.split(",").map(&:to_i)
    end
  end
end
