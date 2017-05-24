require "capsicum/version"
require 'ffi'

module Capsicum
  class IntPtr < FFI::Struct
    layout :value, :int
  end

  module LibC
    extend FFI::Library
    ffi_lib [FFI::CURRENT_PROCESS, 'c']

    attach_variable :errno, :int

    attach_function :cap_enter, [], :int
    attach_function :cap_getmode, [IntPtr], :int
  end

  def sandboxed?
    ptr = IntPtr.new
    ret = LibC.cap_getmode(ptr)

    if ret == 0
      ptr[:value] == 1
    else
      raise SystemCallError.new("cap_getmode", LibC.errno)
    end
  end

  def enter!
    ret = LibC.cap_enter

    if ret == 0
      return true
    else
      raise SystemCallError.new("cap_enter", LibC.errno)
    end
  end

  def within_sandbox
    return enum_for(:within_sandbox) unless block_given?

    pid = fork do
      Capsicum.enter!
      yield
    end

    Process.waitpid2(pid).last
  end

  module_function :sandboxed?
  module_function :enter!
  module_function :within_sandbox
end
