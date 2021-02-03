# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("#{__dir__}/.."))

module MRuby
  module IvBenchmark
    IMPLEMENTATIONS = %i[2.1.2 baseline new].freeze
    BUILD_MODES = %w[64-word 64-nan 64-no 32-word 32-no].freeze
  end
end
