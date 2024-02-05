module RedmineTagging
  module Patches
    module ApplicationHelperPatch
      def link_to_project_tag_filter(project, tag, options = {}, html_options = {})
        options.reverse_merge!({
          status: 'o',
          title:  tag
        })

        opts = {
          'set_filter'     => 1,
          'f'              => ['tags', 'status_id'],
          'op[tags]'       => '=',
          'op[status_id]'  => options[:status],
          'v[tags][]'      => tag_without_sharp(tag),
          'v[status_id][]' => 1
        }

        if project
          link_to(options[:title], project_issues_path(project, opts), html_options)
        else
          link_to(options[:title], issues_path(opts), html_options)
        end
      end

      def tag_without_sharp(tag)
        tag.to_s.sub(/^\s*#/, '')
      end
    end
  end
end
