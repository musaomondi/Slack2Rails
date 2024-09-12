module Api
  class Sender::Business < ApiRecord
    self.table_name = 'senders'
    self.inheritance_column = :_type_disabled
  end
end

