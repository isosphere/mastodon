# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Blocks' do
  let(:user)    { Fabricate(:user) }
  let(:scopes)  { 'read:blocks' }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/blocks' do
    subject do
      get '/api/v1/blocks', headers: headers, params: params
    end

    let!(:blocks) { Fabricate.times(3, :block, account: user.account) }
    let(:params)  { {} }

    let(:expected_response) do
      blocks.map { |block| a_hash_including(id: block.target_account.id.to_s, username: block.target_account.username) }
    end

    it_behaves_like 'forbidden for wrong scope', 'write write:blocks'

    it 'returns the blocked accounts', :aggregate_failures do
      subject

      expect(response).to have_http_status(200)
      expect(body_as_json).to match_array(expected_response)
    end

    context 'with limit param' do
      let(:params) { { limit: 2 } }

      it 'returns only the requested number of blocked accounts' do
        subject

        expect(body_as_json.size).to eq(params[:limit])
      end

      it 'sets the correct pagination header for the prev path' do
        subject

        expect(response.headers['Link'].find_link(%w(rel prev)).href).to eq(api_v1_blocks_url(limit: params[:limit], since_id: blocks.last.id))
      end

      it 'sets the correct pagination header for the next path' do
        subject

        expect(response.headers['Link'].find_link(%w(rel next)).href).to eq(api_v1_blocks_url(limit: params[:limit], max_id: blocks[1].id))
      end
    end

    context 'with max_id param' do
      let(:params) { { max_id: blocks[1].id } }

      it 'queries the blocks in range according to max_id', :aggregate_failures do
        subject

        response_body = body_as_json

        expect(response_body.size).to be 1
        expect(response_body[0][:id]).to eq(blocks[0].target_account.id.to_s)
      end
    end

    context 'with since_id param' do
      let(:params) { { since_id: blocks[1].id } }

      it 'queries the blocks in range according to since_id', :aggregate_failures do
        subject

        response_body = body_as_json

        expect(response_body.size).to be 1
        expect(response_body[0][:id]).to eq(blocks[2].target_account.id.to_s)
      end
    end
  end
end
