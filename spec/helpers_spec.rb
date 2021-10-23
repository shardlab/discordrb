# frozen_string_literal: true

describe HelperMethods do
  describe '#load_data_file' do
    it 'loads the test data correctly' do
      data = load_data_file(:test)
      expect(data['success']).to eq(true)
    end
  end

  describe '#fixture' do
    fixture :data, [:test]

    it 'loads the test data correctly' do
      expect(data['success']).to eq(true)
    end
  end

  describe '#fixture_property' do
    fixture :data, [:test]
    fixture_property :data_success, :data, ['success']
    fixture_property :data_success_str, :data, ['success'], :to_s

    it 'defines the test property correctly' do
      expect(data_success).to eq(true)
    end

    it 'filters data correctly' do
      expect(data_success_str).to eq('true')
    end
  end
end
