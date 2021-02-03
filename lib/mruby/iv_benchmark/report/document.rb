# frozen_string_literal: true

require_relative 'chart_helper'

module MRuby::IvBenchmark
  autoload :HtmlUtil, 'mruby/iv_benchmark/html_util'

  class Report
    class Document < Base
      include ChartHelper

      TITLE = "Instance Variable Table Benchmark for mruby"
      GITHUB_URL = "https://github.com/shuujii/mruby-iv-benchmark"

      def run(options)
        write_css(options)
        toc = Toc.create
        toc.each{|page| write_page(toc, page)}
      end

    private

      def write_css(options)
        erb_path = "#{report_root}/css/main.sass.erb"
        css_path = "#{doc_root}/css/main.css"
        task css_path => [erb_path, "#{__dir__}/chart_helper.rb"] do
          cmds = %W[sassc -a -s]
          cmds << "-t" << "compressed" if options[:minify]
          css = capture(*cmds, stdin_data: erb(erb_path))
          write_file(css_path, css)
        end
      end

      def write_page(toc, page)
        path = File.expand_path("#{doc_root}/#{page.url}/index.html")
        write_file(path, toc.to_html(page))
      end

      class Toc
        class << self
          include Util
          def create
            toc = prev = parent = nil
            Dir["#{page_root}/*.md{,.erb}"].sort!.each do |path|
              page = Page.new
              page.html_for!(path)
              if prev
                page.url = path.sub(%r@^.*/\d*-([^/]+)\.md(?:\.erb)?$@, '/\1')
                prev.next = page
              else
                page.url = "/"
                toc = Toc.new(page)
              end
              page.url_with_base = url_with_base(page.url)
              page.html.scan(%r@^<h(\d) .*?>(.*)</h\d>@) do |l, name|
                level = l.to_i
                if level == 2
                  page.name = name
                  page.level = level
                else
                  child = TocHeader.new(name)
                  child.level = level
                  if level == 3
                    page << child
                    parent = child
                  else
                    parent << child
                  end
                end
              end
              prev = page
            end
            toc
          end

          def url_with_base(url) "/mruby-iv-benchmark#{url}" end
        end

        def initialize(index_page)
          @root_page = index_page
        end


        def each(&block)
          page = @root_page
          while page
            block.(page)
            page = page.next
          end
        end

        def to_html(page)
          Util.build_html(self) do |toc|
            doctype
            html(lang: "ja") do
              head do
                meta(charset: "utf-8")
                title{TITLE}
                link_css(toc.url_with_base("/css/main.css"))
                if page.chart?
                  link_css(toc.url_with_base("/css/uPlot.min.css"))
                  script(src: toc.url_with_base("/js/uPlot.iife.min.js"))
#                  script(src: toc.url_with_base("/js/uPlot.iife.js"))
                  script(src: toc.url_with_base("/js/chart.js"))
                end
              end
              body do
                header do
                  h1{a(href: toc.url_with_base("/")){TITLE}}
                  div{a(href: GITHUB_URL){"GitHub"}}
                end
                nav("#toc") do
                  ul do
                    toc.each do |pg|
                      active = page.name == pg.name
                      href = active ? "##{pg.anchor}" : pg.url_with_base
                      li(active ? ".active" : "") do
                        a!(".h2", href: href){pg.name}
                        toc.children_to_html(
                          self, pg.children, pg.url_with_base, active)
                      end
                    end
                  end
                end
                article!("#content"){page.html}
              end
            end
          end << "\n"
        end

        def children_to_html(b, children, url_with_base, active)
          return if children.empty?
          b.ul do
            children.each do |child|
              b.li do
                href = "#{url_with_base unless active}##{child.anchor}"
                b.a!(".h#{child.level}", href: href){child.name}
                children_to_html(b, child.children, url_with_base, active)
              end
            end
          end
        end

        def url_with_base(url) self.class.url_with_base(url) end
      end

      class TocHeader
        attr_accessor :name, :level
        attr_reader :children
        def initialize(name=nil) @name = name end
        def children; @children ||= [] end
        def anchor; @anchor ||= HtmlUtil.header_anchor(@name) end
        def <<(header) children << header; self end
      end

      class Page < TocHeader
        include Util
        attr_accessor :url, :url_with_base, :html, :prev, :next
        def chart?; @name == "Memory Usage" || @name == "Performance" end
        def html_for!(md_path)
          html_path = md_path.sub(/\.md(\.erb)?\z/, '.html\1')
          task html_path => md_path do
            html = Markdown.render(File.read(md_path))
            write_file(html_path, html)
          end
          html ||= File.read(html_path)
          @html = ext?(html_path, "erb") ? erb(html_path, tag: :html) : html
        end
      end
    end
  end
end
