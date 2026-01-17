class CreateRecipients < ActiveRecord::Migration[7.2]
  def change
    create_table :recipients do |t|
      t.references :campaign, null: false, foreign_key: true
      t.string :name
      t.string :contact
      t.integer :status

      t.timestamps
    end
  end
end
