require 'rails_helper'

RSpec.describe 'Campaigns', type: :request do
  describe 'POST /campaigns' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          campaign: {
            title: 'Summer Sale Campaign',
            recipients: [
              { name: 'John Doe', contact: 'john@example.com' },
              { name: 'Leo Davis', contact: 'leo@example.com' },
              { name: 'Tommy Johnson', contact: 'tommy@example.com' }
            ]
          }
        }
      end

      it 'creates a new campaign' do
        expect {
          post campaigns_path, params: valid_params
        }.to change(Campaign, :count).by(1)
      end

      it 'creates recipients for the campaign' do
        expect {
          post campaigns_path, params: valid_params
        }.to change(Recipient, :count).by(3)
      end

      it 'sets campaign status to pending' do
        post campaigns_path, params: valid_params
        campaign = Campaign.last
        expect(campaign.status).to eq('pending')
      end

      it 'creates recipients with queued status' do
        post campaigns_path, params: valid_params
        campaign = Campaign.last
        expect(campaign.recipients.pluck(:status)).to all(eq('queued'))
      end

      it 'creates recipients with correct name and contact' do
        post campaigns_path, params: valid_params
        campaign = Campaign.last

        expect(campaign.recipients.count).to eq(3)
        expect(campaign.recipients.pluck(:name)).to contain_exactly('John Doe', 'Leo Davis', 'Tommy Johnson')
        expect(campaign.recipients.pluck(:contact)).to contain_exactly('john@example.com', 'leo@example.com', 'tommy@example.com')
      end

      it 'redirects to the campaign show page' do
        post campaigns_path, params: valid_params
        campaign = Campaign.last
        expect(response).to redirect_to(campaign_path(campaign))
      end

      it 'ignores blank recipient entries' do
        params_with_blanks = {
          campaign: {
            title: 'Test Campaign',
            recipients: [
              { name: 'John Doe', contact: 'john@example.com' },
              { name: '', contact: '' },
              { name: 'Leo Davis', contact: 'leo@example.com' },
              { name: '   ', contact: '   ' }
            ]
          }
        }

        expect {
          post campaigns_path, params: params_with_blanks
        }.to change(Recipient, :count).by(2)
      end

      it 'ignores invalid recipient entries (missing name or contact)' do
        params_with_invalid = {
          campaign: {
            title: 'Test Campaign',
            recipients: [
              { name: 'John Doe', contact: 'john@example.com' },
              { name: '', contact: 'missing@example.com' },
              { name: 'Leo Davis', contact: '' }
            ]
          }
        }

        expect {
          post campaigns_path, params: params_with_invalid
        }.to change(Recipient, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          campaign: {
            title: '',
            recipients: [
              { name: 'John Doe', contact: 'john@example.com' }
            ]
          }
        }
      end

      it 'does not create a campaign without title' do
        expect {
          post campaigns_path, params: invalid_params
        }.not_to change(Campaign, :count)
      end

      it 'renders the index template with errors' do
        post campaigns_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Campaigns')
      end

      it 'displays error message' do
        post campaigns_path, params: invalid_params
        expect(response.body).to match(/can't be blank|can&#39;t be blank/i)
      end
    end
  end

  describe 'GET /campaigns/:id' do
    let(:campaign) { Campaign.create!(title: 'Test Campaign') }
    let!(:recipient1) { Recipient.create!(campaign: campaign, name: 'John', contact: 'john@example.com') }
    let!(:recipient2) { Recipient.create!(campaign: campaign, name: 'Leo', contact: 'leo@example.com') }

    it 'returns successful response' do
      get campaign_path(campaign)
      expect(response).to have_http_status(:success)
    end

    it 'displays campaign information' do
      get campaign_path(campaign)
      expect(response.body).to include(campaign.title)
      expect(response.body).to include(campaign.status)
    end

    it 'displays all recipients' do
      get campaign_path(campaign)
      expect(response.body).to include('John')
      expect(response.body).to include('Leo')
      expect(response.body).to include('john@example.com')
      expect(response.body).to include('leo@example.com')
    end
  end

  describe 'POST /campaigns/:id/start' do
    let(:campaign) { Campaign.create!(title: 'Test Campaign', status: :pending) }
    let!(:recipient) { Recipient.create!(campaign: campaign, name: 'John', contact: 'john@example.com', status: :queued) }

    it 'updates campaign status to processing' do
      post start_campaign_path(campaign)
      expect(campaign.reload.status).to eq('processing')
    end

    it 'enqueues DispatchCampaignJob' do
      expect {
        post start_campaign_path(campaign)
      }.to have_enqueued_job(DispatchCampaignJob).with(campaign.id)
    end

    it 'redirects to campaign show page' do
      post start_campaign_path(campaign)
      expect(response).to redirect_to(campaign_path(campaign))
    end

    context 'when campaign is already processing' do
      before { campaign.update!(status: :processing) }

      it 'does not change status' do
        expect {
          post start_campaign_path(campaign)
        }.not_to change { campaign.reload.status }
      end

      it 'redirects without enqueuing job' do
        expect {
          post start_campaign_path(campaign)
        }.not_to have_enqueued_job(DispatchCampaignJob)
      end
    end

    context 'when campaign is completed' do
      before { campaign.update!(status: :completed) }

      it 'does not change status' do
        expect {
          post start_campaign_path(campaign)
        }.not_to change { campaign.reload.status }
      end
    end
  end
end
