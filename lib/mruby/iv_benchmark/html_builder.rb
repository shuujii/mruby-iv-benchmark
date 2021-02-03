# frozen_string_literal: true

autoload :CGI, 'cgi/escape'

module MRuby::IvBenchmark
  class HtmlBuilder
    EMPTY_ELEMENTS = %i[
      area base br col embed hr img input link meta param source track wbr
    ].each_with_object({}){|el, h| h[el] = true}

    class << self
      def build(*args, &block)
        builder = new
        builder.instance_exec(*args, &block)
        builder.to_s
      end
    end

    def initialize(&block)
      @html = +""
      block&.(self)
    end

    def tag(name, id_and_class=nil, escape: true, **attrs, &block)
      name = name.to_s
      if id_and_class
        id_and_class.scan(/(\A|[#.])([^#.]+)/).each do |(prefix, value)|
          n = prefix == "#" ? "id" : "class"
          v = attrs[n]
          v ? (v << " " << value) : (attrs[n] = value)
        end
      end
      @html << "<" << name
      attrs.each{|k,v| @html<<' '<<k.to_s<<'="'<<h(v)<<'"'} unless attrs.empty?
      @html << ">"
      ret = block&.call
      @html << (escape ? h(ret) : ret) if String === ret
      @html << "</" << name << ">" unless EMPTY_ELEMENTS.include?(name.to_sym)
      self
    end

    def tag!(name, id_and_class=nil, **attrs, &block)
      tag(name, id_and_class, escape: false, **attrs, &block)
    end

    def doctype; @html << "<!DOCTYPE html>" end
    def link_css(href) link(rel: "stylesheet", href: href) end
    def h(obj) CGI.escapeHTML(obj.to_s) end
    def to_s; @html end

    def method_missing(name, *args, **kws, &block)
      super unless /\A(?<tag>\w+)(?<suffix>!)?\z/ =~ name
      self.class.class_eval <<-EOS,  __FILE__, __LINE__ + 1
        def #{name}(*args, **kws, &block)
          tag#{suffix}(:#{tag}, *args, **kws, &block)
        end
      EOS
      send("tag#{suffix}", tag, *args, **kws, &block)
    end
  end
end
