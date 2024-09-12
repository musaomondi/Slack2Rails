# frozen_string_literal: true

class ApiRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :aza_api, reading: :aza_api }
end
