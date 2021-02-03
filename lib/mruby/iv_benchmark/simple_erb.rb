# frozen_string_literal: true

module MRuby::IvBenchmark
  module SimpleErb
    TAGS = {
      #       opening  closing  one-line
      erb: %w[<%       %>       %],
      c:   %w[/*%      %*/      //%],
      md:  %w[**%      %**      #%],

    }
    TAGS[:js] = TAGS[:c]
    TAGS[:html] = TAGS[:md]

    class << self
      #
      # Supported tags are <%, <%-, <%=, <%#, %, %> and -%>
      #
      def run(src_path, tag: :erb, context: Object.new, locals: nil)
        tag_o, tag_c, tag_1, regexp = tags = TAGS.fetch(tag)
        unless regexp
          re_o, re_c, re_1 = [tag_o, tag_c, tag_1].map{|t| Regexp.escape(t)}
          regexp = /
            (?:^[\x20\t]*?#{re_o}(-)|#{re_o}([=#]?)) (.*?) (-?#{re_c}) |
            (?:^#{re_1}() (.*?(?:\r?\n|\z)))
          /mx
          tags << regexp
        end
        terms = File.read(src_path).split(regexp)
        code = +"proc{|out__,locals__| "
        locals&.each_key{|k|k = k.to_s; code << k << "=locals__[:" << k << "]; "}
        is_tag = rm_nl = false
        while term = terms.shift
          next rm_nl = term[-tag_c.size-1] == "-" if term.end_with?(tag_c)
          if is_tag
            case term
            when "",  "-"; code << "; " << terms.shift
            when "="; code << "; out__<<(" << terms.shift << ").to_s"
            when "#"; code << ("\n" * terms.shift.count("\n"))
            end
          elsif !term.empty?
            text = rm_nl && term.start_with?("\n") ? term[1..-1] : term
            code << "; out__<<" << text.dump << ("\n" * term.count("\n"))
          end
          is_tag = !is_tag
        end
        code << "; out__}.('',locals)"
        context.instance_eval(code, src_path)
      end
    end
  end
end
