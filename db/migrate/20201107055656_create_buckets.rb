class CreateBuckets < ActiveRecord::Migration[6.0]
  def change
    create_table :buckets, id: :uuid do |t|
      t.belongs_to :user, type: :uuid, foreign_key: true, index: true

      t.timestamps
    end
  end
end
