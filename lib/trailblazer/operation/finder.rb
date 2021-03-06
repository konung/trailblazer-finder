# frozen_string_literal: true

# Really gotta clean this up, but can't be bothered right now
module Trailblazer
  class Operation
    def self.Finder(finder_class, action = nil, entity = nil)
      task = Trailblazer::Activity::TaskBuilder::Binary(Finder.new)

      extension = Trailblazer::Activity::TaskWrap::Merge.new(
        Wrap::Inject::Defaults(
          "finder.class"        => finder_class,
          "finder.entity"       => entity,
          "finder.action"       => action
        )
      )

      {task: task, id: "finder.build", Trailblazer::Activity::DSL::Extension.new(extension) => true}
    end

    class Finder
      def call(options, params:, **)
        builder                   = Finder::Builder.new
        options[:finder]          = finder = builder.call(options, params)
        options[:model]           = finder # Don't like it, but somehow it's needed if contracts are loaded
        options["result.finder"]  = result = Result.new(!finder.nil?, {})

        result.success?
      end

      class Builder
        def call(options, params)
          finder_class  = options["finder.class"]
          entity        = options["finder.entity"] || nil
          action        = options["finder.action"] || :all
          action        = :all unless %i[all single].include?(action)

          send("#{action}!", finder_class, entity, params, options["finder.action"])
        end

        private

        def all!(finder_class, entity, params, *)
          finder_class.new(entity: entity, params: params)
        end

        def single!(finder_class, entity, params, *)
          apply_id(params)
          if entity.nil?
            finder_class.new(params: params).result.first
          else
            finder_class.new(entity: entity, params: params).result.first
          end
        end

        def apply_id(params)
          return if params[:id].nil?

          params[:id_eq] = params[:id] unless params.key?("id")
        end
      end
    end
  end
end
