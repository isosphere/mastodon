# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Followed tags' do
  let(:user)    { Fabricate(:user) }
  let(:scopes)  { 'read:follows' }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/followed_tags' do
    subject do
      get '/api/v1/followed_tags', headers: headers, params: params
    end

    let!(:tag_follows) { Fabricate.times(5, :tag_follow, account: user.account) }
    let(:params)       { {} }

    let(:expected_response) do
      tag_follows.map do |tag_follow|
        a_hash_including(name: tag_follow.tag.name, following: true)
      end
    end

    before do
      Fabricate(:tag_follow)
    end

    it_behaves_like 'forbidden for wrong scope', 'write write:follows'

    it 'returns http success' do
      subject

      expect(response).to have_http_status(:success)
    end

    it 'returns the followed tags correctly' do
      subject

      expect(body_as_json).to match_array(expected_response)
    end

    context 'with limit param' do
      let(:params) { { limit: 3 } }

      it 'returns only the requested number of follow tags' do
        subject

        expect(body_as_json.size).to eq(params[:limit])
      end

      it 'sets the correct pagination header for the prev path' do
        subject

        expect(response.headers['Link'].find_link(%w(rel prev)).href).to eq(api_v1_followed_tags_url(limit: params[:limit], since_id: tag_follows.last.id))
      end

      it 'sets the correct pagination header for the next path' do
        subject

        expect(response.headers['Link'].find_link(%w(rel next)).href).to eq(api_v1_followed_tags_url(limit: params[:limit], max_id: tag_follows[2].id))
      end
    end
  end
end
