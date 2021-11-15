module RedmineTagging
  module Patches
    module ProjectSettingsTabs
      def project_settings_tabs
        tabs = super
        tabs << { name: 'tags', partial: 'tagging/tagtab', label: :tagging_tab_label }
        return tabs
      end
    end
  end
end
