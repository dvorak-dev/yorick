class FuneralNoticesIndex < Chewy::Index
  # Fold accents and leave words whole. An exact full_name.keyword boost
  # is a later mapping change.
  settings analysis: {
    analyzer: {
      folded: {
        tokenizer: 'standard',
        filter: %w[lowercase asciifolding]
      }
    }
  }

  index_scope FuneralNotice

  field :id, type: :integer
  field :full_name, type: 'search_as_you_type', analyzer: 'folded'
  field :content, type: :text, analyzer: 'folded'
  field :published_on, type: :date
  field :created_at, type: :date
  field :updated_at, type: :date
end
