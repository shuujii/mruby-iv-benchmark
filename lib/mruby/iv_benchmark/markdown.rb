# frozen_string_literal: true

require 'redcarpet'
autoload :CGI, 'cgi/escape'

module MRuby::IvBenchmark
  autoload :HtmlUtil, 'mruby/iv_benchmark/html_util'

  class Markdown < Redcarpet::Render::HTML
    class << self
      def render(md)
        @renderer ||= Redcarpet::Markdown.new(new,
          fenced_code_blocks: true,
          no_intra_emphasis: true,
          space_after_headers: true,
          strikethrough: true,
          tables: true,
          underline: true,
        )
        @renderer.render(md)
      end
    end

    def header(html, level)
      id = %| id="#{HtmlUtil.header_anchor(html)}"| if level <= 4
      "\n<h#{level}#{id}>#{html}</h#{level}>\n"
    end

    # For ERB tag
    def double_emphasis(html)
      if html.start_with?("%") && html.end_with?("%")
        "**#{CGI.unescapeHTML(html)}**"
      else
        "<strong>#{html}</strong>"
      end
    end

    def paragraph(html)
      return html if html.start_with?("**%") && html.end_with?("%**")
      "\n<p>#{html}</p>\n"
    end
  end
end
