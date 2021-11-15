module RedmineTagging::Patches::QueriesHelperPatch
  extend ActiveSupport::Concern

  def self.apply
    QueriesHelper.send :include, self unless QueriesHelper.included_modules.include?(self)
  end

  included do
    # QueriesHelper is included all over the place, it's less brittle to patch
    # it directly vs adding this as a new helper (that would call super)
    # everywhere.
    alias_method :column_content_without_tags, :column_content
    alias_method :column_content, :column_content_with_tags
  end

  def column_content_with_tags(column, issue)
    value = column.value_object(issue)

    if value.class.name == 'Array' && value.first.class.name == 'IssueTag'
      links = value.map do |issue_tag|
        link_to_project_tag_filter(@project, issue_tag.tag)
      end
      links.join(', ')
    else
      column_content_without_tags(column, issue)
    end
  end
end
