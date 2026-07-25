class CreateStudents < ActiveRecord::Migration[7.1]
  def change
    create_table :students do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :birth_date, null: false
      t.references :school_class, null: false, foreign_key: true

      t.timestamps
    end
  end
end
