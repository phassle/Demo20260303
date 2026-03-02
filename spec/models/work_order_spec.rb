require "rails_helper"

RSpec.describe WorkOrder, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:property) }
    it { is_expected.to belong_to(:tenant).optional }
    it { is_expected.to belong_to(:assigned_to).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[open in_progress completed cancelled]) }
    it { is_expected.to validate_inclusion_of(:priority).in_array(%w[low normal high urgent]) }
  end

  describe "scopes" do
    let(:property) { create(:property) }

    describe ".open_orders" do
      it "returns only open work orders" do
        open = create(:work_order, property: property, status: "open")
        create(:work_order, property: property, status: "completed")
        expect(WorkOrder.open_orders).to eq([open])
      end
    end

    describe ".unassigned" do
      it "returns work orders without an assignee" do
        unassigned = create(:work_order, property: property, assigned_to: nil)
        create(:work_order, property: property, assigned_to: create(:user, :technician))
        expect(WorkOrder.unassigned).to eq([unassigned])
      end
    end
  end
end
