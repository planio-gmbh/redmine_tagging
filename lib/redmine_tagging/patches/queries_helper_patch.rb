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
    return column_content_without_tags(column, issue) unless column.name == :issue_tags

    value = column.value_object(issue)
    # fall back linking to the issues' project if tags are rendered in the
    # global /issues list. This is not ideal as users would expect to see the
    # tag added to the global filter (which we do not support due to the
    # difficulties involved with deciding what tags a user may actually see), but it
    # probably is still better than no link at all.
    project = @project || issue.project
    links = value.to_a.map do |issue_tag|
      link_to issue_tag.name, project_issues_path(project, RedmineTagging::Tagcloud.tag_filter_link_options(issue_tag.name))
    end
    safe_join links, ' '
  end
end
