bit, boxing = ENV["MRUBY_IVBM_BUILD_MODE"].split("-")

MRuby::Lockfile.disable
MRuby::Build.new do |conf|
  conf.toolchain ENV["CC"].include?("clang") ? :clang : :gcc
  conf.gem core: "mruby-print"
  conf.gem core: "mruby-bin-mruby"
  conf.gem path: __dir__
  conf.cc do |cc|
    cc.flags << "-g0 -O3"
    cc.flags << "-m#{bit}"
    cc.defines << "MRB_#{boxing.upcase}_BOXING"
    cc.defines << "MRB_HEAP_PAGE_SIZE=200000"
    cc.defines << "MRB_METHOD_CACHE_SIZE=1000"
    cc.defines << "MRB_GC_FIXED_ARENA"
    cc.defines << "MRB_GC_ARENA_SIZE=2500"
    cc.defines << "MRB_FIXED_STATE_ATEXIT_STACK"
  end
  conf.linker.flags << "-m#{bit}"
end
