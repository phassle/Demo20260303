require 'rails_helper'

RSpec.describe WorkOrders::List do
  describe '#call' do
    let(:property) { create(:property) }
    let(:other_property) { create(:property) }

    it 'returns serialized work orders for the property' do
      work_order = create(:work_order, property: property)
      result = described_class.new(property_id: property.id).call

      expect(result).to eq([serialized(work_order)])
    end

    it 'excludes work orders for other properties' do
      create(:work_order, property: property)
      create(:work_order, property: other_property)

      result = described_class.new(property_id: property.id).call

      expect(result.length).to eq(1)
      expect(result.first[:property]).to eq(property.name)
    end

    it 'returns empty array when none exist' do
      expect(described_class.new(property_id: property.id).call).to eq([])
    end
  end

  def serialized(work_order)
    {
      id: work_order.id,
      title: work_order.title,
      status: work_order.status,
      priority: work_order.priority,
      property: work_order.property.name,
      tenant: work_order.tenant&.name,
      assigned_to: work_order.assigned_to&.name
    }
  end
end
