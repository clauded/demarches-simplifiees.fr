# Some of this file is lifted from Gitlab's `lib/gitlab/database/migration_helpers.rb``

# Copyright (c) 2011-present GitLab B.V.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module Database::MigrationHelpers
  # Given a combination of columns, return the records that appear twice of more
  # with the same values.
  #
  # Returns tuples of ids.
  #
  # Example: [[7, 3], [1, 9, 4]]
  def find_duplicates(table_name, column_names)
    duplicate_tuples = ActiveRecord::Base.connection.execute <<-SQL
      SELECT string_agg(the_table.id::text, ', ')
        FROM #{table_name} AS the_table
        WHERE EXISTS
          (
          SELECT 1
          FROM #{table_name} AS tmp
          WHERE (
            #{column_names.map { |c| "tmp.#{c} = the_table.#{c}" }.join(' AND ')}
          )
          LIMIT 1
          OFFSET 1
         )
        GROUP BY #{column_names.join(', ')}
    SQL
    duplicate_tuples.values.map do |tuple|
      tuple.first.split(', ').map(&:to_i)
    end
  end


  def remove_duplicates(table_name, column_names)
    duplicates = find_duplicates(table_name, column_names)

    duplicates.each do |ids|
      ids.drop(1) # drop all records except the first
      execute "DELETE FROM #{table_name} WHERE (#{table_name}.id IN (#{ids.join(', ')}))"
    end
  end

  # Creates a new index, concurrently
  #
  # Example:
  #
  #     add_concurrent_index :users, :some_column
  #
  # See Rails' `add_index` for more info on the available arguments.
  def add_concurrent_index(table_name, column_name, options = {})
    if transaction_open?
      raise 'add_concurrent_index can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
    end

    options = options.merge({ algorithm: :concurrently })

    if index_exists?(table_name, column_name, options)
      Rails.logger.warn "Index not created because it already exists (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}"
      return
    end

    disable_statement_timeout do
      add_index(table_name, column_name, options)
    end
  end

  private

  # Long-running migrations may take more than the timeout allowed by
  # the database. Disable the session's statement timeout to ensure
  # migrations don't get killed prematurely.
  #
  # There are two possible ways to disable the statement timeout:
  #
  # - Per transaction (this is the preferred and default mode)
  # - Per connection (requires a cleanup after the execution)
  #
  # When using a per connection disable statement, code must be inside
  # a block so we can automatically execute `RESET ALL` after block finishes
  # otherwise the statement will still be disabled until connection is dropped
  # or `RESET ALL` is executed
  def disable_statement_timeout
    if block_given?
      if statement_timeout_disabled?
        # Don't do anything if the statement_timeout is already disabled
        # Allows for nested calls of disable_statement_timeout without
        # resetting the timeout too early (before the outer call ends)
        yield
      else
        begin
          execute('SET statement_timeout TO 0')

          yield
        ensure
          execute('RESET ALL')
        end
      end
    else
      unless transaction_open?
        raise <<~ERROR
              Cannot call disable_statement_timeout() without a transaction open or outside of a transaction block.
              If you don't want to use a transaction wrap your code in a block call:

              disable_statement_timeout { # code that requires disabled statement here }

              This will make sure statement_timeout is disabled before and reset after the block execution is finished.
        ERROR
      end

      execute('SET LOCAL statement_timeout TO 0')
    end
  end

end
