# frozen_string_literal: true

autoload :JSON, 'json'
require_relative 'base'
require_relative 'chart_helper'

module MRuby::IvBenchmark
  autoload :HtmlUtil, 'mruby/iv_benchmark/html_util'

  class Report
    class Chart < Base
      include ChartHelper

      def run(options)
        write_js(options)
        BaseChart.classes.each {|c| c.new.run}
      end

    private

      def write_js(options)
        erb_path = "#{report_root}/js/chart.js.erb"
        js_path = "#{doc_root}/js/chart.js"
        helper_path = "#{__dir__}/chart_helper.rb"
        task js_path => [erb_path, helper_path, __FILE__] do
          js = erb(erb_path, tag: :js)
          js = capture("uglifyjs", stdin_data: js) if options[:minify]
          write_file(js_path, js)
        end
      end

      class BaseChart
        include Util

        class << self
          def inherited(sub) classes << sub end
          def classes; @@classes ||= [] end
          def category; @category ||= hyphenize(name.split("::")[4]).freeze end
          def feature; @feature ||= hyphenize(name.split("::")[5]).freeze end
          def key; @key ||= [category, feature].compact.join("-").freeze end
        private
          def hyphenize(str) str.gsub(/.\K[A-Z]/, '-\&').downcase if str end
        end

        def run
          BUILD_MODES.each{|mode| write_json(mode)}
          write_html
        end

        def legend_html(b)
          b.div(".legend") do
            b.div(".legend-header"){"iv_tbl size: --"}
            b.div(".legend-body") do
              b.div(".legend-items") do
                IMPLEMENTATIONS.each do |impl|
                  legend_item_html(b, impl, impl.capitalize, unit)
                end
              end
              b.div(".legend-notes") do
                b.div{"Drag and drop to zoom in (double-click resets)"}
              end
            end
          end
        end

        #
        #   div(".legend-item.baseline")
        #     div(".legend-figure")
        #     div(".legend-label"){"Baseline:"}
        #     div(".legend-value"){"--"}
        #     div(".legend-unit"){"kB"}
        #
        def legend_item_html(b, key, label, unit=nil)
          b.div(".legend-item.#{HtmlUtil.class_for(key)}") do
            b.div(".legend-figure")
            b.div(".legend-label"){"#{label}:"}
            b.div(".legend-value"){"--"}
            b.div(".legend-unit"){unit}
          end
        end

        def unit; Chart::UNITS[category] end

        module_eval %w[category feature key].map {|name|
          "def #{name}; self.class.#{name} end"
        } * "\n"

      private

        def write_json(mode)
          tsv_paths = IMPLEMENTATIONS.map do |impl|
            return unless File.exist?(path = tsv_path(impl, mode))
            path
          end
          json_path = json_path(mode)
          task json_path => tsv_paths do
            iv_sizes = nil
            all_data = tsv_paths.map do |tsv_path|
              iv_sizes, data = read_tsv(tsv_path)
              data
            end
            write_file(json_path, JSON.generate([iv_sizes, *all_data]))
          end
        end

        def read_tsv(path)
          iv_sizes, ipses = [], []
          Tsv.each(path) do |iv_size, value, *|
            iv_sizes << iv_size.to_i
            ipses << value.to_f
          end
          [iv_sizes, ipses]
        end

        def write_html
          path = html_path
          task path => __FILE__ do
            html = build_html(self) do |c|
              #
              # div("#chart-performance-c-get.line-chart")
              #   div(".modes")
              #     div(".mode")
              #     ...
              #   div(".chart-item")
              #     div(".chart")
              #     div(".legent")
              #       ...
              #   ...
              #
              div("#chart-#{c.key}.line-chart") do
                div(".modes") do
                  BUILD_MODES.each do |mode|
                    div(".mode", "data-mode": mode){c.build_mode_text(mode)}
                  end
                end
                (c.feature == "c-set" ? 2 : 1).times do
                  div(".chart-item") do
                    div(".chart")
                    c.legend_html(self)
                  end
                end
              end
            end << "\n"
            write_file(path, html)
          end
        end

        def json_path(mode)
          path_join(doc_root, category, feature, "#{mode}.json")
        end

        def tsv_path(impl, mode)
          path_join(data_root, category, feature, impl, "#{mode}.tsv")
        end

        def html_path
          path_join(data_root, category, feature, "chart.html")
        end
      end

      class MemoryUsage < BaseChart; end

      module Performance
        FEATURES = %w[c-set c-get].each do |feature|
          const_set feature.gsub(/(?:^|-)(.)/){$1.upcase}, Class.new(BaseChart)
        end
      end
    end
  end
end
