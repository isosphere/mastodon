# frozen_string_literal: true

require 'rails_helper'

describe 'UnloggedBrowsing' do
  subject { page }

  before do
    visit root_path
  end

  it 'loads the home page' do
    expect(subject).to have_css('div.app-holder')

    expect(subject).to have_css('div.columns-area__panels__main')
  end
end
