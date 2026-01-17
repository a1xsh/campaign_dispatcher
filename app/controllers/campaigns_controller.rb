class CampaignsController < ApplicationController
  def index
    @campaigns = Campaign.order(created_at: :desc)
    @campaign = Campaign.new
  end

  def show
    @campaign = Campaign.find(params[:id])
    @recipients = @campaign.recipients.order(:id)
  end

  def create
    @campaign = Campaign.new(title: campaign_params[:title], status: :pending)
    recipients_params = params[:campaign][:recipients] || []

    if @campaign.save
      recipients_params.each do |recipient_params|
        name = recipient_params[:name]&.strip
        contact = recipient_params[:contact]&.strip
        next if name.blank? || contact.blank?

        @campaign.recipients.create!(name:, contact:, status: :queued)
      end

      redirect_to @campaign
    else
      @campaigns = Campaign.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def start
    campaign = Campaign.find(params[:id])
    return redirect_to campaign if campaign.processing? || campaign.completed?

    campaign.update!(status: :processing)
    DispatchCampaignJob.perform_later(campaign.id)

    campaign.reload
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

    redirect_to campaign
  end

  private

  def campaign_params
    params.require(:campaign).permit(:title)
  end
end
