module RedmineTagging
  def self.dynamic_font_size?
    Setting.plugin_redmine_tagging["dynamic_font_size"] == "1"
  end

  def self.sidebar_tagcloud?
    Setting.plugin_redmine_tagging["sidebar_tagcloud"] == '1'
  end

  def self.issues_inline_tags?
    false
    # Setting.plugin_redmine_tagging["issues_inline"] == '1'
  end

  def self.wiki_pages_inline_tags?
    false
    # Setting.plugin_redmine_tagging["wiki_pages_inline"] == '1'
  end

  def self.visible_tags(project: nil, types: ['Issue'])
    if project.nil?
      visible_projects = Project.allowed_to(User.current, :view_issues)
      contexts = visible_projects.map{|p| TaggingPlugin::ContextHelper.context_for p}
    else
      contexts = [TaggingPlugin::ContextHelper.context_for(project)]
    end
    return ActsAsTaggableOn::Tag.
      joins(:taggings).
      where(taggings: {taggable_type: types, context: contexts}).
      distinct
  end
end
