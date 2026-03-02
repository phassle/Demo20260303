module Api
  module V1
    class WorkOrdersController < ApplicationController
      def index
        authorize WorkOrder, :index?
        work_orders = policy_scope(WorkOrder).where(property_id: params[:property_id])
                                             .includes(:property, :tenant, :assigned_to)
        render json: work_orders.map { |work_order| serialize_work_order(work_order) }
      end

      def create
        service = CreateWorkOrder.new(work_order_params, params[:property_id])
        authorize service.work_order
        if service.call
          render json: service.work_order, status: :created
        else
          render json: { errors: service.work_order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def work_order_params
        params.require(:work_order).permit(:title, :description, :tenant_id, :priority)
      end

      def serialize_work_order(work_order)
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
end
