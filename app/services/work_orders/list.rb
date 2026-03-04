module WorkOrders
  class List
    def initialize(property_id:)
      @property_id = property_id
    end

    def call
      work_orders = WorkOrder.where(property_id: @property_id)
      work_orders.map do |wo|
        {
          id: wo.id,
          title: wo.title,
          status: wo.status,
          priority: wo.priority,
          property: wo.property.name,
          tenant: wo.tenant&.name,
          assigned_to: wo.assigned_to&.name
        }
      end
    end
  end
end
