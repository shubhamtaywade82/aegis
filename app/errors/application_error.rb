# frozen_string_literal: true

class ApplicationError < StandardError
  attr_reader :code, :context

  def initialize(message = nil, code: nil, context: {})
    @code = code
    @context = context.freeze

    super(message || self.class.name)
  end
end
