# frozen_string_literal: true

require 'discordrb'

describe Discordrb::API do
  describe '.uri_with_query' do
    it 'requires a String as uri_string' do
      expect { Discordrb::API.uri_with_query(5,      nil) }.to raise_error URI::InvalidURIError, 'bad URI(is not URI?): 5'
      expect { Discordrb::API.uri_with_query(:test,  nil) }.to raise_error URI::InvalidURIError, 'bad URI(is not URI?): :test'
      expect(Discordrb::API.uri_with_query('path', nil)).to eq 'path'
    end

    it 'does not transform uri_string if no or nil-valued query parameters are provided' do
      [
        nil,
        {},
        { test: nil }
      ].each do |query|
        expect(Discordrb::API.uri_with_query('path',                          query)).to eq 'path'
        expect(Discordrb::API.uri_with_query('/path',                         query)).to eq '/path'
        expect(Discordrb::API.uri_with_query('/path?',                        query)).to eq '/path?'
        expect(Discordrb::API.uri_with_query('/path?asdf',                    query)).to eq '/path?asdf'
        expect(Discordrb::API.uri_with_query('https://discord.com/path?asdf', query)).to eq 'https://discord.com/path?asdf'
      end
    end

    it 'appends serialized query parameters to uri_string' do
      expect(Discordrb::API.uri_with_query('path',                          { test:  123 })).to eq 'path?test=123'
      expect(Discordrb::API.uri_with_query('/path',                         { test:  123 })).to eq '/path?test=123'
      expect(Discordrb::API.uri_with_query('/path?',                        { test:  123 })).to eq '/path?test=123'
      expect(Discordrb::API.uri_with_query('/path?asdf',                    { test:  123 })).to eq '/path?asdf&test=123'
      expect(Discordrb::API.uri_with_query('https://discord.com/path?asdf', { test:  123 })).to eq 'https://discord.com/path?asdf&test=123'
      expect(Discordrb::API.uri_with_query('https://discord.com/path?asdf', { test!: 123 })).to eq 'https://discord.com/path?asdf&test%21=123'
      expect(Discordrb::API.uri_with_query('https://discord.com/path?asdf', { test?: 123 })).to eq 'https://discord.com/path?asdf&test%3F=123'
    end
  end
end
