# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tag' do
  let(:user) { Fabricate(:user) }
  let(:scopes)  { 'read:statuses' }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  shared_examples 'a successful request to the tag timeline' do
    it 'returns the expected statuses', :aggregate_failures do
      subject

      expect(response).to have_http_status(200)
      expect(body_as_json.pluck(:id)).to match_array(expected_statuses.map { |status| status.id.to_s })
    end
  end

  describe 'GET /api/v1/timelines/tag/:hashtag' do
    subject do
      get "/api/v1/timelines/tag/#{hashtag}", headers: headers, params: params
    end

    before do
      Setting.timeline_preview = true
    end

    let(:account)         { Fabricate(:account) }
    let!(:private_status) { PostStatusService.new.call(account, visibility: :private, text: '#life could be a dream') } # rubocop:disable RSpec/LetSetup
    let!(:life_status)    { PostStatusService.new.call(account, text: 'tell me what is my #life without your #love') }
    let!(:war_status)     { PostStatusService.new.call(user.account, text: '#war, war never changes') }
    let!(:love_status)    { PostStatusService.new.call(account, text: 'what is #love?') }
    let(:params)          { {} }
    let(:hashtag)         { 'life' }

    context 'when given only one hashtag' do
      let(:expected_statuses) { [life_status] }

      it_behaves_like 'a successful request to the tag timeline'
    end

    context 'with any param' do
      let(:expected_statuses) { [life_status, love_status] }
      let(:params)            { { any: %(love) } }

      it_behaves_like 'a successful request to the tag timeline'
    end

    context 'with all param' do
      let(:expected_statuses) { [life_status] }
      let(:params)            { { all: %w(love) } }

      it_behaves_like 'a successful request to the tag timeline'
    end

    context 'with none param' do
      let(:expected_statuses) { [war_status] }
      let(:hashtag)           { 'war' }
      let(:params)            { { none: %w(life love) } }

      it_behaves_like 'a successful request to the tag timeline'
    end

    context 'with limit param' do
      let(:hashtag) { 'love' }
      let(:params)  { { limit: 1 } }

      it 'returns only the requested number of statuses' do
        subject

        expect(body_as_json.size).to eq(params[:limit])
      end

      it 'sets the correct pagination headers', :aggregate_failures do
        subject

        headers = response.headers['Link']

        expect(headers.find_link(%w(rel prev)).href).to eq(api_v1_timelines_tag_url(limit: 1, min_id: love_status.id.to_s))
        expect(headers.find_link(%w(rel next)).href).to eq(api_v1_timelines_tag_url(limit: 1, max_id: love_status.id.to_s))
      end
    end

    context 'when the instance allows public preview' do
      context 'when the user is not authenticated' do
        let(:headers) { {} }
        let(:expected_statuses) { [life_status] }

        it_behaves_like 'a successful request to the tag timeline'
      end
    end

    context 'when the instance does not allow public preview' do
      before do
        Form::AdminSettings.new(timeline_preview: false).save
      end

      context 'when the user is not authenticated' do
        let(:headers) { {} }

        it 'returns http unauthorized' do
          subject

          expect(response).to have_http_status(401)
        end
      end

      context 'when the user is authenticated' do
        let(:expected_statuses) { [life_status] }

        it_behaves_like 'a successful request to the tag timeline'
      end
    end
  end
end
