module ActiveRecord
module ConnectionAdapters
module SchemaStatements
  # Options for +:on_delete+ and +:on_update+ may be specified.  Acceptable
  # values are +:restrict+, +:set_null+, and +:cascade+.
  #
  # Note that some databases will automatically create an index on the constrained
  # columns.
  #
  # ===== Examples
  # ====== Creating a simple foreign key
  #  add_foreign_key :orders, :user_id
  # generates
  #  ALTER TABLE orders ADD CONSTRAINT index_orders_on_user_id FOREIGN KEY (user_id) REFERENCES users (id)
  # ====== Specifying the target table
  #  add_foreign_key :articles, :author_id, :references => :users
  # generates
  #  ALTER TABLE articles ADD CONSTRAINT index_articles_on_author_id FOREIGN KEY (author_id) REFERENCES users (id)
  # ====== Cascading deletes
  #  add_foreign_key :comments, :post_id, :on_delete => :cascade
  # generates
  #  ALTER TABLE comments ADD CONSTRAINT index_comments_on_post_id FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE
  def create_type(type_name, options = {})
    type_definition = TableDefinition.new(self)

    yield type_definition

    if options[:force] && type_exists?(type_name)
      drop_type(type_name, options)
    end

    create_sql = "CREATE TYPE "
    create_sql << "#{quote_table_name(type_name)} AS ("
    create_sql << type_definition.to_sql
    create_sql << ")"
    execute create_sql
  end

  def drop_type(type_name, options = {})
    execute "DROP TYPE IF EXISTS #{quote_table_name(type_name)}"
  end
end
end
end

