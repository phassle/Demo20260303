module WorkOrders
  class Create
    Result = Struct.new(:success?, :work_order)

    def initialize(params)
      @params = params
    end

    def call
      work_order = WorkOrder.new(@params)
      if work_order.save
        Result.new(true, work_order)
      else
        Result.new(false, work_order)
      end
    end
  end
end
