# frozen_string_literal: true
module CloudPayments
  module Namespaces
    class Token < Base
      def topup(attributes)
        response = request(:topup, attributes)
        Transaction.new(response[:model])
      end
    end
  end
end
