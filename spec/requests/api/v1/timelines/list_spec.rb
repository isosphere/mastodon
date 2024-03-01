# frozen_string_literal: true

require 'rails_helper'

describe 'API V1 Timelines List' do
  let(:user) { Fabricate(:user) }
  let(:scopes)  { 'read:statuses' }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }
  let(:list) { Fabricate(:list, account: user.account) }

  context 'with a user context' do
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:lists') }

    describe 'GET /api/v1/timelines/list/:id' do
      before do
        follow = Fabricate(:follow, account: user.account)
        list.accounts << follow.target_account
        PostStatusService.new.call(follow.target_account, text: 'New status for user home timeline.')
      end

      it 'returns http success' do
        get "/api/v1/timelines/list/#{list.id}", headers: headers

        expect(response).to have_http_status(200)
      end
    end
  end

  context 'with the wrong user context' do
    let(:other_user) { Fabricate(:user) }
    let(:token)      { Fabricate(:accessible_access_token, resource_owner_id: other_user.id, scopes: 'read') }

    describe 'GET #show' do
      it 'returns http not found' do
        get "/api/v1/timelines/list/#{list.id}", headers: headers

        expect(response).to have_http_status(404)
      end
    end
  end

  context 'without a user context' do
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: nil, scopes: 'read') }

    describe 'GET #show' do
      it 'returns http unprocessable entity' do
        get "/api/v1/timelines/list/#{list.id}", headers: headers

        expect(response).to have_http_status(422)
        expect(response.headers['Link']).to be_nil
      end
    end
  end
end
