class CreateApprovers < ActiveRecord::Migration[6.0]
  def change
    # done
    create_table :approvers do |t|
      t.belongs_to :admin_user, foreign_key: true
      t.bigint  :approver_id
      t.references :approver_id, references: :admin_users

      t.timestamps
    end
  end
end
