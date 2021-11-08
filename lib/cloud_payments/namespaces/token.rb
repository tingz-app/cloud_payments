# frozen_string_literal: true
module CloudPayments
  module Namespaces
    class Token < Base
      def topup(attributes)
        byebug
        response = request(:topup, attributes)
        if response[:model][:success]
          Transaction.new(response[:model])
        else
          EscrowPayout.new(response[:model][:success])
        end
      end
    end
  end
end
