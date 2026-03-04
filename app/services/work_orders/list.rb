module WorkOrders
  class List
    def initialize(property_id:)
      @property_id = property_id
    end

    def call
      WorkOrder.where(property_id: @property_id).map { |work_order| serialize(work_order) }
    end

    private

    def serialize(work_order)
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
end
