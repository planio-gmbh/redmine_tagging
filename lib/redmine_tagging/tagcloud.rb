module RedmineTagging
  class Tagcloud
    def tag_cloud_in_project(project, &each_tag)
      tags = {}

      if project
        context = TaggingPlugin::ContextHelper.context_for(project)

        Issue.tag_counts_on(context).each do |tag|
          tags[tag.name] = tag.count
        end

        WikiPage.tag_counts_on(context).each do |tag|
          tags[tag.name] = tags[tag.name].to_i + tag.count
        end
  #    else
  #      Issue.all_tag_counts.each do |tag|
  #        tags[tag.name] = tag.count
  #      end
  #
  #      WikiPage.all_tag_counts.each do |tag|
  #        tags[tag.name] = tags[tag.name].to_i + tag.count
  #      end
      end

      tags = tags.reject {|key,value| value == 0 }

      if tags.size > 0
        min_max = tags.values.minmax
        distance = min_max[1] - min_max[0]

        dynamic_fonts_enabled = RedmineTagging.dynamic_font_size?

        tags.keys.sort_by { |t| t.downcase }.each do |tag|
          if dynamic_fonts_enabled && (distance != 0)
            count = tags[tag]
            factor = (count - min_max[0]).to_f / distance
          else
            factor = 0.0
          end

          each_tag.call(tag, factor)
        end
      end
    end
  end
end
