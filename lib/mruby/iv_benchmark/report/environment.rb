# frozen_string_literal: true

require 'set'
require_relative '../html_util'

module MRuby::IvBenchmark
  class Report
    class Environment < Base
      BOXINGS = {"no" => "No", "nan" => "NaN", "word" => "Word"}
      MAC_HARDWARE_KEYS = Set[
        "Processor Name",
        "Processor Speed",
        "Number of Processors",
        "Total Number of Cores",
        "L2 Cache (per Core)",
        "L3 Cache",
        "Memory",
      ]

      def run(options)
        write_implementation
        write_platform
        write_type_size
      end

    private

      def write_implementation
        tsv_path = env_dir("implementation.tsv")
        content = build_html do
          table{tbody{Tsv.read(tsv_path).each{|(k, v)| tr{th{k}.td!{v}}}}}
        end << "\n"
        write_file(ext(tsv_path, "html"), content)
      end

      def write_platform
        write_os
        File.exist?(env_dir("cpu.txt")) ? write_hardware_linux : write_hardware_mac
      end

      def write_os
        tsv_path = env_dir("os.tsv")
        write_file(ext(tsv_path, "html"), table(Tsv.read(tsv_path)))
      end

      def write_hardware_mac
        attrs = []
        File.foreach(env_dir("hardware.txt")) do |line|
          next unless /^\s*(?<key>[^:]+?)\s*:\s*(?<value>.*?)\n/ =~ line
          attrs << [key, value] if MAC_HARDWARE_KEYS.include?(key)
        end
        write_file(env_dir("hardware.html"), table(attrs))
      end

      def write_hardware_linux
        html = hardware_linux_cpu
        html << hardware_linux_memory
        write_file(env_dir("hardware.html"), html)
      end

      def hardware_linux_cpu
        processors = {}
        attrs = nil
        File.foreach(env_dir("cpu.txt")) do |line|
          next unless /^(?<key>[^:]+?)\s*:\s*(?<value>.*?)\n/ =~ line
          if key == "processor"
            attrs = processors["CPU #{value}"] = []
          else
            attrs << [key, value]
          end
        end
        processors.inject(+"") do |html, (caption, attrs)|
          html << table(attrs, caption: caption) << "\n"
        end
      end

      def hardware_linux_memory
        File.foreach(env_dir("memory.txt")) do |line|
          # only MemTotal
          /^(?<key>[^:]+?)\s*:\s*(?<value>.*?)\n/ =~ line
          return table([[key, value]], caption: "Memory") << "\n"
        end
      end

      def write_type_size
        IMPLEMENTATIONS.map do |impl|
          path = env_dir("type-size", "#{impl}.html")
          content = HtmlUtil.size_table(env_dir("type-size"), "Type", impl)
          write_file(path, content)
        end
      end

      def table(body, caption: nil)
        build_html do
          table do
            caption{caption} if caption
            tbody{body.each{|(k, v)| tr{th{k}.td{v}}}}
          end
        end << "\n"
      end
    end
  end
end
