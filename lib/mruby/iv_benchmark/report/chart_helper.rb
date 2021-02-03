# frozen_string_literal: true

module MRuby::IvBenchmark
  class Report
    module ChartHelper
      darken = ->((h, s, l), amount){[h, s, l - amount]}
      hsl = ->((h, s, l)){"hsl(#{h},#{s}%,#{l}%)"}
      hsls_to_colors = ->(hsls, colors) do
        hsls.each do |k, v|
          case v
          when Array; colors[k] = hsl.(v)
          else hsls_to_colors.(v, colors[k] ||= {})
          end
        end
        colors
      end

      hsls = {}
      IMPLEMENTATIONS.each do |impl|
        impl_hsls = hsls[impl] = {}
        figure = impl_hsls[:figure] = Util.config.dig(:implementations,impl,:hsl)
        impl_hsls[:text] = darken.(figure, 12)
      end
      COLORS = hsls_to_colors.(hsls, {})
      COLORS[:axis] = "#282828"
      COLORS[:bg] = "#fff"

      LINE_CHART_WIDTH = 550
      LINE_CHART_HEIGHT = 270
      UNITS = {"memory-usage" => "kB", "performance" => "M i/s"}
      X_LABEL = "iv_tbl size"
    end
  end
end
