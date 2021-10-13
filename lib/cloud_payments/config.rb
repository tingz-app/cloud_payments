# frozen_string_literal: true
module CloudPayments
  class Config
    attr_accessor :connection_options, :serializer, :log, :public_key, :secret_key, :host, :raise_banking_errors,
                  :payout_public_key, :payout_secret_key
    attr_writer :logger

    DEFAULT_LOGGER = ->{
      require 'logger'
      logger = Logger.new(STDERR)
      logger.progname = 'cloud_payments'
      logger.formatter = ->(severity, datetime, progname, msg){ "#{datetime} (#{progname}): #{msg}\n" }
      logger
    }

    def initialize
      @log = false
      @serializer = Client::Serializer::MultiJson.new(self)
      @connection_options = {}
      @connection_block = nil
      @host = 'https://api.cloudpayments.ru'
      if block_given?
        yield self
      end
    end

    def logger
      @logger ||= log ? DEFAULT_LOGGER.call : nil
    end

    def available_currencies
      %w{RUB USD EUR}
    end

    def connection_block(&block)
      if block_given?
        @connection_block = block
      else
        @connection_block
      end
    end

    def dup
      clone = super
      clone.connection_options = connection_options.dup
      clone
    end
  end
end
