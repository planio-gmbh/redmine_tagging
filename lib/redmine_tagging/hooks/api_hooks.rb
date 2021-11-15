module TaggingPlugin
  class ApiHooks < Redmine::Hook::ViewListener
    def api_issues_index(options = {})
      api, issue = options.values_at :api, :issue
      api.array :tags do
        issue.issue_tags.each do |issue_tag|
          api.tag(:id => issue_tag.tag[1..-1])
        end
      end
    end

    def api_issues_show(options = {})
      api, issue = options.values_at :api, :issue
      api.array :tags do
        issue.issue_tags.each do |issue_tag|
          api.tag(:id => issue_tag.tag[1..-1])
        end
      end
    end
  end
end
