module RedmineTagging::Patches::WikiPagePatch

  def self.apply
    WikiPage.prepend self unless WikiPage < self
  end

  def self.prepended(base)
    base.class_eval do
      has_many :wiki_page_tags

      acts_as_taggable
      safe_attributes :tags

      before_save :update_tags

      searchable_options[:columns] << "tags.name"

      original_scope = searchable_options[:scope] || self

      searchable_options[:scope] = ->(*args) {
        (original_scope.respond_to?(:call) ?
          original_scope.call(*args) :
          original_scope
        ).joins(<<-SQL
          LEFT JOIN taggings ON taggings.taggable_type = 'WikiPage' AND taggings.taggable_id = #{WikiPage.table_name}.id
          LEFT JOIN tags ON tags.id = taggings.tag_id
        SQL
        )
      }
    end
  end

  def tags=(new_tags)
    if new_tags
      @tags_to_update = TaggingPlugin::TagsHelper.from_string(new_tags)
    end
  end

  private

  def update_tags
    if @tags_to_update
      project_context = TaggingPlugin::ContextHelper.context_for(project)
      set_tag_list_on(project_context, @tags_to_update)
    end

    true
  end
end

