require 'rails_helper'

RSpec.describe WorkOrders::List do
  let(:property) { create(:property) }
  let(:other_property) { create(:property) }
  let(:tenant) { create(:tenant, property: property) }
  let(:user) { create(:user) }

  describe '#call' do
    it 'returns serialized work orders for the given property' do
      create(:work_order, property: property, tenant: tenant, assigned_to: user)

      results = described_class.new(property_id: property.id).call

      expect(results).to be_an(Array)
      expect(results.length).to eq(1)
    end

    it 'excludes work orders from other properties' do
      create(:work_order, property: property)
      create(:work_order, property: other_property)

      results = described_class.new(property_id: property.id).call

      expect(results.length).to eq(1)
    end

    it 'returns empty array when no work orders exist' do
      results = described_class.new(property_id: property.id).call

      expect(results).to eq([])
    end

    it 'returns hashes with correct keys' do
      create(:work_order, property: property, tenant: tenant)

      result = described_class.new(property_id: property.id).call.first

      expect(result.keys).to match_array(%i[id title status priority property tenant assigned_to])
    end

    it 'includes assigned_to name when a user is assigned' do
      create(:work_order, property: property, assigned_to: user)

      result = described_class.new(property_id: property.id).call.first

      expect(result[:assigned_to]).to eq(user.name)
    end

    it 'returns empty array for nil property_id' do
      results = described_class.new(property_id: nil).call

      expect(results).to eq([])
    end

    it 'returns empty array for nonexistent property_id' do
      results = described_class.new(property_id: 0).call

      expect(results).to eq([])
    end
  end
end
