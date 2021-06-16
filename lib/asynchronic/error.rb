module Asynchronic
  class Error

    attr_reader :message, :backtrace

    def initialize(source)
      @message = source.respond_to?(:message) ? source.message : source.to_s
      @backtrace = source.respond_to?(:backtrace) ? source.backtrace : []
    end

  end
end