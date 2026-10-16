# frozen_string_literal: true

class PaginationComponent < ViewComponent::Base
  def initialize(pagy:)
    super()
    @pagy = pagy
  end

  def params_to_keep
    request.query_parameters.slice(:full_name, :content)
  end
end
