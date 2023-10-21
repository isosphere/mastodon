# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Accounts::CredentialsController do
  render_views

  let(:user)  { Fabricate(:user) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  context 'with an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'GET #show' do
      let(:scopes) { 'read:accounts' }

      it 'returns http success' do
        get :show
        expect(response).to have_http_status(200)
      end
    end

    describe 'PATCH #update' do
      let(:scopes) { 'write:accounts' }

      describe 'with valid data' do
        before do
          allow(ActivityPub::UpdateDistributionWorker).to receive(:perform_async)

          patch :update, params: {
            display_name: "Alice Isn't Dead",
            note: "Hi!\n\nToot toot!",
            avatar: fixture_file_upload('avatar.gif', 'image/gif'),
            header: fixture_file_upload('attachment.jpg', 'image/jpeg'),
            source: {
              privacy: 'unlisted',
              sensitive: true,
            },
          }
        end

        it 'updates account info', :aggregate_failures do
          expect(response).to have_http_status(200)

          user.reload
          user.account.reload

          expect(user.account.display_name).to eq("Alice Isn't Dead")
          expect(user.account.note).to eq("Hi!\n\nToot toot!")
          expect(user.account.avatar).to exist
          expect(user.account.header).to exist
          expect(user.setting_default_privacy).to eq('unlisted')
          expect(user.setting_default_sensitive).to be(true)

          expect(ActivityPub::UpdateDistributionWorker).to have_received(:perform_async).with(user.account_id)
        end
      end

      describe 'with empty source list' do
        before do
          patch :update, params: {
            display_name: "I'm a cat",
            source: {},
          }, as: :json
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end
      end

      describe 'with a too long profile bio' do
        before do
          note = 'This is too long. '
          note += 'a' * (Account::MAX_NOTE_LENGTH - note.length + 1)
          patch :update, params: { note: note }
        end

        it 'returns http unprocessable entity' do
          expect(response).to have_http_status(422)
        end
      end
    end
  end

  context 'without an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
    end

    describe 'GET #show' do
      it 'returns http unauthorized' do
        get :show
        expect(response).to have_http_status(401)
      end
    end

    describe 'PATCH #update' do
      it 'returns http unauthorized' do
        patch :update, params: { note: 'Foo' }
        expect(response).to have_http_status(401)
      end
    end
  end
end
