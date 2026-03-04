require 'rails_helper'

RSpec.describe WorkOrders::List do
  let(:property) { create(:property) }
  let(:other_property) { create(:property) }
  let(:tenant) { create(:tenant, property: property) }

  describe '#call' do
    it 'returns work orders for the property' do
      create(:work_order, property: property, tenant: tenant, title: 'Fix door')
      create(:work_order, property: property, tenant: tenant, title: 'Fix window')

      result = described_class.new(property_id: property.id).call

      expect(result.length).to eq(2)
      expect(result.pluck(:title)).to contain_exactly('Fix door', 'Fix window')
    end

    it 'excludes work orders from other properties' do
      create(:work_order, property: property, tenant: tenant)
      create(:work_order, property: other_property)

      result = described_class.new(property_id: property.id).call

      expect(result.length).to eq(1)
    end

    it 'returns empty array when no work orders' do
      result = described_class.new(property_id: property.id).call

      expect(result).to eq([])
    end

    it 'returns correct hash structure' do
      wo = create(:work_order, property: property, tenant: tenant, title: 'Fix door', status: 'open', priority: 'high')

      result = described_class.new(property_id: property.id).call

      expect(result.first).to include(
        id: wo.id,
        title: 'Fix door',
        status: 'open',
        priority: 'high',
        property: property.name,
        tenant: tenant.name
      )
    end
  end
end
