MRuby::Gem::Specification.new("mruby-iv-benchmark") do |spec|
  spec.license = "MIT"
  spec.author  = "KOBAYASHI Shuji"
  spec.summary = "Instance variable table benchmark"
  spec.bins    = Dir.children("#{__dir__}/tools")
end
