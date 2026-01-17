class Campaign < ApplicationRecord
  has_many :recipients, dependent: :destroy

  enum status: { pending: 0, processing: 1, completed: 2 }

  validates :title, presence: true

  after_initialize :set_default_status, if: :new_record?

  def sent_count
    sent_status_value = Recipient.statuses[:sent]
    sql = ActiveRecord::Base.sanitize_sql_array([
      "SELECT COUNT(*) FROM recipients WHERE campaign_id = ? AND status = ?",
      id, sent_status_value
    ])
    result = ActiveRecord::Base.connection.select_value(sql)
    result.to_i
  end

  def total_count
    Recipient.where(campaign_id: id).count
  end

  private

  def set_default_status
    self.status ||= :pending
  end
end
