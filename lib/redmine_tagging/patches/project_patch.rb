module RedmineTagging::Patches::ProjectPatch
  def self.apply
    Project.send :prepend, self unless Project < self
  end

  def tags
    ActsAsTaggableOn::Tag.
        joins(:taggings).
        joins(
          self.class.sanitize_sql_for_conditions([
            "inner join #{Issue.table_name} issues on issues.project_id = ? AND issues.id = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id",
            id
          ])
        ).order(:name).uniq
  end
end

