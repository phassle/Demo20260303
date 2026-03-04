require 'rails_helper'

RSpec.describe WorkOrders::Create do
  let(:property) { create(:property) }
  let(:tenant) { create(:tenant, property: property) }

  describe '#call' do
    context 'with valid params' do
      let(:params) do
        {
          title: 'Fix door',
          description: 'Broken hinge',
          priority: 'normal',
          property_id: property.id,
          tenant_id: tenant.id
        }
      end

      it 'creates a work order' do
        expect do
          described_class.new(params).call
        end.to change(WorkOrder, :count).by(1)
      end

      it 'returns success result' do
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.work_order).to be_a(WorkOrder)
        expect(result.work_order.title).to eq('Fix door')
        expect(result.errors).to be_nil
      end
    end

    context 'with invalid params' do
      let(:params) do
        {
          title: '',
          description: 'Something',
          priority: 'normal',
          property_id: property.id
        }
      end

      it 'does not create a work order' do
        expect do
          described_class.new(params).call
        end.not_to change(WorkOrder, :count)
      end

      it 'returns failure result with errors' do
        result = described_class.new(params).call

        expect(result.success?).to be false
        expect(result.work_order).to be_nil
        expect(result.errors).to be_an(Array)
        expect(result.errors).to include(/Title/)
      end
    end
  end
end
