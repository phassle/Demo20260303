require 'rails_helper'

RSpec.describe 'Api::V1::WorkOrders', type: :request do
  let(:manager) { create(:user) }
  let(:property) { create(:property) }
  let(:tenant) { create(:tenant, property: property) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{manager.api_token}" } }

  describe 'authentication' do
    it 'returns 401 when no token provided' do
      get api_v1_property_work_orders_path(property)

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq('Unauthorized')
    end

    it 'returns 401 when invalid token provided' do
      get api_v1_property_work_orders_path(property),
          headers: { 'Authorization' => 'Bearer invalid_token' }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/properties/:property_id/work_orders' do
    it 'returns 200 with work orders' do
      create(:work_order, property: property, tenant: tenant)

      get api_v1_property_work_orders_path(property), headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to be_an(Array)
      expect(response.parsed_body.length).to eq(1)
    end

    it 'returns 200 with empty array when no work orders' do
      get api_v1_property_work_orders_path(property), headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it 'returns 403 when technician tries to list work orders' do
      technician = create(:user, :technician)

      get api_v1_property_work_orders_path(property),
          headers: { 'Authorization' => "Bearer #{technician.api_token}" }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/properties/:property_id/work_orders' do
    it 'creates a work order with valid params' do
      params = { work_order: { title: 'Fix door', description: 'Broken hinge', priority: 'normal' } }

      post api_v1_property_work_orders_path(property), params: params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['title']).to eq('Fix door')
    end

    it 'ignores property_id in body and uses URL param' do
      other_property = create(:property)
      params = { work_order: { title: 'Fix door', description: 'Broken hinge', priority: 'normal',
                               property_id: other_property.id } }

      post api_v1_property_work_orders_path(property), params: params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(WorkOrder.last.property_id).to eq(property.id)
    end

    it 'returns 403 when technician tries to create a work order' do
      technician = create(:user, :technician)
      params = { work_order: { title: 'Fix door', description: 'Broken hinge', priority: 'normal' } }

      post api_v1_property_work_orders_path(property),
           params: params,
           headers: { 'Authorization' => "Bearer #{technician.api_token}" },
           as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 422 when title is blank' do
      params = { work_order: { title: '', description: 'Something', priority: 'normal' } }

      post api_v1_property_work_orders_path(property), params: params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to include(/Title/)
    end

    it 'returns 400 when work_order key is missing' do
      post api_v1_property_work_orders_path(property), params: { bad: {} },
                                                       headers: auth_headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to match(/work_order/)
    end
  end

  describe 'error handling' do
    it 'returns 500 with generic message on unexpected error' do
      allow(WorkOrder).to receive(:all).and_raise(RuntimeError, 'boom')

      get api_v1_property_work_orders_path(property), headers: auth_headers

      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body['error']).to eq('Internal server error')
    end
  end
end
