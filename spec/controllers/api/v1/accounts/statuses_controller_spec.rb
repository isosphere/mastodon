# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Accounts::StatusesController do
  render_views

  let(:user)  { Fabricate(:user) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:statuses') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    it 'returns expected headers', :aggregate_failures do
      Fabricate(:status, account: user.account)
      get :index, params: { account_id: user.account.id, limit: 1 }

      expect(response).to have_http_status(200)
      expect(links_from_header.size)
        .to eq(2)
    end

    context 'with only media' do
      it 'returns http success' do
        get :index, params: { account_id: user.account.id, only_media: true }

        expect(response).to have_http_status(200)
      end
    end

    context 'with exclude replies' do
      let!(:status) { Fabricate(:status, account: user.account) }
      let!(:status_self_reply) { Fabricate(:status, account: user.account, thread: status) }

      before do
        Fabricate(:status, account: user.account, thread: Fabricate(:status)) # Reply to another user
        get :index, params: { account_id: user.account.id, exclude_replies: true }
      end

      it 'returns posts along with self replies', :aggregate_failures do
        expect(response)
          .to have_http_status(200)
        expect(body_as_json)
          .to have_attributes(size: 2)
          .and contain_exactly(
            include(id: status.id.to_s),
            include(id: status_self_reply.id.to_s)
          )
      end
    end

    context 'with only own pinned' do
      before do
        Fabricate(:status_pin, account: user.account, status: Fabricate(:status, account: user.account))
      end

      it 'returns http success and includes a header link' do
        get :index, params: { account_id: user.account.id, pinned: true }

        expect(response).to have_http_status(200)
        expect(links_from_header.size)
          .to eq(1)
        expect(links_from_header)
          .to contain_exactly(
            have_attributes(
              href: /pinned=true/,
              attr_pairs: contain_exactly(['rel', 'prev'])
            )
          )
      end
    end

    context 'with enough pinned statuses to paginate' do
      before do
        stub_const 'Api::BaseController::DEFAULT_STATUSES_LIMIT', 1
        2.times { Fabricate(:status_pin, account: user.account) }
      end

      it 'returns http success and header pagination links to prev and next' do
        get :index, params: { account_id: user.account.id, pinned: true }

        expect(response).to have_http_status(200)
        expect(links_from_header.size)
          .to eq(2)
        expect(links_from_header)
          .to contain_exactly(
            have_attributes(
              href: /pinned=true/,
              attr_pairs: contain_exactly(['rel', 'next'])
            ),
            have_attributes(
              href: /pinned=true/,
              attr_pairs: contain_exactly(['rel', 'prev'])
            )
          )
      end
    end

    context "with someone else's pinned statuses" do
      let(:account)        { Fabricate(:account, username: 'bob', domain: 'example.com') }
      let(:status)         { Fabricate(:status, account: account) }
      let(:private_status) { Fabricate(:status, account: account, visibility: :private) }

      before do
        Fabricate(:status_pin, account: account, status: status)
        Fabricate(:status_pin, account: account, status: private_status)
      end

      it 'returns http success' do
        get :index, params: { account_id: account.id, pinned: true }
        expect(response).to have_http_status(200)
      end

      context 'when user does not follow account' do
        it 'lists the public status only' do
          get :index, params: { account_id: account.id, pinned: true }
          json = body_as_json
          expect(json.map { |item| item[:id].to_i }).to eq [status.id]
        end
      end

      context 'when user follows account' do
        before do
          user.account.follow!(account)
        end

        it 'lists both the public and the private statuses' do
          get :index, params: { account_id: account.id, pinned: true }
          json = body_as_json
          expect(json.map { |item| item[:id].to_i }).to contain_exactly(status.id, private_status.id)
        end
      end
    end
  end

  private

  def links_from_header
    response
      .headers['Link']
      .links
  end
end
