class CreateWorkOrder
  attr_reader :work_order

  def initialize(params, property_id)
    @work_order = WorkOrder.new(params.merge(property_id: property_id))
  end

  def call
    work_order.save
  end
end
