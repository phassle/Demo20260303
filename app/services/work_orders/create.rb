module WorkOrders
  class Create
    Result = Struct.new(:success?, :work_order, :errors)

    def initialize(params)
      @params = params
    end

    def call
      work_order = WorkOrder.new(@params)
      if work_order.save
        Result.new(true, work_order, nil)
      else
        Result.new(false, nil, work_order.errors.full_messages)
      end
    end
  end
end
