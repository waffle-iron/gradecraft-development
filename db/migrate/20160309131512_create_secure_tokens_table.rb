class CreateSecureTokensTable < ActiveRecord::Migration
  def change
    create_table :secure_tokens do |t|
      t.string   :uuid
      t.text     :encrypted_key

      t.references :user, index: true, foreign_key: true
      t.references :course, index: true, foreign_key: true
      t.references :target, polymorphic: true, index: true

      t.datetime :expires_at
      t.timestamps null: false
    end
  end
end
