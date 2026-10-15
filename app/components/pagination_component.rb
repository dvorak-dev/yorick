# frozen_string_literal: true

class PaginationComponent < ViewComponent::Base
  include Pagy::Frontend

  def initialize(pagy:)
    super()
    @pagy = pagy
  end

  delegate :series, to: :@pagy

  def params_to_keep
    request.query_parameters.slice(:full_name, :content)
  end
end
