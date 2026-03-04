module Api
  module V1
    class WorkOrdersController < ApplicationController
      def index
        render json: WorkOrders::List.new(property_id: params[:property_id]).call
      end

      def create
        # NOTE: No Pundit authorization!
        result = WorkOrders::Create.new(work_order_params).call
        if result.success?
          render json: result.work_order, status: :created
        else
          render json: { errors: result.work_order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def work_order_params
        params.require(:work_order).permit(:title, :description, :property_id, :tenant_id, :priority)
      end
    end
  end
end
