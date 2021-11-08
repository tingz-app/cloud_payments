# frozen_string_literal: true
module CloudPayments
  module Namespaces
    class Token < Base
      def topup(attributes)
        response = request(:topup, attributes)
        byebug
        if response[:model][:pa_req]
          Secure3D.new(model)
        else
          Transaction.new(model)
        end
        Transaction.new(response[:model])
      end
    end
  end
end
