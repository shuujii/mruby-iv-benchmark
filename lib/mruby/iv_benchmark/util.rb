# frozen_string_literal: true

autoload :FileUtils, 'fileutils'
autoload :Open3, 'open3'
autoload :Pathname, 'pathname'
autoload :YAML, 'yaml'
require_relative '../iv_benchmark'

module MRuby::IvBenchmark
  autoload :SimpleErb, 'mruby/iv_benchmark/simple_erb'
  autoload :HtmlBuilder, 'mruby/iv_benchmark/html_builder'

  module Util
    BOXINGS = {"no" => "No", "nan" => "NaN", "word" => "Word"}

    class << self
      def config
        @config ||= (
          yaml = File.read("#{root}/config.yml")
          conf = YAML.load(yaml, symbolize_names: true)
          impl_attrs = conf.fetch(:implementations)
          impls = conf[:implementations] = {}
          IMPLEMENTATIONS.zip(impl_attrs){|impl, attrs| impls[impl] = attrs}
          conf.freeze
        )
      end

      def root; @root ||= File.expand_path("#{__dir__}/../../..").freeze end
      def src_root; @src_root ||= "#{root}/mruby".freeze end
      def report_root; @report_root ||= "#{root}/report".freeze end
      def data_root; @data_root ||= "#{report_root}/data".freeze end
      def page_root; @page_root ||= "#{report_root}/page".freeze end
      def doc_root; @doc_root ||= "#{root}/docs".freeze end
      def src_dir(impl) "#{src_root}/#{impl}" end
      def build_dir(impl, mode) "#{src_dir(impl)}/build/#{mode}" end
      def data_dir(name, impl=nil) path_join(data_root, name, impl) end
      def env_dir(name, impl=nil) data_dir("environment/#{name}", impl) end
      def path_join(*parts) parts.compact * "/" end
      def build_html(*args, &block) HtmlBuilder.build(*args, &block) end
      def from_root(path) Pathname.new(path).relative_path_from(root) end
      def mac?; RUBY_PLATFORM.include?('darwin') end

      def build_mode_text(mode)
        bit, boxing = mode.split("-")
        "#{bit}-bit #{BOXINGS[boxing]}-boxing"
      end

      def sha_path(impl)
        "#{src_root}/#{impl}.sha"
      end

      def local_sha(impl)
        return nil unless File.exist?(sha_path = sha_path(impl))
        File.read(sha_path).chomp
      end

      def github_location(user_project, revision)
        text = "github:#{user_project}@#{revision[0,7]}"
        url = "https://github.com/#{user_project}/tree/#{revision}"
        build_html{a(href: url){text}}
      end

      def write_file(path, content)
        log_name = File.exist?(path) ? "update" : "create"
        FileUtils.mkdir_p File.dirname(path)
        File.write(path, content)
        log log_name, from_root(path)
      end

      def ext(path, new_ext="")
        new_ext = ".#{new_ext}" if !new_ext.empty? && !new_ext.start_with?(".")
        path.sub(/\.[^.]+\z/, new_ext)
      end

      def ext?(path, ext)
        ext = ".#{ext}" unless ext.start_with?(".")
        File.extname(path) == ext
      end

      def log(name, msg)
        printf "  %8s: %s\n", name, msg
      end

      def compiler
        ENV['CC'] || (mac? ? 'clang' : 'gcc')
      end

      def task(rule, &block)
        raise ArgumentError, "rule error" unless rule.size == 1
        target, deps = rule.first
        if !File.exist?(target) ||
           Array(deps).any?{|dep| File.mtime(dep) - File.mtime(target) > 0.2}
          block.call
        end
      end

      def sh(*args)
        command_error($?, *args) unless system(*args)
      end

      def capture(*args)
        out, status = Open3.capture2(*args)
        command_error(status, *args) unless status.success?
        out
      end

      def command_error(status, *args)
        msg = "Command failed with status (#{status.exitstatus}): [#{args*' '}]"
        raise RuntimeError, msg, caller(1)
      end
    end

    module_eval methods(false).map {|m|
      "def #{m}(*args, **kws, &block) #{name}.#{m}(*args, **kws, &block) end"
    } * "\n"

    def erb(src_path, dst_path=nil, **kws, &block)
      result = SimpleErb.run(src_path, context: self, **kws, &block)
      write_file(dst_path, result) if dst_path
      result
    end
  end
end
