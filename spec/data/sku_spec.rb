# frozen_string_literal: true

require 'discordrb'

describe Discordrb::SKU do
  let(:bot) { double('bot') }

  subject(:sku) do
    described_class.new(sku_data, bot)
  end

  fixture :sku_data, %i[sku]

  describe '#name' do
    it 'returns the name of the sku' do
      expect(sku.name).to eq sku_data['name']
    end
  end

  describe '#slug' do
    it 'returns the slug of the sku' do
      expect(sku.slug).to eq sku_data['slug']
    end
  end

  describe '#type' do
    it 'returns the type of the sku' do
      expect(sku.type).to eq sku_data['type']
    end
  end

  describe '#flags' do
    it 'returns the flags of the sku' do
      expect(sku.flags).to eq sku_data['flags']
    end
  end

  describe '#application_id' do
    it 'returns the application ID of the sku' do
      expect(sku.application_id).to eq sku_data['application_id'].to_i
    end
  end

  describe '#durable?' do
    it 'returns if the sku is durable' do
      expect(sku.durable?).to eq sku_data['type'] == Discordrb::SKU::TYPES[:durable]
    end
  end

  describe '#consumable?' do
    it 'returns if the sku is consumable' do
      expect(sku.consumable?).to eq sku_data['type'] == Discordrb::SKU::TYPES[:consumable]
    end
  end

  describe '#subscription?' do
    it 'returns if the sku is subscription' do
      expect(sku.subscription?).to eq sku_data['type'] == Discordrb::SKU::TYPES[:subscription]
    end
  end

  describe '#subscription_group?' do
    it 'returns if the sku is a part of a subscription group' do
      expect(sku.subscription_group?).to eq sku_data['type'] == Discordrb::SKU::TYPES[:subscription_group]
    end
  end

  describe '#available?' do
    it 'returns if the sku is available' do
      expect(sku.available?).to eq sku_data['flags'].anybits?(Discordrb::SKU::FLAGS[:available])
    end
  end

  describe '#server_subscription?' do
    it 'returns if the sku is a server subscription' do
      expect(sku.server_subscription?).to eq sku_data['flags'].anybits?(Discordrb::SKU::FLAGS[:server_subscription])
    end
  end

  describe '#user_subscription?' do
    it 'returns if the sku is a user subscription' do
      expect(sku.user_subscription?).to eq sku_data['flags'].anybits?(Discordrb::SKU::FLAGS[:user_subscription])
    end
  end
end
