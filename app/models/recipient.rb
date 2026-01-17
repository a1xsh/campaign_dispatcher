class Recipient < ApplicationRecord
  belongs_to :campaign

  enum status: { queued: 0, sent: 1, failed: 2 }

  validates :name, presence: true
  validates :contact, presence: true

  after_initialize :set_default_status, if: :new_record?
  after_commit :broadcast_update, on: :update

  private

  def set_default_status
    self.status ||= :queued
  end

  private

  def broadcast_update
    Turbo::StreamsChannel.broadcast_replace_to(
      campaign,
      target: ActionView::RecordIdentifier.dom_id(self),
      partial: "recipients/row",
      locals: { recipient: self }
    )
    
    campaign.reload
    Turbo::StreamsChannel.broadcast_replace_to(
      campaign,
      target: "campaign_progress",
      partial: "campaigns/progress",
      locals: { campaign: }
    )
  end
end
