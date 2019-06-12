module TaggingPlugin

  module ProjectsHelperPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :project_settings_tabs, :tags_tab
      end
    end

    module InstanceMethods
      def project_settings_tabs_with_tags_tab
        tabs = project_settings_tabs_without_tags_tab
        tabs << { name: 'tags', partial: 'tagging/tagtab', label: :tagging_tab_label }
        return tabs
      end
    end
  end

end

ProjectsHelper.send(:include, TaggingPlugin::ProjectsHelperPatch) unless ProjectsHelper.included_modules.include? TaggingPlugin::ProjectsHelperPatch
