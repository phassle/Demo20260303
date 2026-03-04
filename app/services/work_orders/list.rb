module WorkOrders
  class List
    def initialize(property_id:)
      @property_id = property_id
    end

    def call
      # NOTE: This has an N+1 query problem — no .includes() (issue #2, out of scope)
      WorkOrder.where(property_id: @property_id).map { |wo| serialize(wo) }
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
