# frozen_string_literal: true

class AdminRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :aza_admin, reading: :aza_admin }
end
