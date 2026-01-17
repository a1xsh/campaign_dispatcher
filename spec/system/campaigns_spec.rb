require 'rails_helper'

RSpec.describe 'Campaign dispatch flow', type: :system do
  let(:campaign) { Campaign.create!(title: 'Test Campaign', status: :pending) }
  let!(:recipient1) { Recipient.create!(campaign: campaign, name: 'John Doe', contact: 'john@example.com', status: :queued) }
  let!(:recipient2) { Recipient.create!(campaign: campaign, name: 'Leo Davis', contact: 'leo@example.com', status: :queued) }
  let!(:recipient3) { Recipient.create!(campaign: campaign, name: 'Tommy Johnson', contact: 'tommy@example.com', status: :queued) }

  it 'displays campaign information' do
    visit campaign_path(campaign)

    expect(page).to have_content('Test Campaign')
    expect(page).to have_content('pending')
    expect(page).to have_button('Start Dispatch')
  end

  it 'displays all recipients with queued status' do
    visit campaign_path(campaign)

    expect(page).to have_content('John Doe')
    expect(page).to have_content('Leo Davis')
    expect(page).to have_content('Tommy Johnson')
    expect(page).to have_content('john@example.com')
    expect(page).to have_content('leo@example.com')
    expect(page).to have_content('tommy@example.com')

    within('table') do
      expect(page).to have_content('queued', count: 3)
    end
  end

  it 'displays initial progress as 0 of 3' do
    visit campaign_path(campaign)

    within('#campaign_progress') do
      expect(page).to have_content('Sent 0 of 3')
    end
  end

  context 'when starting a campaign dispatch', js: true do
    it 'updates campaign status to processing after clicking start' do
      visit campaign_path(campaign)

      expect(page).to have_content('pending')
      expect(page).to have_button('Start Dispatch')

      click_button 'Start Dispatch'

      expect(page).to have_current_path(campaign_path(campaign), wait: 5)

      visit campaign_path(campaign)

      expect(page).to have_content('processing')
      expect(page).not_to have_button('Start Dispatch')
    end

    it 'dynamically updates recipient statuses as job processes them', js: true do
      visit campaign_path(campaign)

      click_button 'Start Dispatch'

      expect(page).to have_current_path(campaign_path(campaign), wait: 5)

      sleep 3

      visit campaign_path(campaign)

      expect(page).to have_content('sent', minimum: 1)

      within('table') do
        expect(page).to have_content('sent', minimum: 1)
      end
    end

    it 'dynamically updates progress counter as recipients are processed', js: true do
      visit campaign_path(campaign)

      click_button 'Start Dispatch'

      expect(page).to have_current_path(campaign_path(campaign), wait: 5)

      sleep 3

      visit campaign_path(campaign)

      expect(page).to have_content(/Sent [1-3] of 3/)
    end

    it 'completes all recipients and updates campaign status', js: true do
      visit campaign_path(campaign)

      click_button 'Start Dispatch'

      expect(page).to have_current_path(campaign_path(campaign), wait: 5)

      sleep 10

      visit campaign_path(campaign)

      within('table') do
        expect(page).to have_content('sent', count: 3)
      end

      expect(page).to have_content('Sent 3 of 3')

      expect(page).to have_content('completed')
    end

    it 'updates individual recipient rows without page refresh', js: true do
      visit campaign_path(campaign)

      expect(page).to have_css("##{dom_id(recipient1)}")
      expect(page.find("##{dom_id(recipient1)}")).to have_content('queued')

      click_button 'Start Dispatch'

      expect(page).to have_current_path(campaign_path(campaign), wait: 5)

      sleep 10

      visit campaign_path(campaign)

      expect(page.find("##{dom_id(recipient1)}")).to have_content(/sent/i)
      expect(page.find("##{dom_id(recipient2)}")).to have_content(/sent/i)
    end
  end

  context 'when creating a new campaign' do
    it 'creates campaign with recipients from form fields' do
      visit root_path

      fill_in 'campaign[title]', with: 'New Campaign'

      name_inputs = all('input[name="campaign[recipients][][name]"]')
      contact_inputs = all('input[name="campaign[recipients][][contact]"]')

      name_inputs.first.set('John Doe')
      contact_inputs.first.set('john@example.com')

      click_button '+ Add Recipient'
      sleep 0.1
      name_inputs = all('input[name="campaign[recipients][][name]"]')
      contact_inputs = all('input[name="campaign[recipients][][contact]"]')
      name_inputs.last.set('Leo Davis')
      contact_inputs.last.set('leo@example.com')

      click_button '+ Add Recipient'
      sleep 0.1
      name_inputs = all('input[name="campaign[recipients][][name]"]')
      contact_inputs = all('input[name="campaign[recipients][][contact]"]')
      name_inputs.last.set('Tommy Johnson')
      contact_inputs.last.set('tommy@example.com')

      click_button 'Create'

      expect(page).to have_content('New Campaign', wait: 5)

      created_campaign = Campaign.find_by(title: 'New Campaign')
      expect(created_campaign).not_to be_nil

      expect(page).to have_current_path(campaign_path(created_campaign), wait: 5)
      expect(page).to have_content('New Campaign')
      expect(page).to have_content('John Doe')
      expect(page).to have_content('Leo Davis')
      expect(page).to have_content('Tommy Johnson')
      expect(page).to have_content('john@example.com')
      expect(page).to have_content('leo@example.com')
      expect(page).to have_content('tommy@example.com')
    end

    it 'shows error when title is missing' do
      visit root_path

      all('input[name="campaign[recipients][][name]"]').first.set('John Doe')
      all('input[name="campaign[recipients][][contact]"]').first.set('john@example.com')

      click_button 'Create'

      expect(page).to have_content("can't be blank")
    end
  end

  private

  def dom_id(record)
    ActionView::RecordIdentifier.dom_id(record)
  end
end
