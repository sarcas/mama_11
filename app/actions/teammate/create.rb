# frozen_string_literal: true

module Mama11
  module Actions
    module Teammate
      class Create < Mama11::Action
        include Deps["repos.teammate_repo"]

        params do
          required(:teammate).hash do
            required(:name).filled(:string)
          end
        end

        def handle(request, response)
          if request.params.valid?
            teammate_repo.create(request.params[:teammate])
            response.redirect_to routes.path(:home)
          end
        end
      end
    end
  end
end
