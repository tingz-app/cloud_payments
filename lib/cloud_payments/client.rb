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

    def cleanup_sign(sign)
      cms_format = /(?<=-----BEGIN CMS-----)(.*)(?=-----END CMS-----)/
      sign.delete("\n").scan(cms_format)
    end

    def sign(request_body)
      byebug
      key = Tempfile.new('key')
      key.write(config.payout_key)
      cert = Tempfile.new('cert')
      cert.write(config.payout_cert)
      body = Tempfile.new('body')
      body.write(JSON.parse(request_body).as_json)
      key.close
      cert.close
      body.close
      sign = %x"openssl cms -sign -signer #{cert.path} -inkey #{key.path} -in #{body.path} -outform pem"
      key.unlink
      cert.unlink
      body.unlink
      cleanup_sign(sign)
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
