class AddIsDeleteToCompetencies < ActiveRecord::Migration[6.0]
  def change
    add_column :competencies, :is_delete, :boolean, default: false
  end
end
