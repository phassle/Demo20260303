require 'rails_helper'

RSpec.describe WorkOrders::Create do
  let(:property) { create(:property) }

  describe '#call' do
    context 'with valid params' do
      let(:params) { { title: 'Fix door', description: 'Broken hinge', priority: 'normal', property_id: property.id } }

      it 'persists the work order' do
        expect { described_class.new(params).call }.to change(WorkOrder, :count).by(1)
      end

      it 'returns a successful result' do
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.work_order).to be_a(WorkOrder)
        expect(result.work_order).to be_persisted
      end
    end

    context 'with invalid params (blank title)' do
      let(:params) { { title: '', description: 'Something', priority: 'normal', property_id: property.id } }

      it 'does not persist the work order' do
        expect { described_class.new(params).call }.not_to change(WorkOrder, :count)
      end

      it 'returns a failure result with errors' do
        result = described_class.new(params).call

        expect(result.success?).to be false
        expect(result.work_order.errors.full_messages).to include(/Title/)
      end
    end
  end
end
