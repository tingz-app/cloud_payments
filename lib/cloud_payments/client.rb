# frozen_string_literal: true
require 'cloud_payments/client/errors'
require 'cloud_payments/client/gateway_errors'
require 'cloud_payments/client/response'
require 'cloud_payments/client/serializer'

module CloudPayments
  class Client
    include Namespaces

    attr_reader :config, :connection

    def initialize(config = nil)
      @config = config || CloudPayments.config
      @connection = build_connection
    end

    def perform_request(path, params = nil)
      request_headers = headers
      request_body = (params ? convert_to_json(params) : nil)
      byebug
      if path == 'payments/token/topup'
        body_sign = sign(request_body)
        request_headers = payout_headers(body_sign)
        connection.basic_auth(config.payout_public_key, config.payout_secret_key)
      else
        connection.basic_auth(config.public_key, config.secret_key)
      end

      response = connection.post(path, request_body, request_headers)

      Response.new(response.status, response.body, response.headers).tap do |response|
        raise_transport_error(response) if response.status.to_i >= 300
      end
    end

    private

    def convert_to_json(data)
      config.serializer.dump(data)
    end

    def headers
      { 'Content-Type' => 'application/json' }
    end

    def sign(request_body)
      key = Tempfile.new('key')
      key.write(config.payout_key)
      cert = Tempfile.new('cert')
      cert.write(config.payout_cert)
      sign = %x"openssl cms -sign -signer #{cert.path} -inkey #{key.path} -in #{request_body} -outform pem"
      key.close
      key.unlink
      cert.close
      cert.unlink
      sign
    end

    def payout_headers(sign)
      headers.merge("X-Signature" => sign)
    end

    def logger
      config.logger
    end

    def raise_transport_error(response)
      logger.fatal "[#{response.status}] #{response.origin_body}" if logger
      error = ERRORS[response.status] || ServerError
      raise error.new "[#{response.status}] #{response.origin_body}"
    end

    def build_connection
      Faraday::Connection.new(config.host, config.connection_options, &config.connection_block)
    end
  end
end
