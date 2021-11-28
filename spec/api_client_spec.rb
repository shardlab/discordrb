# frozen_string_literal: true

require 'discordrb'

describe Discordrb::API::Route do
  let(:major_param) { '123456789' }
  subject { Discordrb::API::Route[:GET, "/guilds/#{major_param}/channels", major_param] }

  it 'normalizes the HTTP verb' do
    expect(subject.verb).to eq(:get)
  end

  it 'formats a route key' do
    expect(subject.route_key).to eq('guilds_id_channels')
  end

  it 'formats a ratelimit key' do
    expect(subject.rate_limit_key).to eq("#{subject.verb}:#{subject.route_key}:#{major_param}")
  end
end
