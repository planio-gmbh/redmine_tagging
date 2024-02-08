module RedmineTagging::Patches::IssuePatch

  def self.apply
    Issue.send :prepend, self unless Issue < self
  end

  def self.prepended(base)
    base.class_eval do
      attr_writer :tags_to_update

      before_save :update_tags
      acts_as_taggable

      after_save :cleanup_tags

      searchable_options[:columns] << "tags.name"

      original_scope = searchable_options[:scope] || self

      searchable_options[:scope] = ->(*args) {
        (original_scope.respond_to?(:call) ?
          original_scope.call(*args) :
          original_scope
        ).joins(<<-SQL
          LEFT JOIN taggings ON taggings.taggable_type = 'Issue' AND taggings.taggable_id = #{Issue.table_name}.id
          LEFT JOIN tags ON tags.id = taggings.tag_id
        SQL
        )
      }
    end
  end


  def create_journal
    if @current_journal
      tag_context = TaggingPlugin::ContextHelper.context_for(project)
      before      = @issue_tags_before_change
      after       = TaggingPlugin::TagsHelper.to_string(tag_list_on(tag_context))
      unless before == after
        @current_journal.details << JournalDetail.new(
          property:  'attr',
          prop_key:  'tags',
          old_value: before,
          value:     after)
      end
    end
    super
  end

  def init_journal(user, notes = "")
    unless project.nil?
      tag_context               = TaggingPlugin::ContextHelper.context_for(project)
      @issue_tags_before_change = TaggingPlugin::TagsHelper.to_string(tag_list_on(tag_context))
    end
    super(user, notes)
  end

  def issue_tags
    ActsAsTaggableOn::Tag.joins('LEFT JOIN taggings ON taggings.tag_id = tags.id')
      .where("taggings.taggable_type = 'Issue' and taggings.taggable_id = ?", id)
  end

  def tags
    issue_tags.map(&:to_s).join(' ')
  end

  def copy_from(arg, options = {})
    super(arg, options)
    issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
    self.tag_list_ctx = issue.tag_list_ctx
    self
  end

  def tag_list_ctx
    tag_context = TaggingPlugin::ContextHelper.context_for(project)
    tag_list_on(tag_context)
  end

  def tag_list_ctx=(new_list)
    tag_context = TaggingPlugin::ContextHelper.context_for(project)
    set_tag_list_on(tag_context, new_list)
  end

  private

  def update_tags
    project_context = TaggingPlugin::ContextHelper.context_for(project)

    # Fix context if project changed
    if project_id_changed? && !new_record?
      @new_project_id = project_id

      taggings.update_all(context: project_context)
    end

    if @tags_to_update
      set_tag_list_on(project_context, @tags_to_update)
    end

    true
  end

  def cleanup_tags
    if @new_project_id
      context = TaggingPlugin::ContextHelper.context_for(project)
      ActsAsTaggableOn::Tagging.where(
        'context != ? AND taggable_id = ? AND taggable_type = ?', context, id, 'Issue'
      ).delete_all
    end
    true
  end
end

