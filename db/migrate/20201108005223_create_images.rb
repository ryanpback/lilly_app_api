class CreateImages < ActiveRecord::Migration[6.0]
  def change
    create_table :images, id: :uuid do |t|
      t.string :filename
      t.belongs_to :bucket, type: :uuid

      t.timestamps
    end
  end
end
