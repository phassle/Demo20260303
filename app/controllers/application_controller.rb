class ApplicationController < ActionController::API
  # include Pundit::Authorization  # TODO: not yet enabled

  rescue_from StandardError, with: :handle_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  private

  def handle_not_found(exception)
    Rails.logger.warn("[NotFound] #{exception.message}")
    render json: { error: 'Resource not found' }, status: :not_found
  end

  def handle_record_invalid(exception)
    Rails.logger.warn("[RecordInvalid] #{exception.message}")
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def handle_parameter_missing(exception)
    Rails.logger.warn("[ParameterMissing] #{exception.message}")
    render json: { error: exception.message }, status: :bad_request
  end

  def handle_internal_error(exception)
    Rails.logger.error("[InternalError] #{exception.class}: #{exception.message}")
    Rails.logger.error(exception.backtrace&.first(10)&.join("\n"))
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end
end
