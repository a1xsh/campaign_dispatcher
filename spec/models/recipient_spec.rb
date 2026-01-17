require 'rails_helper'

RSpec.describe Recipient, type: :model do
  describe 'associations' do
    it 'belongs to a campaign' do
      recipient = Recipient.new(name: 'John', contact: 'john@example.com')
      expect(recipient).to respond_to(:campaign)
    end
  end

  describe 'validations' do
    it 'requires a name' do
      campaign = Campaign.create!(title: 'Test')
      recipient = Recipient.new(campaign: campaign, contact: 'john@example.com')
      expect(recipient).not_to be_valid
      expect(recipient.errors[:name]).to include("can't be blank")
    end

    it 'requires a contact' do
      campaign = Campaign.create!(title: 'Test')
      recipient = Recipient.new(campaign: campaign, name: 'John')
      expect(recipient).not_to be_valid
      expect(recipient.errors[:contact]).to include("can't be blank")
    end
  end

  describe 'enums' do
    it 'has correct status values' do
      campaign = Campaign.create!(title: 'Test')
      recipient = Recipient.create!(campaign: campaign, name: 'John', contact: 'john@example.com')
      expect(recipient.status).to eq('queued')

      recipient.sent!
      expect(recipient.status).to eq('sent')

      recipient.failed!
      expect(recipient.status).to eq('failed')
    end
  end
end
