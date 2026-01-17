require 'rails_helper'

RSpec.describe DispatchCampaignJob, type: :job do
  describe '#perform' do
    let(:campaign) { Campaign.create!(title: 'Test Campaign', status: :pending) }
    let!(:recipient1) { Recipient.create!(campaign: campaign, name: 'John', contact: 'john@example.com', status: :queued) }
    let!(:recipient2) { Recipient.create!(campaign: campaign, name: 'Leo', contact: 'leo@example.com', status: :queued) }

    before do
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    end

    it 'processes all queued recipients' do
      expect {
        DispatchCampaignJob.new.perform(campaign.id)
      }.to change { recipient1.reload.status }.from('queued').to('sent')
        .and change { recipient2.reload.status }.from('queued').to('sent')
    end

    it 'updates campaign status to completed' do
      DispatchCampaignJob.new.perform(campaign.id)

      expect(campaign.reload.status).to eq('completed')
    end

    it 'broadcasts updates for each recipient' do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).at_least(:twice)

      DispatchCampaignJob.new.perform(campaign.id)
    end

    it 'broadcasts progress updates' do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        campaign,
        target: 'campaign_progress',
        partial: 'campaigns/progress',
        locals: { campaign: kind_of(Campaign) }
      ).at_least(:once)

      DispatchCampaignJob.new.perform(campaign.id)
    end

    it 'only processes queued recipients' do
      recipient3 = Recipient.create!(campaign: campaign, name: 'Tommy', contact: 'tommy@example.com', status: :sent)

      DispatchCampaignJob.new.perform(campaign.id)

      expect(recipient1.reload.status).to eq('sent')
      expect(recipient2.reload.status).to eq('sent')
      expect(recipient3.reload.status).to eq('sent')
    end

    it 'broadcasts recipient updates with correct parameters' do
      recipient_id = "recipient_#{recipient1.id}"
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        campaign,
        target: recipient_id,
        partial: 'recipients/row',
        locals: { recipient: recipient1 }
      ).at_least(:once)

      DispatchCampaignJob.new.perform(campaign.id)
    end

    it 'simulates sending delay' do
      start_time = Time.current
      DispatchCampaignJob.new.perform(campaign.id)
      end_time = Time.current

      expect(end_time - start_time).to be >= 1
    end

    context 'when an error occurs' do
      before do
        allow_any_instance_of(Recipient).to receive(:update!) do |recipient, attrs|
          status_value = attrs[:status] || attrs['status']
          if status_value == :sent || status_value == 'sent' || status_value == 1
            raise StandardError.new('Test error')
          else
            failed_status = Recipient.statuses[:failed]
            recipient.update_columns(status: failed_status)
          end
        end
      end

      it 'marks recipient as failed' do
        DispatchCampaignJob.new.perform(campaign.id)

        expect(recipient1.reload.status).to eq('failed')
        expect(recipient2.reload.status).to eq('failed')
      end

      it 'still broadcasts updates even when errors occur' do
        # Allow broadcasts from after_commit callbacks
        allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to).and_call_original

        DispatchCampaignJob.new.perform(campaign.id)

        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).at_least(:twice)
      end

      it 'still completes the campaign even if some recipients fail' do
        DispatchCampaignJob.new.perform(campaign.id)

        expect(campaign.reload.status).to eq('completed')
      end
    end

    context 'with no recipients' do
      let(:empty_campaign) { Campaign.create!(title: 'Empty Campaign', status: :pending) }

      it 'completes immediately' do
        DispatchCampaignJob.new.perform(empty_campaign.id)

        expect(empty_campaign.reload.status).to eq('completed')
      end
    end
  end
end
