# frozen_string_literal: true

module MRuby::IvBenchmark
  class Tsv
    include Enumerable

    class << self
      def each(path, &block)
        return to_enum(__callee__, path) unless block
        new(path).each(&block)
      end

      def read(path)
        new(path).to_a
      end
    end

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def each(&block)
      return to_enum(__callee__) unless block
      File.foreach(@path) do |line|
        next if line.start_with?("#")
        line.chomp!
        block.(line.split("\t"))
      end
      self
    end
  end
end
