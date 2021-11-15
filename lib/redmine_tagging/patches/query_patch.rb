module RedmineTagging::Patches::QueryPatch

  def self.apply
    IssueQuery.send :prepend, self unless IssueQuery < self
  end

  def self.prepended(base)
    base.class_eval do
      add_available_column QueryColumn.new(:issue_tags, caption: :field_tags)
    end
  end

  def available_filters
    unless @available_tag_filter
      @available_filters = super
      @available_tag_filter = available_tags_filter
      @available_filters.merge!(@available_tag_filter)
    end
    @available_filters
  end

  def available_tags_filter
    if project.nil?
      tags = ActsAsTaggableOn::Tag.where(
          "id in (select tag_id from taggings where taggable_type = 'Issue')"
      )
    else
      context = TaggingPlugin::ContextHelper.context_for(project)
      tags = ActsAsTaggableOn::Tag.where(
          "id in (select tag_id from taggings where taggable_type = 'Issue' and context = ?)",
          context
      )
    end
    tags = tags.sort_by { |t| t.name.downcase }.map do |tag|
      [tag_without_sharp(tag), tag_without_sharp(tag)]
    end
    field = 'tags'
    options = {
      type:   :list_optional,
      values: tags,
      name:   l(:field_tags),
      order:  21,
    }
    filter = ActiveSupport::OrderedHash.new
    filter[field] = QueryFilter.new(field, options)
    filter
  end

  def sql_for_field(field, operator, v, db_table, db_field, is_custom_filter = false)
    if field == 'tags'
      tagging_sql(field, operator)
    else
      super
    end
  end

  def tagging_sql(field, operator)
    case operator
      when '!*'
        tagging_sql_none
      when '*'
        tagging_sql_any
      when '!'
        tagging_sql_not_equal(field)
      else
        tagging_sql_equal(field)
    end
  end

  def tagging_sql_none
    "(#{Issue.table_name}.id NOT IN (select taggable_id from taggings where taggable_type='Issue'))"
  end

  def tagging_sql_any
    "(#{Issue.table_name}.id IN (select taggable_id from taggings where taggable_type='Issue'))"
  end

  def tagging_sql_not_equal(field)
    sql = tagging_sql_equal(field)
    "(not #{sql})"
  end

  def tagging_sql_equal(field)
    selected_values = values_for(field).map { |tag| tag_with_sharp(tag).downcase }
    sql = selected_values.collect { |val| "'#{ActiveRecord::Base.connection.quote_string(val.gsub('\'', ''))}'" }.join(',')
    "(#{Issue.table_name}.id in (select taggable_id from taggings join tags on tags.id = taggings.tag_id where taggable_type='Issue' and lower(tags.name) in (#{sql})))"
  end

  def tag_without_sharp(tag)
    tag.to_s.gsub(/^\s*#/, '')
  end

  def tag_with_sharp(tag)
    '#' + tag_without_sharp(tag)
  end
end

