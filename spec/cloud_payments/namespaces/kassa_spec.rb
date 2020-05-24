#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
require 'spec_helper'

describe CloudPayments::Namespaces::Kassa do
  subject{ described_class.new(CloudPayments.client) }

  describe '#receipt' do
    let(:attributes) do
      {
        inn: '7708806666',
        type: 'Income',
        customer_receipt:  {
          items: [
            {
              amount: '13350.00',
              label: 'Good Description',
              price: '13350.00',
              quantity: 1.0,
              vat: 0
            }
          ]
        }
      }
    end

    context do
      before{ attributes.delete(:inn) }
      specify{ expect{subject.receipt(attributes)}.to raise_error(described_class::InnNotProvided) }
    end

    context do
      before{ attributes.delete(:type) }
      specify{ expect{subject.receipt(attributes)}.to raise_error(described_class::TypeNotProvided) }
    end

    context do
      before{ attributes.delete(:customer_receipt) }
      specify{ expect{subject.receipt(attributes)}.to raise_error(described_class::CustomerReceiptNotProvided) }
    end
  end
end
