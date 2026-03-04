require 'rails_helper'

RSpec.describe WorkOrders::Create do
  describe '#call' do
    let(:property) { create(:property) }

    it 'returns success and persists when params are valid' do
      params = { title: 'Fix sink', description: 'Dripping', priority: 'normal', property_id: property.id }

      result = described_class.new(params).call

      expect(result.success?).to be(true)
      expect(result.work_order).to be_persisted
      expect(result.work_order.title).to eq('Fix sink')
    end

    it 'returns failure and errors when params are invalid' do
      params = { title: '', description: '', priority: 'normal', property_id: property.id }

      result = described_class.new(params).call

      expect(result.success?).to be(false)
      expect(result.work_order.errors.full_messages).to include(/Title/, /Description/)
      expect(result.work_order).not_to be_persisted
    end
  end
end
