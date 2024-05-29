class CreateUserConnectedAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :user_connected_accounts do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :provider_identifier, null: false
      t.string :access_token, null: false
      t.json :auth, default: {}, null: false
      t.datetime :expires_at

      t.timestamps
    end
    add_index :user_connected_accounts, [ :provider, :provider_identifier ], unique: true
  end
end
