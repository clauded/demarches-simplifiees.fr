describe Database::MigrationHelpers do
  include Database::MigrationHelpers

  class TestLabel < ActiveRecord::Base
  end

  before(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table "test_labels", force: true do |t|
        t.string :label
        t.integer :user_id
      end
    end

    # User 1 labels
    TestLabel.create({ id: 1, label: 'Important', user_id: 1 })
    TestLabel.create({ id: 2, label: 'Urgent', user_id: 1 })
    TestLabel.create({ id: 3, label: 'Done', user_id: 1 })
    TestLabel.create({ id: 4, label: 'Bug', user_id: 1 })

    # User 2 labels
    TestLabel.create({ id: 5, label: 'Important', user_id: 2 })
    TestLabel.create({ id: 6, label: 'Critical', user_id: 2 })

    # Duplicates
    TestLabel.create({ id: 7, label: 'Urgent', user_id: 1 })
    TestLabel.create({ id: 8, label: 'Important', user_id: 2 })
  end

  after(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.drop_table :test_labels, force: true
    end
  end

  describe '.find_duplicated_records' do
    context 'using a single column for uniqueness' do
      subject do
        find_duplicated_records(:test_labels, [:label])
      end

      it 'finds duplicates' do
        expect(subject.length).to eq 2
      end

      it 'finds three labels with "Important"' do
        expect(subject).to include [1, 5, 8]
      end

      it 'finds two labels with "Urgent"' do
        expect(subject).to include [2, 7]
      end
    end

    context 'using multiple columns for uniqueness' do
      subject do
        find_duplicated_records(:test_labels, [:label, :user_id])
      end

      it 'finds duplicates' do
        expect(subject.length).to eq 2
      end

      it 'finds two labels with "Important" for user 2' do
        expect(subject).to include [5, 8]
      end

      it 'finds two labels with "Urgent" for user 1' do
        expect(subject).to include [2, 7]
      end
    end
  end
end
