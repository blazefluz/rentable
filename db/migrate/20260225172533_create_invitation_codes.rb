class CreateInvitationCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :invitation_codes do |t|
      t.string :code
      t.references :instance, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.integer :max_uses
      t.integer :current_uses
      t.datetime :expires_at
      t.boolean :deleted

      t.timestamps
    end
  end
end
