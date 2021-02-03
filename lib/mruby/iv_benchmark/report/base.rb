# frozen_string_literal: true

module MRuby::IvBenchmark
  autoload :Markdown, 'mruby/iv_benchmark/markdown'
  autoload :Tsv, 'mruby/iv_benchmark/tsv'

  class Report
    class Base
      include Util
    end
  end
end
