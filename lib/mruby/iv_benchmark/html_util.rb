# frozen_string_literal: true

module MRuby::IvBenchmark
  module HtmlUtil
    class << self
      def class_for(obj)
        s = obj.to_s
        "#{'v' if /\A\d/.match?(s)}#{s.tr('^0-9a-zA-Z\-', '_')}"
      end

      def header_anchor(html)
        html.downcase.gsub(/ |<.*?>/){$& == " " ? "-" : ""}
      end

      def size_table(data_dir, key_name, impl)
        # [["64-no",
        #   [["void*", "8"],
        #    ["mrb_value", "16"],
        #    ["mrb_int", "8"]]],
        #  ["32-word",
        #   [["void*", "4"],
        #    ["mrb_value", "4"],
        #    ["mrb_int", "4"]]],
        # ...]
        data = []

        BUILD_MODES.each do |mode|
          path = "#{data_dir}/#{impl}/#{mode}.tsv"
          data << [mode, Tsv.read(path)] if File.exist?(path)
        end
        return "" if data.empty?

        Util.build_html do
          table do
            caption{impl.to_s.capitalize}
            thead do
              tr{th(rowspan: 2){key_name}.th(colspan: data.size){"Size (byte)"}}
              tr do
                data.each do |mode, _|
                  th!{Util.build_mode_text(mode).sub(" ", "<br>")}
                end
              end
            end
            tbody do
              data[0][1].size.times do |row|
                tr do
                  th{code{data[0][1][row][0]}}
                  data.each do |mode, sizes|
                    td(".right"){sizes[row][1].gsub(/\B(?=(.{3})+(?!.))/, ",")}
                  end
                end
              end
            end
          end
        end << "\n"
      end
    end
  end
end
