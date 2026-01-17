require 'rails_helper'

RSpec.describe Campaign, type: :model do
  describe 'associations' do
    it 'has many recipients' do
      campaign = Campaign.new(title: 'Test')
      expect(campaign).to respond_to(:recipients)
    end

    it 'destroys recipients when campaign is destroyed' do
      campaign = Campaign.create!(title: 'Test')
      recipient = Recipient.create!(campaign: campaign, name: 'John', contact: 'john@example.com')

      expect {
        campaign.destroy
      }.to change { Recipient.count }.by(-1)
    end
  end

  describe 'validations' do
    it 'requires a title' do
      campaign = Campaign.new
      expect(campaign).not_to be_valid
      expect(campaign.errors[:title]).to include("can't be blank")
    end
  end

  describe 'enums' do
    it 'has correct status values' do
      campaign = Campaign.create!(title: 'Test')
      expect(campaign.status).to eq('pending')

      campaign.processing!
      expect(campaign.status).to eq('processing')

      campaign.completed!
      expect(campaign.status).to eq('completed')
    end
  end

  describe '#sent_count' do
    let(:campaign) { Campaign.create!(title: 'Test Campaign') }

    it 'returns the count of sent recipients' do
      Recipient.create!(campaign: campaign, name: 'John', contact: 'john@example.com', status: :sent)
      Recipient.create!(campaign: campaign, name: 'Leo', contact: 'leo@example.com', status: :sent)
      Recipient.create!(campaign: campaign, name: 'Tommy', contact: 'tommy@example.com', status: :queued)

      expect(campaign.sent_count).to eq(2)
    end
  end

  describe '#total_count' do
    let(:campaign) { Campaign.create!(title: 'Test Campaign') }

    it 'returns the total count of recipients' do
      Recipient.create!(campaign: campaign, name: 'John', contact: 'john@example.com')
      Recipient.create!(campaign: campaign, name: 'Leo', contact: 'leo@example.com')
      Recipient.create!(campaign: campaign, name: 'Tommy', contact: 'tommy@example.com')

      expect(campaign.total_count).to eq(3)
    end
  end
end
