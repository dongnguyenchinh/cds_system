class CreateTitlePrivileges < ActiveRecord::Migration[6.0]
  def change
    create_table :title_privileges do |t|
      t.string :name
      
      t.timestamps
    end
  end
end
