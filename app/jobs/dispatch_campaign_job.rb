class DispatchCampaignJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    
    broadcast_status(campaign.reload)

    campaign.recipients.queued.each do |recipient|
      begin
        sleep(rand(1..3))
        recipient.update!(status: :sent)
      rescue => e
        recipient.update!(status: :failed)
      end
    end

    campaign.update!(status: :completed)
    campaign = Campaign.find(campaign_id)
    broadcast_progress(campaign)
    broadcast_status(campaign)
  end

  private

  def broadcast_recipient(recipient)
    Turbo::StreamsChannel.broadcast_replace_to(
      recipient.campaign,
      target: ActionView::RecordIdentifier.dom_id(recipient),
      partial: "recipients/row",
      locals: { recipient: }
    )
  end

  def broadcast_progress(campaign)
    Turbo::StreamsChannel.broadcast_replace_to(
      campaign,
      target: "campaign_progress",
      partial: "campaigns/progress",
      locals: { campaign: }
    )
  end

  def broadcast_status(campaign)
    Turbo::StreamsChannel.broadcast_replace_to(
      campaign,
      target: "campaign_status",
      partial: "campaigns/status",
      locals: { campaign: }
    )
    
    Turbo::StreamsChannel.broadcast_replace_to(
      campaign,
      target: "start_button",
      partial: "campaigns/start_button",
      locals: { campaign: }
    )
  end
end
