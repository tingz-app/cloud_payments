# frozen_string_literal: true
require 'spec_helper'

describe CloudPayments do
  before do
    @old_config = CloudPayments.config
  end

  after do
    CloudPayments.config = @old_config
  end

  describe '#config=' do
    specify{ expect{ CloudPayments.config = 'config' }.to change{ CloudPayments.config }.to('config') }
  end

  describe '#config' do
    specify{ expect(CloudPayments.config).to be_instance_of(CloudPayments::Config) }
  end

  it 'supports global configuration' do
    CloudPayments.config.secret_key = "OLD_KEY"

    CloudPayments.configure do |c|
      c.secret_key = "NEW_KEY"
    end

    expect(CloudPayments.config.secret_key).to eq "NEW_KEY"
    expect(CloudPayments.client.config.secret_key).to eq "NEW_KEY"
  end

  it 'supports local configuration' do
    CloudPayments.config.secret_key = "OLD_KEY"

    config = CloudPayments::Config.new do |c|
      c.secret_key = "NEW_KEY"
    end
    client = CloudPayments::Client.new(config)
    webhooks = CloudPayments::Webhooks.new(config)

    expect(config.secret_key).to eq "NEW_KEY"
    expect(client.config.secret_key).to eq "NEW_KEY"
    expect(webhooks.config.secret_key).to eq "NEW_KEY"
  end
end
