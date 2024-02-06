require 'redmine'

Redmine::Plugin.register :redmine_tagging do
  name 'Redmine Tagging Plugin'
  author 'Restream'
  description 'This plugin adds tagging features to Redmine.'
  version '0.1.6'

  settings default: {
      dynamic_font_size: '1',
      sidebar_tagcloud:  '1',
      wiki_pages_inline: '0',
      issues_inline:     '0'
    },
    partial:        'tagging/settings'

  Redmine::WikiFormatting::Macros.register do
    desc 'Wiki/Issues tagcloud'
    macro :tagcloud do |obj, args|
      args, options = extract_macro_options(args, :parent)

      return if params[:controller] == 'mailer'

      if obj
        if obj.is_a? WikiContent
          project = obj.page.wiki.project
        else
          project = obj.project
        end
      else
        project = Project.visible.where(identifier: params[:project_id]).first
      end

      if project # this may be an attempt to render tag cloud when deleting wiki page
        if [WikiContent, WikiContent::Version, NilClass].include?(obj.class)
          render partial: 'tagging/tagcloud_search', project: project
        elsif [Journal, Issue].include?(obj.class)
          render partial: 'tagging/tagcloud', project: project
        end
      end
    end
  end

  Redmine::WikiFormatting::Macros.register do
    desc 'Wiki/Issues tag'
    macro :tag do |obj, args|
      if obj.is_a?(WikiContent) && Setting.plugin_redmine_tagging["wiki_pages_inline"] == '1'
        inline = true
      elsif obj.is_a?(Issue) && Setting.plugin_redmine_tagging["issues_inline"] == '1'
        inline = true
      else
        inline = false
      end

      if inline
        args, options = extract_macro_options(args, :parent)
        tags = args.collect{|a| a.split(/[#"'\s,]+/)}.flatten.select{|tag| !tag.blank?}.collect{|tag| "##{tag}" }.uniq
        tags.sort_by! { |t| t.downcase }

        if obj.is_a? WikiContent
          obj = obj.page
          project = obj.wiki.project
        else
          project = obj.project
        end

        context = TaggingPlugin::ContextHelper.context_for(project)
        tags_present = obj.tag_list_on(context).sort_by { |t| t.downcase }.join(',')
        new_tags = tags.join(',')
        if tags_present != new_tags
          obj.tags_to_update = new_tags
          obj.save
        end

        taglinks = tags.collect do |tag|
          search_url = {
            controller: 'search',
            action:     'index',
            id:         project,
            q:          "\"#{tag}\""
          }

          search_url.merge!(obj.is_a?(WikiPage) ? { wiki_pages: true, issues: false } : { wiki_pages: false, issues: true })
          link_to(tag, search_url)
        end.join('&nbsp;')

        raw("<div class='tags'>#{taglinks}</div>")
      else
        ''
      end
    end
  end
end

Rails.configuration.to_prepare do
  RedmineTagging::Patches::IssuePatch.apply
  RedmineTagging::Patches::ProjectPatch.apply
  RedmineTagging::Patches::QueryPatch.apply
  RedmineTagging::Patches::QueriesHelperPatch.apply
  RedmineTagging::Patches::WikiPagePatch.apply

  # be more explicit about where the helper is included, patching ApplicationHelper is brittle
  IssuesController.send :helper, RedmineTagging::Patches::ApplicationHelperPatch
  WikiController.send :helper, RedmineTagging::Patches::ApplicationHelperPatch
  ReportsController.send :helper, RedmineTagging::Patches::ApplicationHelperPatch

  ProjectsController.send :helper, RedmineTagging::Patches::ProjectSettingsTabs
end

require 'tagging_plugin/tagging_hooks'
require 'redmine_tagging/hooks/api_hooks'
