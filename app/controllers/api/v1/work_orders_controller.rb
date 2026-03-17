module Api
  module V1
    class WorkOrdersController < ApplicationController
      def index
        work_orders = WorkOrder.includes(:property, :tenant, :assigned_to).where(property_id: params[:property_id])
        render json: work_orders.map { |wo|
          {
            id: wo.id,
            title: wo.title,
            status: wo.status,
            priority: wo.priority,
            property: wo.property.name,
            tenant: wo.tenant&.name,
            assigned_to: wo.assigned_to&.name
          }
        }
      end

      def create
        work_order = WorkOrder.new(work_order_params)
        # NOTE: No Pundit authorization!
        if work_order.save
          render json: work_order, status: :created
        else
          render json: { errors: work_order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def work_order_params
        params.require(:work_order).permit(:title, :description, :property_id, :tenant_id, :priority)
      end
    end
  end
end
