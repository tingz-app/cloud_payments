# frozen_string_literal: true
module CloudPayments
  class EscrowPayout < Model
    property :transaction_ids, required: true

    def ids
      transaction_ids
    end

    def required_secure3d?
      true
    end
  end
end
